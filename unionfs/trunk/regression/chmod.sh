#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: chmod(A, 700)
# TEST:  Where A is in b0, b1, and both as a file/directory


source scaffold

# initial directories
function beforefiles {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
f $LOWER_DIR/b0/a
f $LOWER_DIR/b0/b
d $LOWER_DIR/b0/c
d $LOWER_DIR/b0/d

d $LOWER_DIR/b1
f $LOWER_DIR/b1/a
d $LOWER_DIR/b1/c
f $LOWER_DIR/b1/e
d $LOWER_DIR/b1/f

FILES
}

# initial set of files
function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/e
d $LOWER_DIR/b0/f
FILES
}

function do_chmod {
	TARGET=$1

	chmod 700 $TARGET || return $?

	if [ `find $TARGET -printf '%m'` != "700" ] ; then
		echo "Permissions for $TARGET are not 700" 1>&2
		return 1
	fi

	chmod 644 $TARGET || return $?

	if [ `find $TARGET -printf '%m'` != "644" ] ; then
		echo "Permissions for $TARGET are not 644" 1>&2
		return 1
	fi

	return 0
}

( beforefiles ) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1

do_chmod $MOUNTPOINT/a
do_chmod $MOUNTPOINT/b
do_chmod $MOUNTPOINT/c
do_chmod $MOUNTPOINT/d
do_chmod $MOUNTPOINT/e
do_chmod $MOUNTPOINT/f

unmount_union

( beforefiles )  | check_hierarchy $LOWER_DIR
echo -n "[rw] "

# The readonly tests
( beforefiles ) | create_hierarchy
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

do_chmod $MOUNTPOINT/a
do_chmod $MOUNTPOINT/b
do_chmod $MOUNTPOINT/c
do_chmod $MOUNTPOINT/d
do_chmod $MOUNTPOINT/e
do_chmod $MOUNTPOINT/f

unmount_union
( beforefiles ; afterfiles_ro )  | check_hierarchy $LOWER_DIR
echo -n "[ro] "

complete_test
