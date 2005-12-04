#!/bin/sh

# TEST: lookup(F), where F is:
# TEST: 	File-Directory-File
# TEST:		Directory-File-Directory
# TEST:		Whiteout-Directory

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2

f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a
f $LOWER_DIR/b2/a

d $LOWER_DIR/b0/b
f $LOWER_DIR/b1/b
d $LOWER_DIR/b2/b

f $LOWER_DIR/b1/.wh.c
d $LOWER_DIR/b2/c
f $LOWER_DIR/b2/c/d
FILES
}

files | create_hierarchy

mount_union "" $LOWER_DIR/b?

checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'd'
checktype $MOUNTPOINT/c '-'




unmount_union

files | check_hierarchy $LOWER_DIR

complete_test
