#!/bin/bash

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
f $LOWER_DIR/b0/foo
FILES
}

function afterfiles {
cat <<FILES
f $LOWER_DIR/b1/foo
FILES
}

( files ) | create_hierarchy

mount_union "" $LOWER_DIR/b0

./progs/bug418 /mnt/unionfs/foo &
sleep 2
unionctl /mnt/unionfs --add /n/lower/b1
unionctl /mnt/unionfs --mode /n/lower/b0 ro
sleep 10

unmount_union
( files ; afterfiles )  | check_hierarchy $LOWER_DIR

complete_test
