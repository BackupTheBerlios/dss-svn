#!/bin/sh

# TEST: Branches: b0,b1=ro and b0,b1
#       rmdir_all(D) where D is a directory in b0 or b1 or both
#
#       D is a file in b0, D is a directory in b1
#       D is a directory in b0, D is a file in b1
#       D is a file in both b0 and b1
#       D is a directory in both b0 and b1
#       .wh.D is a whiteout in b0 and D is a directory in b1
#       D is in b0 (not empty) and in b1 (not empty)
#       D is in b0 (empty) and in b1 (not empty)
#       D is in b0 (not empty) and in b1 (empty)
#       D is in b0 (has whiteouts) and in b1 (not empty)
#       D is in b0 (not empty) and in b1 (has whiteouts)
#       D is in b0 (not empty)
#
# TEST: after rmdir, mkdir back removed directories again



source scaffold

# initial directories
function directories {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d2
d $LOWER_DIR/b0/d3
d $LOWER_DIR/b0/d4
d $LOWER_DIR/b0/d5
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d2
d $LOWER_DIR/b1/d3
d $LOWER_DIR/b1/d4
d $LOWER_DIR/b1/d5
FILES
}

# initial set of files
function beforefiles {
cat <<FILES
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a

d $LOWER_DIR/b0/b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

d $LOWER_DIR/b0/d
d $LOWER_DIR/b1/d

f $LOWER_DIR/b0/.wh.e
d $LOWER_DIR/b1/e

d $LOWER_DIR/b0/d1/f
d $LOWER_DIR/b1/d1/g

d $LOWER_DIR/b0/d2/
d $LOWER_DIR/b1/d2/h

d $LOWER_DIR/b0/d3/i
d $LOWER_DIR/b1/d3/

f $LOWER_DIR/b0/d4/.wh.j
d $LOWER_DIR/b1/d4/j

d $LOWER_DIR/b0/d5/k
f $LOWER_DIR/b1/d5/.wh.k
FILES
}






function after_directories_rw {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d2
d $LOWER_DIR/b0/d3
d $LOWER_DIR/b0/d5
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d2
d $LOWER_DIR/b1/d3
d $LOWER_DIR/b1/d4
d $LOWER_DIR/b1/d5
FILES
}


function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a

f $LOWER_DIR/b0/.wh.b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/.wh.e
d $LOWER_DIR/b1/e

d $LOWER_DIR/b0/d1/f
d $LOWER_DIR/b1/d1/g

d $LOWER_DIR/b1/d2/h

d $LOWER_DIR/b0/d3/i

f $LOWER_DIR/b0/.wh.d4
d $LOWER_DIR/b1/d4/j

d $LOWER_DIR/b0/d5/k
f $LOWER_DIR/b1/d5/.wh.k
FILES
}


function afterfiles_mkdir_back_rw {
cat <<FILES
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a

f $LOWER_DIR/b0/.wh.b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

d $LOWER_DIR/b0/d
f $LOWER_DIR/b0/d/.wh.__dir_opaque

f $LOWER_DIR/b0/.wh.e
d $LOWER_DIR/b1/e

d $LOWER_DIR/b0/d1/f
d $LOWER_DIR/b1/d1/g

d $LOWER_DIR/b1/d2/h

d $LOWER_DIR/b0/d3/i

d $LOWER_DIR/b0/d4
f $LOWER_DIR/b0/d4/.wh.__dir_opaque
d $LOWER_DIR/b1/d4/j

d $LOWER_DIR/b0/d5/k
f $LOWER_DIR/b1/d5/.wh.k
FILES
}



function after_directories_ro {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d2
d $LOWER_DIR/b0/d3
d $LOWER_DIR/b0/d5
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d2
d $LOWER_DIR/b1/d3
d $LOWER_DIR/b1/d4
d $LOWER_DIR/b1/d5
FILES
}



function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a

f $LOWER_DIR/b0/.wh.b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/.wh.d
d $LOWER_DIR/b1/d

f $LOWER_DIR/b0/.wh.e
d $LOWER_DIR/b1/e

d $LOWER_DIR/b0/d1/f
d $LOWER_DIR/b1/d1/g

d $LOWER_DIR/b1/d2/h

d $LOWER_DIR/b0/d3/i

f $LOWER_DIR/b0/.wh.d4
d $LOWER_DIR/b1/d4/j

d $LOWER_DIR/b0/d5/k
f $LOWER_DIR/b1/d5/.wh.k
FILES
}


function afterfiles_mkdir_back_ro {
cat <<FILES
f $LOWER_DIR/b0/a
d $LOWER_DIR/b1/a

d $LOWER_DIR/b0/b
f $LOWER_DIR/b0/b/.wh.__dir_opaque
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

d $LOWER_DIR/b0/d
f $LOWER_DIR/b0/d/.wh.__dir_opaque
d $LOWER_DIR/b1/d

f $LOWER_DIR/b0/.wh.e
d $LOWER_DIR/b1/e

d $LOWER_DIR/b0/d1/f
d $LOWER_DIR/b1/d1/g

d $LOWER_DIR/b1/d2/h

d $LOWER_DIR/b0/d3/i

d $LOWER_DIR/b0/d4
f $LOWER_DIR/b0/d4/.wh.__dir_opaque
d $LOWER_DIR/b1/d4/j

d $LOWER_DIR/b0/d5/k
f $LOWER_DIR/b1/d5/.wh.k
FILES
}






##### simple tests
( directories ; beforefiles) | create_hierarchy

mount_union "delete=all" $LOWER_DIR/b0 $LOWER_DIR/b1

shouldfail rmdir $MOUNTPOINT/a
rmdir $MOUNTPOINT/b
shouldfail rmdir $MOUNTPOINT/c
rmdir $MOUNTPOINT/d
shouldfail rmdir $MOUNTPOINT/e
shouldfail rmdir $MOUNTPOINT/d1
shouldfail rmdir $MOUNTPOINT/d2
shouldfail rmdir $MOUNTPOINT/d3
rmdir $MOUNTPOINT/d4
shouldfail rmdir $MOUNTPOINT/d5

# making sure things are gone
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d4  '-'

unmount_union
( after_directories_rw ; afterfiles_rw )  | check_hierarchy $LOWER_DIR





##### simple tests  and then mkdir back
( directories ; beforefiles) | create_hierarchy

mount_union "debug=0,delete=all" $LOWER_DIR/b0 $LOWER_DIR/b1

shouldfail rmdir $MOUNTPOINT/a
rmdir $MOUNTPOINT/b
shouldfail rmdir $MOUNTPOINT/c
rmdir $MOUNTPOINT/d
shouldfail rmdir $MOUNTPOINT/e
shouldfail rmdir $MOUNTPOINT/d1
shouldfail rmdir $MOUNTPOINT/d2
shouldfail rmdir $MOUNTPOINT/d3
rmdir $MOUNTPOINT/d4
shouldfail rmdir $MOUNTPOINT/d5

# making sure things are gone
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d4  '-'


mkdir $MOUNTPOINT/d
mkdir $MOUNTPOINT/d4

unmount_union
( after_directories_rw ; afterfiles_mkdir_back_rw )  | check_hierarchy $LOWER_DIR

echo -n "[rw] "

##### simple tests with b1 with RO branch
( directories ; beforefiles) | create_hierarchy

mount_union "debug=0,delete=all" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

shouldfail rmdir $MOUNTPOINT/a
rmdir $MOUNTPOINT/b
shouldfail rmdir $MOUNTPOINT/c
rmdir $MOUNTPOINT/d
shouldfail rmdir $MOUNTPOINT/e
shouldfail rmdir $MOUNTPOINT/d1
shouldfail rmdir $MOUNTPOINT/d2
shouldfail rmdir $MOUNTPOINT/d3
rmdir $MOUNTPOINT/d4
shouldfail rmdir $MOUNTPOINT/d5

# making sure things are gone
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d4  '-'

unmount_union
( after_directories_ro ; afterfiles_ro )  | check_hierarchy $LOWER_DIR

echo -n "[ro] "


##### simple tests  and then mkdir back
( directories ; beforefiles) | create_hierarchy

mount_union "debug=0,delete=all" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

shouldfail rmdir $MOUNTPOINT/a
rmdir $MOUNTPOINT/b
shouldfail rmdir $MOUNTPOINT/c
rmdir $MOUNTPOINT/d
shouldfail rmdir $MOUNTPOINT/e
shouldfail rmdir $MOUNTPOINT/d1
shouldfail rmdir $MOUNTPOINT/d2
shouldfail rmdir $MOUNTPOINT/d3
rmdir $MOUNTPOINT/d4
shouldfail rmdir $MOUNTPOINT/d5

# making sure things are gone
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d4  '-'


mkdir $MOUNTPOINT/b
mkdir $MOUNTPOINT/d
mkdir $MOUNTPOINT/d4

unmount_union
( after_directories_ro ; afterfiles_mkdir_back_ro )  | check_hierarchy $LOWER_DIR

echo -n "[ro] "


complete_test
