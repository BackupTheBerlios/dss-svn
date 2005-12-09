#!/bin/sh

# TEST: lookup(F), where F is:
# TEST: 	File-Directory-File
# TEST:		Directory-File-Directory
# TEST:		Whiteout-Directory

source scaffold

function files {
cat <<FILES
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b2

f /n/lower/b0/a
d /n/lower/b1/a
f /n/lower/b2/a

d /n/lower/b0/b
f /n/lower/b1/b
d /n/lower/b2/b

f /n/lower/b1/.wh.c
d /n/lower/b2/c
f /n/lower/b2/c/d
FILES
}

files | create_hierarchy

mount_union "" /n/lower/b?

checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'd'
checktype $MOUNTPOINT/c '-'




unmount_union

files | check_hierarchy /n/lower

echo "OK"
exit 0
