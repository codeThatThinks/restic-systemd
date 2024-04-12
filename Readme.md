# restic-systemd

Automated restic backups with systemd

Based on https://github.com/erikw/restic-automatic-backup-scheduler


## Installation

1. `sudo make install`
2. Copy an example config from `/etc/default/restic-*.conf` to `/etc/restic.d/my-backup-profile.conf`
3. Edit the config file and enter your desired restic options.
4. Enable the systemd backup timer for the specific config and do a backup:
```
sudo systemctl enable --now restic-backup@my-backup-profile.timer
```
5. Enable the systemd backup check timer and check the newly created backup:
```
sudo systemctl enable --now restic-check@my-backup-profile.timer
```


## Using Backblaze B2 as a backend

1. Create a B2 bucket (private; no encryption; no object lock)
2. Go to `Account` > `Application Keys`, and create a new read/write key scoped only to the specific bucket.
3. In the config file, set `B2_ACCOUNT_ID` to the key ID and `B2_ACCOUNT_KEY` to the application key.
