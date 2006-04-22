#!/bin/bash -norc
set -x
PATH=/sbin:.:/usr/local/fist:${PATH}
export PATH

if [ ! -z "$1" ] ; then
	uniondbg -d /mnt/unionfs $1
fi

umount /mnt/unionfs
lsmod
rmmod unionfs
lsmod

if [ -x ./postundoit.`uname -n` ] ; then
	./postundoit.`uname -n`
elif [ -x ./postundoit ] ; then
	./postundoit
fi
