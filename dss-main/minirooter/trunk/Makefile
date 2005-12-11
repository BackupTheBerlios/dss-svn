DSDIR=$(DESTDIR)/etc/minirooter
LIBDIR=$(DESTDIR)/usr/share/minirooter
CONFIGDIR=$(LIBDIR)/confdir
MINIFUN=$(DESTDIR)/usr/lib/minirooter/
install:
	mkdir -p $(DESTDIR)/usr/{share/man/man8,sbin}
	mkdir -p $(MINIFUN)
	mkdir -p $(DSDIR)
	mkdir -p $(LIBDIR)/etc
	mkdir -p $(LIBDIR)/bootsplash/{animations,config,images}
	mkdir -p $(CONFIGDIR)/scripts
	tar xfvz busybox*.tar.gz
	install -o root -g root -m 0644 busybox.links $(LIBDIR)/
	install -o root -g root -m 0644 modules $(DSDIR)/
	install -o root -g root -m 0644 exe $(DSDIR)/
	install -o root -g root -m 0755 linuxrc $(DSDIR)/
	install -o root -g root -m 0755 busybox  $(LIBDIR)/
	install -o root -g root -m 0755 mkderooter.8 $(DESTDIR)/usr/share/man/man8/
	install -o root -g root -m 0755 mkderooter $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 mkext2fs $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 mkext2fs $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0644 bootsplash/animations/* $(LIBDIR)/bootsplash/animations/
	install -o root -g root -m 0644 bootsplash/config/* $(LIBDIR)/bootsplash/config/
	install -o root -g root -m 0644 bootsplash/images/* $(LIBDIR)/bootsplash/images/
	install -o root -g root -m 0644 etc/* $(LIBDIR)/etc/
	install -o root -g root -m 0644 config-busybox $(LIBDIR)/
	install -o root -g root -m 0755 confdir/init $(CONFIGDIR)/
	install -o root -g root -m 0644 confdir/exe $(CONFIGDIR)/
	install -o root -g root -m 0644 confdir/mkinitrd.conf $(CONFIGDIR)/
	install -o root -g root -m 0644 confdir/modules $(CONFIGDIR)/
	install -o root -g root -m 0755 confdir/scripts/* $(CONFIGDIR)/scripts/
	install -o root -g root -m 0644 functions $(MINIFUN)/

clean:
	rm -f busybox  busybox.links config-busybox
	



