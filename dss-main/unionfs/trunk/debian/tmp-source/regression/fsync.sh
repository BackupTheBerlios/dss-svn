#!/bin/sh
# TEST: Branches: b0,b1=ro and b0,b1
# TEST: flock(F_WRLCK) a file on b1

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
f $LOWER_DIR/b0/a
FILES
}

function rw {
	( files ) | create_hierarchy
	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1
	./progs/fsync $MOUNTPOINT/a
	unmount_union
	( files ) | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="rw"
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
