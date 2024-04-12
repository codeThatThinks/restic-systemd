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

# NOTE start all commands in background and wait for them to finish.
# Reason: bash ignores any signals while child process is executing and thus the trap exit hook is not triggered.
# However if put in subprocesses, wait(1) waits until the process finishes OR signal is received.
# Reference: https://unix.stackexchange.com/questions/146756/forward-sigterm-to-child-in-bash

# Prune old backups.
restic prune \
	-v \
	"${b2_conn_arg[@]}" \
	"${RESTIC_PRUNE_ARGS[@]}" \
	&
wait $!

# Check repository for errors.
restic check \
	-v \
	"${b2_conn_arg[@]}" \
	"${RESTIC_CHECK_ARGS[@]}" \
	&
wait $!

echo "Cleanup finished."
