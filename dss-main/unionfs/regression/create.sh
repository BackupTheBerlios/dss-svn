#!/bin/sh

# TEST: Branches b0,b1,b2 and b0,b1=ro,b2=ro
# TEST: mkdir A
# TEST:  Where A is in the same branch
# TEST:  Where A already exists as a whiteout on the same branch
# TEST:  Where A already exists as a whiteout on the same branch and there are
#        pre-existing entries to the right
#
# TEST:  Where A is on a RO branch
# TEST:  Where A exists as a whiteout on a RO branch
# TEST:  Where A already exists as a whiteout on the same branch and there are
#        pre-existing entries to the right


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
d $LOWER_DIR/b1/d1/x
d $LOWER_DIR/b1/d1/d2
d $LOWER_DIR/b1/d1/d2/d3
d $LOWER_DIR/b2
d $LOWER_DIR/b2/d5
d $LOWER_DIR/b2/d1
d $LOWER_DIR/b2/d1/d2
d $LOWER_DIR/b2/d1/d2/d3
f $LOWER_DIR/b2/d1/d2/d3/a
f $LOWER_DIR/b2/d1/d2/d3/b
f $LOWER_DIR/b2/d1/d2/d3/c
d $LOWER_DIR/b2/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES

f $LOWER_DIR/b0/d1/.wh.x

f $LOWER_DIR/b2/d1/d2/d3/d4/.wh.d

FILES
}

function beforefiles_383 {
cat <<FILES
f $LOWER_DIR/b1/y
FILES
}
function afterfiles_383 {
cat <<FILES
f $LOWER_DIR/b0/y
f $LOWER_DIR/b1/y
FILES
}


function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b0/y

f $LOWER_DIR/b0/d1/x

f $LOWER_DIR/b2/d1/d2/d3/d4/d

FILES
}


function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/y

f $LOWER_DIR/b0/d1/x

d $LOWER_DIR/b0/d1/d2/d3
d $LOWER_DIR/b0/d1/d2/d3/d4
f $LOWER_DIR/b0/d1/d2/d3/d4/d
f $LOWER_DIR/b2/d1/d2/d3/d4/.wh.d

FILES
}

function rw {
	( directories ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1 $LOWER_DIR/b2

	touch $MOUNTPOINT/y
	checktype $MOUNTPOINT/y 'f'
	touch $MOUNTPOINT/d1/x
	checktype $MOUNTPOINT/d1/x 'f'
	touch $MOUNTPOINT/d1/d2/d3/d4/d
	checktype $MOUNTPOINT/d1/d2/d3/d4/d 'f'

	unmount_union
	( directories ; afterfiles_rw )  | check_hierarchy $LOWER_DIR
}


function ro {
	( directories ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

	touch $MOUNTPOINT/y
	checktype $MOUNTPOINT/y 'f'
	touch $MOUNTPOINT/d1/x
	checktype $MOUNTPOINT/d1/x 'f'
	touch $MOUNTPOINT/d1/d2/d3/d4/d
	checktype $MOUNTPOINT/d1/d2/d3/d4/d 'f'

	unmount_union
	( directories ; afterfiles_ro )  | check_hierarchy $LOWER_DIR
}

function BUG383 {
	( directories ; beforefiles_383 ) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

	local SM=`umask`
	umask 022
	checktype $MOUNTPOINT/y 'f'
	checkperms $MOUNTPOINT/y 644
	chmod 421 $MOUNTPOINT/y
	checkperms $MOUNTPOINT/y 421
	rm -f $MOUNTPOINT/y
	checktype $MOUNTPOINT/y '-'
	umask 026
	touch $MOUNTPOINT/y
	checktype $MOUNTPOINT/y 'f'
	checkperms $MOUNTPOINT/y 640

	umask $SM

	unmount_union
	( directories ; afterfiles_383 )  | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="rw ro BUG383"
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
