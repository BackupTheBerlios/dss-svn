#!/bin/sh
#
# Add unionfs support to a 2.6.x Linux kernel source.
# Adapted from script sent in by Sven Geggus
#
# This script expects a clean Linux source tree, and adds the following:
#	linux/fs/unionfs	Unionfs sources
#	linux/fs/Kconfig	A configuration option to
#				"Miscellaneous filesytems" menu.
#	linux/fs/Makefile	A reference to linux/fs/unionfs.
#
# To control the Unionfs options (e.g., debugging), you still need to edit
# linux/fs/unionfs/Makefile, because they aren't yet configurable from
# make config.
#
if [ $# -ne 1 ]; then
	echo "Usage: patch-kernel.sh <sourcetree>"
	exit 1
fi

set -e

# kernel soucretree sanity check
if ! grep -q 'Linux kernel release 2.6.xx' $1/README; then
  echo "Invalid Kernel Sourcetree $1, should be Kernel 2.6.x"
  exit 1
fi

if [ -d $1/fs/unionfs ] ; then
	echo "This kernel source tree is already patched."
	exit 1
fi

# We don't want to double patch
if grep -q 'config UNION_FS' $1/fs/Kconfig 2>/dev/null ; then
	echo "Configuration option 'UNION_FS' already exists in $1/fs/Kconfig" 1>&2
	exit 1
fi
if grep -q 'CONFIG_UNION_FS' $1/fs/Makefile ; then
	echo "Build option 'CONFIG_UNION_FS' already exists in $1/Makefile" 1>&2
	exit 1
fi


# We handle Kconfig first, because it is relatively tricky
if ! grep -q '^menu "Miscellaneous filesystems"' $1/fs/Kconfig 2>/dev/null ; then
	echo "Can not find 'Miscellaneous filesystems' menu" 1>&2
	exit 1
fi

START=`grep -n '^menu "Miscellaneous filesystems"' $1/fs/Kconfig |cut -d: -f1`
END=`tail -n +$START $1/fs/Kconfig |grep -n endmenu | head -n 1 | cut -d: -f1`
END=$(($START + $END - 2))

# add config-option to Kconfig
cp $1/fs/Kconfig $1/fs/Kconfig.orig
head -n $END $1/fs/Kconfig.orig >$1/fs/Kconfig
echo -e "config UNION_FS
\ttristate \"Union fs support\"
\tdepends on EXPERIMENTAL
\thelp
\t  Unionfs is a stackable unification file system, which can
\t  appear to merge the contents of several directories (branches),
\t  while keeping their physical content separate.

\t  see <http://www.fsl.cs.sunysb.edu/project-unionfs.html> for details
" >>$1/fs/Kconfig
tail -n +$(($END + 1)) $1/fs/Kconfig.orig >>$1/fs/Kconfig

# make the directory
mkdir -p $1/fs/unionfs
# copy unionfs sources
cp -a *.[ch] $1/fs/unionfs/
# copy unionfs extras over
cp -a AUTHORS COPYING ChangeLog INSTALL NEWS README $1/fs/unionfs
# copy makefile over
cp Makefile.kernel $1/fs/unionfs/Makefile

# add unionfs directory to Makefile in fs directory
cp $1/fs/Makefile $1/fs/Makefile.orig
echo 'obj-$(CONFIG_UNION_FS)          += unionfs/' >>$1/fs/Makefile
