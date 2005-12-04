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
f /n/lower/b1/d1/d2/d3/d4/.wh.c
FILES
}


function afterfiles_rw {
cat <<FILES
b /n/lower/b0/a

c /n/lower/b1/d5/b

b /n/lower/b1/d1/d2/d3/d4/c

FILES
}



function afterfiles_ro {
cat <<FILES
b /n/lower/b0/a

d /n/lower/b0/d5
c /n/lower/b0/d5/b

f /n/lower/b1/d1/d2/d3/d4/.wh.c
d /n/lower/b0/d1/d2
d /n/lower/b0/d1/d2/d3
d /n/lower/b0/d1/d2/d3/d4
b /n/lower/b0/d1/d2/d3/d4/c
FILES
}




( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1

mknod $MOUNTPOINT/a    b 200 0
checktype "$MOUNTPOINT/a" 'b'
mknod $MOUNTPOINT/d5/b  c  200 0
checktype "$MOUNTPOINT/d5/b" 'c'
mknod $MOUNTPOINT/d1/d2/d3/d4/c  b  200 0
checktype "$MOUNTPOINT/d1/d2/d3/d4/c" 'b'


unmount_union
( directories ; afterfiles_rw )  | check_hierarchy /n/lower


( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro

mknod $MOUNTPOINT/a   b  200 0
checktype "$MOUNTPOINT/a" 'b'
mknod $MOUNTPOINT/d5/b  c   200 0
checktype "$MOUNTPOINT/d5/b" 'c'
mknod $MOUNTPOINT/d1/d2/d3/d4/c   b  200 0
checktype "$MOUNTPOINT/d1/d2/d3/d4/c" 'b'

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy /n/lower

echo "OK"
