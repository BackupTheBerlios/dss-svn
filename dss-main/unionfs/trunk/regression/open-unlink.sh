#!/bin/sh
# TEST: Branches: b0,b1=ro and b0,b1
# TEST: open(a), unlink(a), receate(a), unlink(a)
# TEST:  at each point verify the contents of a using the original fd

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
f $LOWER_DIR/b0/.wh.a
d $LOWER_DIR/b1
f $LOWER_DIR/b1/a
FILES
}

function afterfiles_rw {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
FILES
}


( files ) | create_hierarchy
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro
./progs/open-unlink $MOUNTPOINT/a
unmount_union
( afterfiles_ro ) | check_hierarchy $LOWER_DIR

complete_test
