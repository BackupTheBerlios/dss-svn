#!/bin/sh
# TEST: Branches: b0,b1=ro and b0,b1
# TEST: flock(F_WRLCK) a file on b1

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
f $LOWER_DIR/b1/a
FILES
}

function afterfiles_ro {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1
f $LOWER_DIR/b1/a
FILES
}

function afterfiles_rw {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
f $LOWER_DIR/b1/a
FILES
}


( files ) | create_hierarchy
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro
./progs/flock-copyup $MOUNTPOINT/a
unmount_union
( afterfiles_ro ) | check_hierarchy $LOWER_DIR

( files ) | create_hierarchy
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1
./progs/flock-copyup $MOUNTPOINT/a
unmount_union
( afterfiles_rw ) | check_hierarchy $LOWER_DIR

complete_test
