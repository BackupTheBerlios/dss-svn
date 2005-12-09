#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: chmod(A, 700)
# TEST:  Where A is in b0, b1, and both as a file/directory


source scaffold

# initial directories
function beforefiles {
cat <<FILES
d /n/lower
d /n/lower/b0
f /n/lower/b0/a
f /n/lower/b0/b
d /n/lower/b0/c
d /n/lower/b0/d

d /n/lower/b1
f /n/lower/b1/a
d /n/lower/b1/c
f /n/lower/b1/e
d /n/lower/b1/f

FILES
}

# initial set of files
function afterfiles_ro {
cat <<FILES
f /n/lower/b0/e
d /n/lower/b0/f
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

mount_union "" /n/lower/b0 /n/lower/b1

do_chmod $MOUNTPOINT/a
do_chmod $MOUNTPOINT/b
do_chmod $MOUNTPOINT/c
do_chmod $MOUNTPOINT/d
do_chmod $MOUNTPOINT/e
do_chmod $MOUNTPOINT/f

unmount_union

( beforefiles )  | check_hierarchy /n/lower
echo -n "[rw] "

# The readonly tests
( beforefiles ) | create_hierarchy
mount_union "" /n/lower/b0 /n/lower/b1=ro

do_chmod $MOUNTPOINT/a
do_chmod $MOUNTPOINT/b
do_chmod $MOUNTPOINT/c
do_chmod $MOUNTPOINT/d
do_chmod $MOUNTPOINT/e
do_chmod $MOUNTPOINT/f

unmount_union
( beforefiles ; afterfiles_ro )  | check_hierarchy /n/lower
echo -n "[ro] "

echo "OK"
exit 0
