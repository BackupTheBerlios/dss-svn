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
d /n/lower/b1/d7
d /n/lower/b1/d8

FILES
}

# initial set of files
function beforefiles {
cat <<FILES
f /n/lower/b0/a

f /n/lower/b0/b

f /n/lower/b0/c

f /n/lower/b1/d5/d

f /n/lower/b0/d1/f
f /n/lower/b0/d1/.wh.g

f /n/lower/b0/d1/.wh.h
f /n/lower/b1/d1/i

f /n/lower/b0/d6/x

f /n/lower/b1/d7/j

FILES
}


function afterfiles_rw {
cat <<FILES
f /n/lower/b0/a
f /n/lower/b0/k

f /n/lower/b0/b
f /n/lower/b0/d1/l

f /n/lower/b0/c
f /n/lower/b0/d1/d2/m

f /n/lower/b1/d5/d
f /n/lower/b1/n

f /n/lower/b0/d1/f
f /n/lower/b0/d1/g

f /n/lower/b1/d1/h
f /n/lower/b1/d1/i

f /n/lower/b0/d6/x
d /n/lower/b0/d1/d2
d /n/lower/b0/d1/d2/d3
d /n/lower/b0/d1/d2/d3/d4
f /n/lower/b0/d1/d2/d3/d4/j

f /n/lower/b1/d7/j
f /n/lower/b1/d8/k

FILES
}




function afterfiles_ro {
cat <<FILES
f /n/lower/b0/a
f /n/lower/b0/k

f /n/lower/b0/b
f /n/lower/b0/d1/l

f /n/lower/b0/c
f /n/lower/b0/d1/d2/m

f /n/lower/b1/d5/d
f /n/lower/b0/d5/d
d /n/lower/b0/d5
f /n/lower/b0/n

f /n/lower/b0/d1/f
f /n/lower/b0/d1/g

f /n/lower/b0/d1/h
f /n/lower/b0/d1/i
f /n/lower/b1/d1/i

f /n/lower/b0/d6/x
d /n/lower/b0/d1/d2
d /n/lower/b0/d1/d2/d3
d /n/lower/b0/d1/d2/d3/d4
f /n/lower/b0/d1/d2/d3/d4/j

d /n/lower/b0/d7
d /n/lower/b0/d8
f /n/lower/b1/d7/j
f /n/lower/b0/d7/j
f /n/lower/b0/d8/k

FILES
}

##### read-write
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1


link $MOUNTPOINT/a $MOUNTPOINT/k
link $MOUNTPOINT/b $MOUNTPOINT/d1/l
link $MOUNTPOINT/c $MOUNTPOINT/d1/d2/m
link $MOUNTPOINT/d5/d $MOUNTPOINT/n
link $MOUNTPOINT/d1/f $MOUNTPOINT/d1/g
link $MOUNTPOINT/d1/i $MOUNTPOINT/d1/h
link $MOUNTPOINT/d6/x $MOUNTPOINT/d1/d2/d3/d4/j
link $MOUNTPOINT/d7/j $MOUNTPOINT/d8/k

unmount_union
( directories ; afterfiles_rw )  | check_hierarchy /n/lower
echo -n "[rw] "

##### readonly
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro


link $MOUNTPOINT/a $MOUNTPOINT/k
link $MOUNTPOINT/b $MOUNTPOINT/d1/l
link $MOUNTPOINT/c $MOUNTPOINT/d1/d2/m
link $MOUNTPOINT/d5/d $MOUNTPOINT/n  ## source is on EROFS
link $MOUNTPOINT/d1/f $MOUNTPOINT/d1/g
link $MOUNTPOINT/d1/i $MOUNTPOINT/d1/h  ## source is on EROFS
link $MOUNTPOINT/d6/x $MOUNTPOINT/d1/d2/d3/d4/j
link $MOUNTPOINT/d7/j $MOUNTPOINT/d8/k

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy /n/lower
echo -n "[ro] "

echo "OK"
exit 0
