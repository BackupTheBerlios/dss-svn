#! /bin/bash
#!/bin/sh
#
# $Id$
#
# Script to build the Debased Live CD miniroot 
# Daniele Favara, (c) 2005 <danjele@gmail.com>
#
# <http://dss.berlios.de>

COLUMNS=90
export COLUMNS
if [ -d /morphix/rc.m/ ];then
	RCDIR=/morphix/rc.m/
elif [ -d /DSSLV/rc.m/ ];then
	RCDIR=/DSSLV/rc.m/
fi
if [ -f /morphix/include.sh ] ; then
	includeme=/morphix/include.sh
elif [ -f /DSSLV/include.sh ] ; then
	includeme=/DSSLV/include.sh
fi
. $includeme >/dev/null 2>&1
for file in $RCDIR/*
do
  echo "Running $file"
  . $file &
done

exit 0
