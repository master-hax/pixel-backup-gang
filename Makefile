VERSION ?= snapshot

SCRIPTS := \
scripts/mount_ext4.sh \
scripts/unmount.sh \
scripts/find_device.sh \
scripts/show_devices.sh \
scripts/enable_tcp_debugging.sh \
scripts/disable_tcp_debugging.sh \

release: $(SCRIPTS)
	tar -czvf pixel-backup-gang-$(VERSION).tar.gz --transform='s,^scripts/,pixel-backup-gang-$(VERSION)/,' $^
clean:
	rm -f pixel-backup-gang-$(VERSION).tar.gz
