#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: link(A, B)
# TEST:  Where A and B are in the same directory on b0/b1
# TEST:  Where A and B are in different directories on b0/b1
# TEST:  Where A is on b0 and B is on b1
# TEST:  Where A is on b1 and B is on b0
# TEST:  Where B already exists as a whiteout on the same branch
# TEST:  Where B already exists as a whiteout on a higher priority branch
# TEST:  Where A exists in b0 and B exists in b1 in a different directory (should create
#        same directory structure in b0)

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
d $LOWER_DIR/b1/d7
d $LOWER_DIR/b1/d8

FILES
}

# initial set of files
function beforefiles {
cat <<FILES
f $LOWER_DIR/b0/a

f $LOWER_DIR/b0/b

f $LOWER_DIR/b0/c

f $LOWER_DIR/b1/d5/d

f $LOWER_DIR/b0/d1/f
f $LOWER_DIR/b0/d1/.wh.g

f $LOWER_DIR/b0/d1/.wh.h
f $LOWER_DIR/b1/d1/i

f $LOWER_DIR/b0/d6/x

f $LOWER_DIR/b1/d7/j

FILES
}

function beforefiles_391 {
cat <<FILES
d $LOWER_DIR/b1/d
f $LOWER_DIR/b1/d/a
FILES
}

function afterfiles_391 {
beforefiles_391
cat <<FILES
d $LOWER_DIR/b0/d
f $LOWER_DIR/b0/d/a
f $LOWER_DIR/b0/d/b
FILES
}


function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b0/k

f $LOWER_DIR/b0/b
f $LOWER_DIR/b0/d1/l

f $LOWER_DIR/b0/c
f $LOWER_DIR/b0/d1/d2/m

f $LOWER_DIR/b1/d5/d
f $LOWER_DIR/b1/n

f $LOWER_DIR/b0/d1/f
f $LOWER_DIR/b0/d1/g

f $LOWER_DIR/b1/d1/h
f $LOWER_DIR/b1/d1/i

f $LOWER_DIR/b0/d6/x
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b0/d1/d2/d3
d $LOWER_DIR/b0/d1/d2/d3/d4
f $LOWER_DIR/b0/d1/d2/d3/d4/j

f $LOWER_DIR/b1/d7/j
f $LOWER_DIR/b1/d8/k

FILES
}

function afterfiles_onelink {
beforefiles
cat <<FILES
f $LOWER_DIR/b0/k
FILES
}

function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b0/k

f $LOWER_DIR/b0/b
f $LOWER_DIR/b0/d1/l

f $LOWER_DIR/b0/c
f $LOWER_DIR/b0/d1/d2/m

f $LOWER_DIR/b1/d5/d
f $LOWER_DIR/b0/d5/d
d $LOWER_DIR/b0/d5
f $LOWER_DIR/b0/n

f $LOWER_DIR/b0/d1/f
f $LOWER_DIR/b0/d1/g

f $LOWER_DIR/b0/d1/h
f $LOWER_DIR/b0/d1/i
f $LOWER_DIR/b1/d1/i

f $LOWER_DIR/b0/d6/x
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b0/d1/d2/d3
d $LOWER_DIR/b0/d1/d2/d3/d4
f $LOWER_DIR/b0/d1/d2/d3/d4/j

d $LOWER_DIR/b0/d7
d $LOWER_DIR/b0/d8
f $LOWER_DIR/b1/d7/j
f $LOWER_DIR/b0/d7/j
f $LOWER_DIR/b0/d8/k

FILES
}

function rw {
	( directories ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1


	link $MOUNTPOINT/a $MOUNTPOINT/k
	link $MOUNTPOINT/b $MOUNTPOINT/d1/l
	link $MOUNTPOINT/c $MOUNTPOINT/d1/d2/m
	link $MOUNTPOINT/d5/d $MOUNTPOINT/n
	link $MOUNTPOINT/d1/f $MOUNTPOINT/d1/g
	link $MOUNTPOINT/d1/i $MOUNTPOINT/d1/h
	link $MOUNTPOINT/d6/x $MOUNTPOINT/d1/d2/d3/d4/j
	link $MOUNTPOINT/d7/j $MOUNTPOINT/d8/k

	unmount_union
	( directories ; afterfiles_rw )  | check_hierarchy $LOWER_DIR
}

function onelink {
	( directories ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1

	link $MOUNTPOINT/a $MOUNTPOINT/k

	unmount_union
	( directories ; afterfiles_onelink )  | check_hierarchy $LOWER_DIR
}

function ro {
	( directories ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

	link $MOUNTPOINT/a $MOUNTPOINT/k
	link $MOUNTPOINT/b $MOUNTPOINT/d1/l
	link $MOUNTPOINT/c $MOUNTPOINT/d1/d2/m
	link $MOUNTPOINT/d5/d $MOUNTPOINT/n  ## source is on EROFS
	link $MOUNTPOINT/d1/f $MOUNTPOINT/d1/g
	link $MOUNTPOINT/d1/i $MOUNTPOINT/d1/h  ## source is on EROFS
	link $MOUNTPOINT/d6/x $MOUNTPOINT/d1/d2/d3/d4/j
	link $MOUNTPOINT/d7/j $MOUNTPOINT/d8/k

	unmount_union
	( directories ; afterfiles_ro )  | check_hierarchy $LOWER_DIR
}

function BUG391 {
	( directories ; beforefiles_391) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

	link $MOUNTPOINT/d/a $MOUNTPOINT/d/b
	checktype $MOUNTPOINT/d 'd'
	checktype $MOUNTPOINT/d/a 'f'
	checktype $MOUNTPOINT/d/b 'f'

	unmount_union
	( directories ; afterfiles_391)  | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="rw ro onelink BUG391"
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
