
	
DSDIR=$(DESTDIR)/etc/debaser
LIBDIR=$(DESTDIR)/usr/lib/debaser
TMPDIR=confdir
install:
	mkdir -p $(DESTDIR)/usr/{share/man/man8,sbin}
	mkdir -p $(DSDIR)
	mkdir -p $(LIBDIR)/scripts
	mkdir -p confdir
	cp -r exclude postsel prepkge useif  live confdir
	cd confdir && tar cvfz ../deconfdir.tar.gz . && cd ../
	
	install -o root -g root -m 0644 deconfdir.tar.gz $(DSDIR)/
	install -o root -g root -m 0644 scripts/* $(LIBDIR)/scripts/
	install -o root -g root -m 0644 functions $(LIBDIR)/
	install -o root -g root -m 0644 default $(DSDIR)/
	install -o root -g root -m 0755 depostrap $(LIBDIR)/
	install -o root -g root -m 0755 pkgedet  $(LIBDIR)/
	install -o root -g root -m 0755 debaser.8 $(DESTDIR)/usr/share/man/man8/
	install -o root -g root -m 0755 debaser $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 dpkg-genstatus $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 dpkg-rebuild $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 make-mod $(DESTDIR)/usr/sbin/
	install -o root -g root -m 0755 make-iso $(DESTDIR)/usr/bin/
clean:
	rm -r confdir deconfdir.tar.gz 
	



