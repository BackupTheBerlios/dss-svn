#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: mknod A
# TEST:  Where A is in the same branch
# TEST:  Where A already exists as a whiteout on the same branch
# TEST:  Where A exists as a whiteout on a RO branch

source scaffold

# initial directories
function directories {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d6
d $LOWER_DIR/b1
d $LOWER_DIR/b1/d5
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
d $LOWER_DIR/b1/d1/d2/d3
d $LOWER_DIR/b1/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES
f $LOWER_DIR/b1/d1/d2/d3/d4/.wh.c
FILES
}


function afterfiles_rw {
cat <<FILES
b $LOWER_DIR/b0/a

c $LOWER_DIR/b1/d5/b

b $LOWER_DIR/b1/d1/d2/d3/d4/c

FILES
}



function afterfiles_ro {
cat <<FILES
b $LOWER_DIR/b0/a

d $LOWER_DIR/b0/d5
c $LOWER_DIR/b0/d5/b

f $LOWER_DIR/b1/d1/d2/d3/d4/.wh.c
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b0/d1/d2/d3
d $LOWER_DIR/b0/d1/d2/d3/d4
b $LOWER_DIR/b0/d1/d2/d3/d4/c
FILES
}




( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1

mknod $MOUNTPOINT/a    b 200 0
checktype "$MOUNTPOINT/a" 'b'
mknod $MOUNTPOINT/d5/b  c  200 0
checktype "$MOUNTPOINT/d5/b" 'c'
mknod $MOUNTPOINT/d1/d2/d3/d4/c  b  200 0
checktype "$MOUNTPOINT/d1/d2/d3/d4/c" 'b'


unmount_union
( directories ; afterfiles_rw )  | check_hierarchy $LOWER_DIR


( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

mknod $MOUNTPOINT/a   b  200 0
checktype "$MOUNTPOINT/a" 'b'
mknod $MOUNTPOINT/d5/b  c   200 0
checktype "$MOUNTPOINT/d5/b" 'c'
mknod $MOUNTPOINT/d1/d2/d3/d4/c   b  200 0
checktype "$MOUNTPOINT/d1/d2/d3/d4/c" 'b'

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy $LOWER_DIR

complete_test
