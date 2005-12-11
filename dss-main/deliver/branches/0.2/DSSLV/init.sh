#!/bin/sh

# $Id: DSSLV-functions 33 2005-10-11 05:38:40Z nomed $

# DSS-LV 
# Daniele Favara <danjele@gmail.com> 2005
# <http://dss.berlios.de>


COLUMNS=90
export COLUMNS
. /etc/deliver.conf
. $FUNCS 
. $INCLUDEME >/dev/null 2>&1
for file in $RCDIR/*
do
  echo "Running $file"
  . $file &
done

exit 0
