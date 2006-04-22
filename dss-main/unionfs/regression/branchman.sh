#!/bin/sh

# TEST: Branches: b0
# TEST:  add b1 before b0
# TEST:  add b1 after b0

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
d $LOWER_DIR/b3
d $LOWER_DIR/b4
FILES
}

function beforefiles {
cat <<FILES
f $LOWER_DIR/b0/b0-only
f $LOWER_DIR/b0/a
f $LOWER_DIR/b1/a
f $LOWER_DIR/b2/a
f $LOWER_DIR/b3/a
f $LOWER_DIR/b4/a
FILES
}

function afterfiles {
	beforefiles
}

function add_before {
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b0

	checktype $MOUNTPOINT/a 'f'
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -
	unionctl /mnt/unionfs --add --before $LOWER_DIR/b0 $LOWER_DIR/b1
	echo "$LOWER_DIR/b1/a" |diff $MOUNTPOINT/a -

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function add_after {
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b0

	checktype $MOUNTPOINT/a 'f'
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -
	unionctl /mnt/unionfs --add --after $LOWER_DIR/b0 $LOWER_DIR/b1
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function add_multiple {
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b0

	checktype $MOUNTPOINT/a 'f'
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -
	for ((i = 1; i <= 4; i++)) ; do
		unionctl /mnt/unionfs --add $LOWER_DIR/b$i
		echo "$LOWER_DIR/b$i/a" |diff $MOUNTPOINT/a -
	done

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function remove {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b1 $LOWER_DIR/b0

	echo "$LOWER_DIR/b1/a" |diff $MOUNTPOINT/a -
	unionctl /mnt/unionfs --remove $LOWER_DIR/b1
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -

	unmount_union

	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function remove_multiple {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0

	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -
	for ((i = 1; i <= 4; i++)) ; do
		unionctl /mnt/unionfs --add $LOWER_DIR/b$i
		echo "$LOWER_DIR/b$i/a" |diff $MOUNTPOINT/a -
	done

	for ((i = 1; i < 4; i++)) ; do
		unionctl /mnt/unionfs --remove $LOWER_DIR/b$i
		echo "$LOWER_DIR/b4/a" |diff $MOUNTPOINT/a -
	done
	unionctl /mnt/unionfs --remove $LOWER_DIR/b4
	echo "$LOWER_DIR/b0/a" |diff $MOUNTPOINT/a -

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function BUG370 {
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b0=rw $LOWER_DIR/b0=ro

	unionctl $MOUNTPOINT --mode $LOWER_DIR/b0 ro
	unionctl $MOUNTPOINT --mode $LOWER_DIR/b0 rw
	unionctl $MOUNTPOINT --add --mode rw $LOWER_DIR/b1
	unionctl $MOUNTPOINT --mode $LOWER_DIR/b0 ro
	unionctl $MOUNTPOINT --add --mode rw $LOWER_DIR/b1
	unionctl $MOUNTPOINT --remove $LOWER_DIR/b1
	unionctl $MOUNTPOINT --mode $LOWER_DIR/b0 ro
	unionctl $MOUNTPOINT --add --mode rw $LOWER_DIR/b1

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}

function query {
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b*

cat <<TMP >/tmp/$$
$MOUNTPOINT	$LOWER_DIR/b0 (rw)
$MOUNTPOINT	$LOWER_DIR/b1 (rw)
$MOUNTPOINT	$LOWER_DIR/b2 (rw)
$MOUNTPOINT	$LOWER_DIR/b3 (rw)
$MOUNTPOINT	$LOWER_DIR/b4 (rw)
TMP
	unionctl $MOUNTPOINT --query |diff - /tmp/$$
cat <<TMP >/tmp/$$
$MOUNTPOINT/b0-only	$LOWER_DIR/b0 (rw)
TMP
	unionctl $MOUNTPOINT/b0-only --query |diff - /tmp/$$
cat <<TMP >/tmp/$$
$MOUNTPOINT/a	$LOWER_DIR/b0 (rw)
$MOUNTPOINT/a	$LOWER_DIR/b1 (rw)
$MOUNTPOINT/a	$LOWER_DIR/b2 (rw)
$MOUNTPOINT/a	$LOWER_DIR/b3 (rw)
$MOUNTPOINT/a	$LOWER_DIR/b4 (rw)
TMP
	unionctl $MOUNTPOINT/a --query |diff - /tmp/$$
	rm -f /tmp/$$

	unmount_union
	( files ; afterfiles )  | check_hierarchy $LOWER_DIR
}


if [ -z "$FXNS" ] ; then
	FXNS="add_before add_after add_multiple remove remove_multiple BUG370 query"
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
