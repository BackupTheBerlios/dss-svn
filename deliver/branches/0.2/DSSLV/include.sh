#! /bin/bash
#!/bin/sh
#
# $Id$
#
# Script to build the Debased Live CD miniroot 
# Daniele Favara, (c) 2005 <danjele@gmail.com>
#
# <http://dss.berlios.de>

WINDOWMANAGER=$(which  x-window-manager)
BGIMAGE=/DSSLV/background.jpg



if [ -e "/cdrom/background.png" ]; then
        BGIMAGE="/cdrom/background.png"
fi

if [ -n "$(getbootparam wm)" ]; then
        WINDOWMANAGER="$(getbootparam wm)"
fi                                                                              

if [ -n "$(getbootparam background)" ]; then 
        BGIMAGE="$(getbootparam background)"
fi

