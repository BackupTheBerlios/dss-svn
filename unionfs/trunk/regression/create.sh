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
d /n/lower
d /n/lower/b0
d /n/lower/b0/d1
d /n/lower/b0/d1/d2
d /n/lower/b0/d6
d /n/lower/b1
d /n/lower/b1/d5
d /n/lower/b1/d1
d /n/lower/b1/d1/x
d /n/lower/b1/d1/d2
d /n/lower/b1/d1/d2/d3
d /n/lower/b2
d /n/lower/b2/d5
d /n/lower/b2/d1
d /n/lower/b2/d1/d2
d /n/lower/b2/d1/d2/d3
f /n/lower/b2/d1/d2/d3/a
f /n/lower/b2/d1/d2/d3/b
f /n/lower/b2/d1/d2/d3/c
d /n/lower/b2/d1/d2/d3/d4

FILES
}

# initial set of files
function beforefiles {
cat <<FILES

f /n/lower/b0/d1/.wh.x

f /n/lower/b2/d1/d2/d3/d4/.wh.d

FILES
}


function afterfiles_rw {
cat <<FILES
f /n/lower/b0/y

f /n/lower/b0/d1/x

f /n/lower/b2/d1/d2/d3/d4/d

FILES
}


function afterfiles_ro {
cat <<FILES
f /n/lower/b0/y

f /n/lower/b0/d1/x

d /n/lower/b0/d1/d2/d3
d /n/lower/b0/d1/d2/d3/d4
f /n/lower/b0/d1/d2/d3/d4/d
f /n/lower/b2/d1/d2/d3/d4/.wh.d

FILES
}


##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1 /n/lower/b2

touch $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'f'
touch $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'f'
touch $MOUNTPOINT/d1/d2/d3/d4/d
checktype $MOUNTPOINT/d1/d2/d3/d4/d 'f'

unmount_union
( directories ; afterfiles_rw )  | check_hierarchy /n/lower



##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro /n/lower/b2=ro

touch $MOUNTPOINT/y
checktype $MOUNTPOINT/y 'f'
touch $MOUNTPOINT/d1/x
checktype $MOUNTPOINT/d1/x 'f'
touch $MOUNTPOINT/d1/d2/d3/d4/d
checktype $MOUNTPOINT/d1/d2/d3/d4/d 'f'

unmount_union
( directories ; afterfiles_ro )  | check_hierarchy /n/lower

echo "OK"
exit 0
