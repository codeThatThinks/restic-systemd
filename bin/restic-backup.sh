#!/usr/bin/env bash

set -o errexit
set -o pipefail

# source config file
[ $# -eq 1 ] && source $1 || echo Usage: $0 CONFIG_FILE; exit 1

# Clean up lock if we are killed.
# If killed by systemd, like $(systemctl stop restic), then it kills the whole cgroup and all it's subprocesses.
# However if we kill this script ourselves, we need this trap that kills all subprocesses manually.
exit_hook() {
	echo "In exit_hook(), being killed" >&2
	jobs -p | xargs kill
	restic unlock
}
trap exit_hook INT TERM

# Add b2 connections arg if set
b2_conn_arg=
[ -z "${B2_CONNECTIONS+x}" ] || b2_conn_arg=(--option b2.connections="$B2_CONNECTIONS")

# Generate exclude file args
exclude_args=()
for exclude_path in "${EXCLUDES[@]}"; do
	exclude_args=("${exclude_args[@]}" --exclude "$exclude_path")
done

# NOTE start all commands in background and wait for them to finish.
# Reason: bash ignores any signals while child process is executing and thus the trap exit hook is not triggered.
# However if put in subprocesses, wait(1) waits until the process finishes OR signal is received.
# Reference: https://unix.stackexchange.com/questions/146756/forward-sigterm-to-child-in-bash

# Remove locks from other stale processes to keep the automated backup running.
restic unlock &
wait $!

# Do the backup!
# --no-scan skips running the scanner to estimate backup size
# --one-file-system makes sure we only backup exactly those mounted file systems
# specified in $RESTIC_BACKUP_PATHS, and not directories like /dev, /sys etc.
# --tag lets us reference these backups later when doing restic-forget.
restic backup \
	-v \
	--no-scan \
	--one-file-system \
	--tag automated \
	"${b2_conn_arg[@]}" \
	"${exclude_args[@]}" \
	"${RESTIC_BACKUP_ARGS[@]}" \
	"${BACKUP_PATHS[@]}" \
	&
wait $!

# Dereference old backups.
# --group-by only the tag and path, and not by hostname. This is because I
# create a B2 Bucket per host, and if this hostname accidentially change some
# time, there would now be multiple backup sets.
restic forget \
	-v \
	"${b2_conn_arg[@]}" \
	--group-by "paths,tags" \
	--tag automated \
	--keep-hourly "$KEEP_HOURLY" \
	--keep-daily "$KEEP_DAILY" \
	--keep-weekly "$KEEP_WEEKLY" \
	--keep-monthly "$KEEP_MONTHLY" \
	--keep-yearly "$KEEP_YEARLY" \
	"${RESTIC_FORGET_ARGS[@]}" \
	&
wait $!

echo "Backup finished."
