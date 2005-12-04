#
# Makefile for the Linux 2.4 unionfs
#

# this should point to where your kernel headers are
KVERS=$(shell uname -r)
MODDIR= /lib/modules/$(KVERS)
LINUXSRC = /lib/modules/$(KVERS)/build
TOPINC   = -I${LINUXSRC}/include
# This is where the make install target will put stuff
PREFIX   = /usr/local
MANDIR   = ${PREFIX}/man
MODPREFIX=
VERSION=071805-1518
TAROPTS = czvf
COMPEXT = .gz
UNIONFS_DEBUG_CFLAG = -g
UNIONFS_OPT_CFLAG= -O2
UNIONFS_VERSION_CFLAG=-DUNIONFS_VERSION=\"${VERSION}\"

# allow custmom override of TOPINC for fistgen developers
# These options enable extended attribute support
#  EXTRACFLAGS=-DUNIONFS_XATTR
# Some kernels also require FIST_SETXATTR_CONSTVOID
#  EXTRACFLAGS=-DUNIONFS_XATTR -DFIST_SETXATTR_CONSTVOID
ifneq ($(FISTDEVMK),)
-include $(FISTDEVMK)
else
-include fistdev.mk
endif

CC	= gcc
KERNELVERSION=$(shell echo $(KVERS) | cut -d. -f1,2)
ifeq ($(KERNELVERSION),2.4)
CFLAGS = -D__KERNEL__ -DMODULE -I. ${TOPINC} -Wall -Wno-unused-label -Werror -fno-strict-aliasing ${EXTRACFLAGS} ${UNIONFS_DEBUG_CFLAG} ${UNIONFS_OPT_CFLAG} ${UNIONFS_VERSION_CFLAG}
endif
EXTRA_CFLAGS += ${TOPINC} -Wall -Werror ${EXTRACFLAGS} ${UNIONFS_DEBUG_CFLAG} ${UNIONFS_OPT_CFLAG} ${UNIONFS_VERSION_CFLAG}
UCFLAGS = -I. ${UNIONFS_DEBUG_CFLAG} ${UNIONFS_OPT_CFLAG} -Wall -Werror ${EXTRAUCFLAGS}  ${UNIONFS_VERSION_CFLAG}

obj-m := unionfs.o
unionfs-objs := subr.o dentry.o locks.o file.o inode.o main.o super.o \
	stale_inode.o branchman.o xattr.o rdstate.o copyup.o  \
	dirhelper.o rename.o unlink.o lookup.o persistent_inode.o \
	commonfops.o dirfops.o print.o

BINS	:=	unionctl uniondbg unionimap

all:	readthereadme unionfs$(KERNELVERSION) ${BINS}

readthereadme:
	@echo "******************************************************************************"
	@echo "If you have questions about or problems building Unionfs, please read INSTALL."
	@echo "******************************************************************************"
	@echo ""

unionfs2.6:
	make -C ${LINUXSRC} SUBDIRS=$(PWD) FISTDEVMK=$(PWD)/fistdev.mk modules

unionfs2.4: ${obj-m}

${obj-m}: ${unionfs-objs}
	ld -o ${obj-m} -r ${unionfs-objs}

unionctl: unionctl.c usercommon.c
	${CC} -o $@ $? ${UCFLAGS}

uniondbg: uniondbg.c
	${CC} -o $@ $? ${UCFLAGS}

unionimap: unionimap.c usercommon.c
	${CC} -o $@ -luuid $? ${UCFLAGS}

memtest:
	perl match-malloc.pl log.txt

TAGS:
	etags -t *.[hc]

tags:
	ctags *.[ch]

clean:
ifeq ($(KERNELVERSION),2.6)
	-make -C ${LINUXSRC} SUBDIRS=$(PWD) FISTDEVMK=$(PWD)/fistdev.mk clean
endif
	rm -f ${unionfs-objs} ${obj-m} ${obj-m:.o=.ko} *.d .*.flags \#* *~
	rm -f ${BINS} TAGS tags
	rm -f unionfs-${VERSION}.tar${COMPEXT}


${unionfs-objs}: unionfs.h fist.h

PHONY. utils: ${BINS}

install-utils: utils
	mkdir -p ${PREFIX}/sbin
	cp unionctl ${PREFIX}/sbin
	cp uniondbg ${PREFIX}/sbin
	cp unionimap ${PREFIX}/sbin
	mkdir -p ${MANDIR}/man4
	mkdir -p ${MANDIR}/man8
	cp man/unionfs.4 ${MANDIR}/man4
	cp man/unionctl.8 ${MANDIR}/man8
	cp man/uniondbg.8 ${MANDIR}/man8

install-mod: unionfs$(KERNELVERSION)
	mkdir -p ${MODPREFIX}/${MODDIR}/kernel/fs
	if [ -f unionfs.ko ] ; then cp unionfs.ko ${MODPREFIX}/${MODDIR}/kernel/fs ; else cp unionfs.o ${MODPREFIX}/${MODDIR}/kernel/fs ; fi
	-/sbin/depmod -a

install: install-utils install-mod

uninstall:
	if [ -f unionfs.ko ] ; then rm ${MODPREFIX}/${MODDIR}/kernel/fs/unionfs.ko ; else rm ${MODPREFIX}/${MODDIR}/kernel/fs/unionfs.o ; fi
	-/sbin/depmod -a
	rm ${MANDIR}/man8/unionctl.8
	rm ${MANDIR}/man8/uniondbg.8
	rm ${MANDIR}/man4/unionfs.4
	rm ${PREFIX}/sbin/unionctl
	rm ${PREFIX}/sbin/uniondbg

release: unionfs-${VERSION}.tar${COMPEXT}

kernel-source-unionfs-${VERSION}.tar${COMPEXT}:
	mkdir kernel-source-unionfs-${VERSION}
	cp -a Makefile *.h *.c kernel-source-unionfs-${VERSION}
	subst "s/\(^all.*\)\(\${BINS}\)/\1/" kernel-source-unionfs-${VERSION}/Makefile
	tar ${TAROPTS} kernel-source-unionfs-${VERSION}.tar${COMPEXT} kernel-source-unionfs-${VERSION}

unionfs-${VERSION}.tar${COMPEXT}:
	mkdir unionfs-${VERSION}
	cp patch-kernel.sh Makefile.kernel COPYING AUTHORS README INSTALL NEWS ChangeLog doit.sh undoit.sh *.pl Makefile *.[ch] misc/snapmerge unionfs-${VERSION}
	cp -r rpm debian unionfs-${VERSION}
	rm -rf unionfs-${VERSION}/rpm/CVS
	rm -rf unionfs-${VERSION}/debian/CVS
	mkdir unionfs-${VERSION}/regression
	cp ../regression/*.sh ../regression/ChangeLog ../regression/scaffold ../regression/README unionfs-${VERSION}/regression
	mkdir unionfs-${VERSION}/man
	cp man/*.[0-9] unionfs-${VERSION}/man
	tar ${TAROPTS} unionfs-${VERSION}.tar${COMPEXT} unionfs-${VERSION}
	rm -rf unionfs-${VERSION}
