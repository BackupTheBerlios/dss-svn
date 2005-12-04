#!/bin/sh
#
# add unionfs support to a 2.6.x Linux kernel source
# adapted from script sent in by Sven Geggus
#
# This script will copy the files appropriate for unionfs
# to be placed into the kernel as opposed to the original
# which moved everything over.
#
# Also this file uses a separate Makefile since the orignal
# if far too compicated for the kernel. This will help in 
# actual kernel inclusion later on. Since we are only 
# supporting patching of a source tree with 2.6.
# 
if [ $# -ne 1 ]; then
	echo "Usage: patch-kernel.sh <sourcetree>"
	exit 1
fi

# kernel soucretree sanity check
if ! grep -q 'Linux kernel release 2.6.xx' $1/README; then
  echo "Ivalid Kernel Sourcetree $1, should be Kernel 2.6.x" 
  exit 1
fi 

# copy unionfs sources
cp -a *.[ch] $1/fs/unionfs/
# copy unionfs extras over
cp -a AUTHORS COPYING ChangeLog INSTALL NEWS README $1/fs/unionfs
# copy unionfs manpages over
cp -ar man $1/fs/unionfs/
# copy makefile over
cp Makefile.kernel $1/fs/unionfs/Makefile

# add unionfs directory to Makefile in fs directory
cp $1/fs/Makefile $1/fs/Makefile.orig
echo 'obj-$(CONFIG_UNION_FS)          += unionfs/' >>$1/fs/Makefile

# add config-option to Kconfig
cp $1/fs/Kconfig $1/fs/Kconfig.orig
head -n 6 $1/fs/Kconfig.orig >$1/fs/Kconfig
echo -e "config UNION_FS
\ttristate \"Union fs support\"
\thelp
\t  Unionfs is a stackable unification file system, which can
\t  appear to merge the contents of several directories (branches),
\t  while keeping their physical content separate.

\t  see <http://www.fsl.cs.sunysb.edu/project-unionfs.html> for details
" >>$1/fs/Kconfig
tail +7 $1/fs/Kconfig.orig >>$1/fs/Kconfig
