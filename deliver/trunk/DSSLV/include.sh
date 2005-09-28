#! /bin/bash
# $Id$

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:."
CMDLINE="$(cat /proc/cmdline)"
[ -e  "/lib/lsb/DSSLV-functions" ] && . /lib/lsb/DSSLV-functions 

WINDOWMANAGER=$(which  x-window-manager)
USER="debaser"
if [ -f /morphix/background.png ];then
BGIMAGE=/morphix/background.png
elif [ -f /DSSLV/background.jpg ];then
BGIMAGE=/DSSLV/background.jpg
fi
XServer=xorg


if [ -e "/cdrom/background.png" ]; then
        BGIMAGE="/cdrom/background.png"
fi

if [ -n "$(getbootparam wm)" ]; then
        WINDOWMANAGER="$(getbootparam wm)"
fi                                                                              

if [ -n "$(getbootparam background)" ]; then 
        BGIMAGE="$(getbootparam background)"
fi

if [ -n "$(getbootparam username)" ]; then
	USER="$(getbootparam username)"
fi
