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
d /n/lower
d /n/lower/b0
d /n/lower/b0/d1
d /n/lower/b0/d6
d /n/lower/b1
d /n/lower/b1/d5
d /n/lower/b1/d1
d /n/lower/b1/d1/d2
d /n/lower/b1/d1/d2/d3
d /n/lower/b1/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES
f /n/lower/b0/a

f /n/lower/b0/b

f /n/lower/b1/d1/d2/d3/d4/.wh.c

FILES
}


function afterfiles_rw {
cat <<FILES
f /n/lower/b0/a
l /n/lower/b0/d

f /n/lower/b0/b
l /n/lower/b1/d5/e

l /n/lower/b1/d1/d2/d3/d4/c

FILES
}



function afterfiles_ro {
cat <<FILES

f /n/lower/b0/a
l /n/lower/b0/d

f /n/lower/b0/b
d /n/lower/b0/d5
l /n/lower/b0/d5/e

f /n/lower/b1/d1/d2/d3/d4/.wh.c
d /n/lower/b0/d1/d2
d /n/lower/b0/d1/d2/d3
d /n/lower/b0/d1/d2/d3/d4
l /n/lower/b0/d1/d2/d3/d4/c

FILES
}




##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1

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
( directories ; afterfiles_rw )  | check_hierarchy /n/lower

( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro


ln --symbolic $MOUNTPOINT/a $MOUNTPOINT/d  
ln --symbolic $MOUNTPOINT/b $MOUNTPOINT/d5/e 
ln --symbolic $MOUNTPOINT/a $MOUNTPOINT/d1/d2/d3/d4/c 

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy /n/lower


echo "OK"
exit 0
