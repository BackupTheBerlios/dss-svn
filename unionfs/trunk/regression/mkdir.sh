#!/bin/sh

source scaffold

# initial directories
function directories {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b0/d6
d $LOWER_DIR/b1
d $LOWER_DIR/b1/d5
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
d $LOWER_DIR/b1/d1/d2/d3
f $LOWER_DIR/b1/d1/d2/d3/a
f $LOWER_DIR/b1/d1/d2/d3/b
f $LOWER_DIR/b1/d1/d2/d3/c
d $LOWER_DIR/b1/d1/d2/d3/d4
d $LOWER_DIR/b2
d $LOWER_DIR/b2/d5
d $LOWER_DIR/b2/d1
d $LOWER_DIR/b2/d1/d2
d $LOWER_DIR/b2/d1/d2/d3
f $LOWER_DIR/b2/d1/d2/d3/d
f $LOWER_DIR/b2/d1/d2/d3/e
f $LOWER_DIR/b2/d1/d2/d3/f
d $LOWER_DIR/b2/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES

f $LOWER_DIR/b0/d1/.wh.x

f $LOWER_DIR/b0/d1/d2/.wh.d3

FILES
}


function afterfiles_rw {
cat <<FILES
d $LOWER_DIR/b0/y

d $LOWER_DIR/b0/d1/x

d $LOWER_DIR/b0/d1/d2/d3

f $LOWER_DIR/b0/d1/d2/d3/.wh.__dir_opaque
f $LOWER_DIR/b0/d1/x/.wh.__dir_opaque
f $LOWER_DIR/b0/y/.wh.__dir_opaque

FILES
}



function afterfiles_ro {
cat <<FILES
d $LOWER_DIR/b0/y

d $LOWER_DIR/b0/d1/x

d $LOWER_DIR/b0/d1/d2/d3
f $LOWER_DIR/b0/d1/d2/d3/.wh.__dir_opaque
f $LOWER_DIR/b0/d1/x/.wh.__dir_opaque
f $LOWER_DIR/b0/y/.wh.__dir_opaque

FILES
}




##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1 $LOWER_DIR/b2


mkdir $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'd'
mkdir $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'd'
mkdir $MOUNTPOINT/d1/d2/d3
checktype $MOUNTPOINT/d1/d2/d3 'd'
checktype $MOUNTPOINT/d1/d2/d3/d4 '-'

unmount_union
( directories ; afterfiles_rw )  | check_hierarchy $LOWER_DIR




#### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

mkdir $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'd'
mkdir $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'd'
mkdir $MOUNTPOINT/d1/d2/d3
checktype $MOUNTPOINT/d1/d2/d3 'd'
checktype $MOUNTPOINT/d1/d2/d3/d4 '-'

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy $LOWER_DIR

complete_test
