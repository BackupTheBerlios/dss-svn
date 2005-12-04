#!/bin/sh

# TEST: Branches b0,b1 and b0,b1=ro
# TEST: mkdir A
# TEST:  Where A is in the same branch
# TEST:  Where A already exists as a whiteout on the same branch
# TEST:  Where A already exists as a whiteout on the same branch and there are 
#        pre-existing directories to the right (should create whiteouts inside A)
#
# TEST:  Where A is on a RO branch
# TEST:  Where A exists as a whiteout on a RO branch
# TEST:  Where A already exists as a whiteout on a RO branch and there are 
#        pre-existing directories to the right (should create whiteouts inside A)


source scaffold

# initial directories
function directories {
cat <<FILES
d /n/lower
d /n/lower/b0
d /n/lower/b0/d1
d /n/lower/b0/d1/d2
d /n/lower/b0/d6
d /n/lower/b1
d /n/lower/b1/d5
d /n/lower/b1/d1
d /n/lower/b1/d1/d2
d /n/lower/b1/d1/d2/d3
f /n/lower/b1/d1/d2/d3/a
f /n/lower/b1/d1/d2/d3/b
f /n/lower/b1/d1/d2/d3/c
d /n/lower/b1/d1/d2/d3/d4
d /n/lower/b2
d /n/lower/b2/d5
d /n/lower/b2/d1
d /n/lower/b2/d1/d2
d /n/lower/b2/d1/d2/d3
f /n/lower/b2/d1/d2/d3/d
f /n/lower/b2/d1/d2/d3/e
f /n/lower/b2/d1/d2/d3/f
d /n/lower/b2/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES

f /n/lower/b0/d1/.wh.x

f /n/lower/b0/d1/d2/.wh.d3

FILES
}


function afterfiles_rw {
cat <<FILES
d /n/lower/b0/y

d /n/lower/b0/d1/x

d /n/lower/b0/d1/d2/d3
f /n/lower/b0/d1/d2/d3/.wh.a
f /n/lower/b0/d1/d2/d3/.wh.b
f /n/lower/b0/d1/d2/d3/.wh.c
f /n/lower/b0/d1/d2/d3/.wh.d
f /n/lower/b0/d1/d2/d3/.wh.d4
f /n/lower/b0/d1/d2/d3/.wh.e
f /n/lower/b0/d1/d2/d3/.wh.f

FILES
}



function afterfiles_ro {
cat <<FILES
d /n/lower/b0/y

d /n/lower/b0/d1/x

d /n/lower/b0/d1/d2/d3
f /n/lower/b0/d1/d2/d3/.wh.a
f /n/lower/b0/d1/d2/d3/.wh.b
f /n/lower/b0/d1/d2/d3/.wh.c
f /n/lower/b0/d1/d2/d3/.wh.d
f /n/lower/b0/d1/d2/d3/.wh.d4
f /n/lower/b0/d1/d2/d3/.wh.e
f /n/lower/b0/d1/d2/d3/.wh.f

FILES
}




##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1 /n/lower/b2


mkdir $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'd'
mkdir $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'd'
mkdir $MOUNTPOINT/d1/d2/d3
checktype $MOUNTPOINT/d1/d2/d3 'd'
checktype $MOUNTPOINT/d1/d2/d3/d4 '-'

unmount_union
( directories ; afterfiles_rw )  | check_hierarchy /n/lower




##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro /n/lower/b2=ro

mkdir $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'd'
mkdir $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'd'
mkdir $MOUNTPOINT/d1/d2/d3
checktype $MOUNTPOINT/d1/d2/d3 'd'
checktype $MOUNTPOINT/d1/d2/d3/d4 '-'

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy /n/lower

echo "OK"
exit 0
