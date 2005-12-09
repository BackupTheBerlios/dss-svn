#!/bin/bash -norc
set -x
PATH=/sbin:.:${PATH}
export PATH

BRANCHES=/branch0:/branch1
MOUNTPOINT=/mnt/unionfs
DEBUG=18
EXTRAMOUNT=
INSMOD=insmod
IMAP=

if [ -f doitopts ] ; then
	source ./doitopts
fi
if [ -f doitopts.`uname -n` ] ; then
	source ./doitopts.`uname -n`
fi

lsmod
if [ -f ./unionfs.ko ] ; then
	$INSMOD ./unionfs.ko || exit
elif [ -f ./unionfs.o ] ; then
	$INSMOD ./unionfs.o || exit
else
	echo "Can not find unionfs object file."
	exit
fi
lsmod

if [ "$NOPAUSE" != "1" ] ; then
	echo "Press enter to continue: "
	read n
fi


# regular style mount
mount -t unionfs -o debug=${1:-$DEBUG},dirs=${BRANCHES}${EXTRAMOUNT}${IMAP} none ${MOUNTPOINT} || exit $?

if [ -f postdoit ] ; then
	source ./postdoit
fi
if [ -f postdoit.`uname -n` ] ; then
	source ./postdoit.`uname -n`
fi

exit 0
