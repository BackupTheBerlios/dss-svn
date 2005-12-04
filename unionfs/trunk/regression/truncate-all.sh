#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: truncate(F)
# TEST:  F on b1 to zero
# TEST:  F on b1 to a non-zero size less than the original
# TEST:  F on b1 to a larger size than the original
# TEST:  F on b0 and b1 to zero
# TEST: WHERE x = 0, 0 < x < size(f), and size(f) < x
# TEST: Using the following branch configurations
# TEST: Branches b0,b1 and b0,b1=ro
# TEST:  F on b0
# TEST:  F on b1
# TEST:  F on b2
# TEST:  F on b0,b1
# TEST: Branches b0,b1,b2
# TEST:  F on b0,b1,b2
# TEST:  F on b0,b1(immutable),b2
# TEST: Branches b0,b1=ro,b2
# TEST:  F on b0,b1,b2

source scaffold

# initial directories
function directories {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
d $LOWER_DIR/b2/d1
d $LOWER_DIR/b2/d1/d2
d $LOWER_DIR/b2/d1/d2/d3
d $LOWER_DIR/b2/d1/d2/d3/d4
FILES
}


(directories) | create_hierarchy

dd if=/dev/zero of=$LOWER_DIR/b0/a bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b0/b bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b0/c bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b0/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b1/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b2/d bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b2/d1/d2/d3/d4/e bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b2/d1/d2/d3/d4/f bs=4000 count=2 2>/dev/null

if havechattr $LOWER_DIR ; then
	CHATTR=1
	chattr +i $LOWER_DIR/b2/d1/d2/d3/d4/f
fi

# mount unionfs
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1 $LOWER_DIR/b2

./progs/truncate -f $MOUNTPOINT/a 0

./progs/truncate -f $MOUNTPOINT/b 5000

./progs/truncate -f $MOUNTPOINT/c 10000

./progs/truncate -f $MOUNTPOINT/d 10000

./progs/truncate -f $MOUNTPOINT/d1/d2/d3/d4/e 10000

if [ ! -z "$CHATTR" ] ; then
	shouldfail ./truncate -f $MOUNTPOINT/d1/d2/d3/d4/f 10000
fi

unmount_union



#### do same tests with mix of ro branches

(directories) | create_hierarchy

dd if=/dev/zero of=$LOWER_DIR/b0/a bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b0/b bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b0/c bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b0/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b1/d bs=4000 count=2 2>/dev/null
dd if=/dev/zero of=$LOWER_DIR/b2/d bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b2/d1/d2/d3/d4/e bs=4000 count=2 2>/dev/null

dd if=/dev/zero of=$LOWER_DIR/b2/d1/d2/d3/d4/f bs=4000 count=2 2>/dev/null
if [ ! -z "$CHATTR" ] ; then
	chattr +i $LOWER_DIR/b2/d1/d2/d3/d4/f
fi


mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

./progs/truncate -f $MOUNTPOINT/a 0

./progs/truncate -f $MOUNTPOINT/b 5000

./progs/truncate -f $MOUNTPOINT/c 10000

./progs/truncate -f $MOUNTPOINT/d 10000

./progs/truncate -f $MOUNTPOINT/d1/d2/d3/d4/e 10000

if [ ! -z "$CHATTR" ] ; then
	shouldfail ./progs/truncate -f $MOUNTPOINT/d1/d2/d3/d4/f 10000
fi

unmount_union

complete_test
