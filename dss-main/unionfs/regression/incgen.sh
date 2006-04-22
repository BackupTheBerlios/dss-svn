#!/bin/sh

# TEST: Branches: b0
# TEST:  Increment the generation number 10 times.

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
FILES
}


( files ) | create_hierarchy
mount_union "" $LOWER_DIR/b0

for ((i = 2; i < 12; i++))
do
	echo "New generation $i" >/tmp/$$
	uniondbg -g  $MOUNTPOINT | diff /tmp/$$ -
	rm /tmp/$$
done

unmount_union
( files )  | check_hierarchy $LOWER_DIR

complete_test
