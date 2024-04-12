.PHONY: install

install:
	mkdir -p /usr/local/bin
	install -m 0755 bin/* /usr/local/bin/
	mkdir -p /etc/default
	install  -m 0644 default/* /etc/default/
	mkdir -p /usr/lib/systemd/system
	install -m 0644 systemd/* /usr/lib/systemd/system/
	mkdir -p /etc/restic.d
	systemctl daemon-reload
	@echo
	@echo Installation complete.
	@echo Create a config file in /etc/restic.d/ and enable the corresponding systemd timer to begin backing up.
