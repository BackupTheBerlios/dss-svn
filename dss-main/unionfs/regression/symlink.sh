#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: symlink(A, B)
# TEST:  Where A and B are in the same branch
# TEST:  Where A and B are in different branches
# TEST:  Where B already exists as a whiteout on the same branch
# TEST:  Where B exists as a whiteout on a RO branch



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
f $LOWER_DIR/b0/a

f $LOWER_DIR/b0/b

f $LOWER_DIR/b1/d1/d2/d3/d4/.wh.c

FILES
}


function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b0/a
l $LOWER_DIR/b0/d

f $LOWER_DIR/b0/b
l $LOWER_DIR/b1/d5/e

l $LOWER_DIR/b1/d1/d2/d3/d4/c

FILES
}



function afterfiles_ro {
cat <<FILES

f $LOWER_DIR/b0/a
l $LOWER_DIR/b0/d

f $LOWER_DIR/b0/b
d $LOWER_DIR/b0/d5
l $LOWER_DIR/b0/d5/e

f $LOWER_DIR/b1/d1/d2/d3/d4/.wh.c
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b0/d1/d2/d3
d $LOWER_DIR/b0/d1/d2/d3/d4
l $LOWER_DIR/b0/d1/d2/d3/d4/c

FILES
}




##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1

function do_link {
	SOURCE=$1
	DEST=$2

	ln --symbolic $SOURCE $DEST || return $?

	if [ `readlink $DEST` != "$SOURCE" ] ; then
		echo "readlink('$DEST') does not match '$SOURCE'" 1>&2
		return 1
	fi

	return 0
}

do_link $MOUNTPOINT/a $MOUNTPOINT/d
do_link $MOUNTPOINT/b $MOUNTPOINT/d5/e
do_link $MOUNTPOINT/a $MOUNTPOINT/d1/d2/d3/d4/c

unmount_union
( directories ; afterfiles_rw )  | check_hierarchy $LOWER_DIR

( directories ; beforefiles) | create_hierarchy

mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro


ln --symbolic $MOUNTPOINT/a $MOUNTPOINT/d
ln --symbolic $MOUNTPOINT/b $MOUNTPOINT/d5/e
ln --symbolic $MOUNTPOINT/a $MOUNTPOINT/d1/d2/d3/d4/c

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy $LOWER_DIR


complete_test
