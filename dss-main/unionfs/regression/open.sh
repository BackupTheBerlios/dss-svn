#!/bin/sh

# TEST: Branches: b0,b1=ro,b2=ro
# TEST: open(D) where D is
# TEST:  a directory in b0
# TEST:  nonexistent in b1
# TEST:  a directory in b0

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
FILES
}

function beforefiles {
cat <<FILES
d $LOWER_DIR/b0/a
d $LOWER_DIR/b2/a

f $LOWER_DIR/b0/b
f $LOWER_DIR/b1/c
f $LOWER_DIR/b2/d

f $LOWER_DIR/b0/e
f $LOWER_DIR/b1/e
f $LOWER_DIR/b2/e
FILES
}

function afterfiles {
	beforefiles
}

function beforefiles_copyup {
cat <<FILES
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
f $LOWER_DIR/b1/d1/d2/a
FILES
}

function afterfiles_copyup {
cat <<FILES
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d1/d2
f $LOWER_DIR/b0/d1/d2/a
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
f $LOWER_DIR/b1/d1/d2/a
FILES
}

function ro {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

	checktype $MOUNTPOINT/a 'd'
	/bin/ls $MOUNTPOINT/a >/dev/null

	echo "$LOWER_DIR/b0/b" |diff /mnt/unionfs/b -
	echo "$LOWER_DIR/b1/c" |diff /mnt/unionfs/c -
	echo "$LOWER_DIR/b2/d" |diff /mnt/unionfs/d -

	echo "$LOWER_DIR/b0/e" |diff /mnt/unionfs/e -

	unmount_union

	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function copyup {
	( files ; beforefiles_copyup) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

	checktype $MOUNTPOINT/d1/d2/a 'f'
	echo "$LOWER_DIR/b1/d1/d2/a" |diff /mnt/unionfs/d1/d2/a -
	echo "New data" > /mnt/unionfs/d1/d2/a
	echo "New data" |diff /mnt/unionfs/d1/d2/a -

	unmount_union

	( files ; afterfiles_copyup )  | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="ro copyup"
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
