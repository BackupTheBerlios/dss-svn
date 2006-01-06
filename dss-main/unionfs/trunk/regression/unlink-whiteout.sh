#!/bin/sh

# TEST: Branches: b0,b1=ro and b0,b1
#       unlink_whiteout(F) where F is a file in b0 or b1 or both
#       F is in b0, b1
#       F is in b0
#       F is in b1
#
# TEST: Branches: b0,b1=ro, and b0,b1
#	g is a symlink in b1
#
# TEST: after unlinking create same files again
#       1. create them before unmount
#       2. create them after unmount and then mount


source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d1/d2
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
FILES
}


function beforefiles {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/d

f $LOWER_DIR/b1/d1/d2/e

l $LOWER_DIR/b1/g
FILES
}

function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/.wh.a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b0/.wh.b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/.wh.c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/.wh.d

f $LOWER_DIR/b0/d1/d2/.wh.e
f $LOWER_DIR/b1/d1/d2/e

f $LOWER_DIR/b0/.wh.g
l $LOWER_DIR/b1/g
FILES
}



function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b0/.wh.a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b1/.wh.b

f $LOWER_DIR/b0/.wh.c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/.wh.d

f $LOWER_DIR/b1/d1/d2/.wh.e

f $LOWER_DIR/b1/.wh.g
FILES
}




function afterfiles_createback_ro {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b0/b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/d

f $LOWER_DIR/b0/d1/d2/e
f $LOWER_DIR/b1/d1/d2/e

f $LOWER_DIR/b0/g
l $LOWER_DIR/b1/g
FILES
}



function afterfiles_createback_rw {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b0/b
f $LOWER_DIR/b1/.wh.b

f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/c

f $LOWER_DIR/b0/d

f $LOWER_DIR/b0/d1/d2/e
f $LOWER_DIR/b1/d1/d2/.wh.e

f $LOWER_DIR/b0/g
f $LOWER_DIR/b1/.wh.g
FILES
}




##### simple test
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
/bin/unlink $MOUNTPOINT/g

# making sure things are gone
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

unmount_union
( files ; afterfiles_ro )  | check_hierarchy $LOWER_DIR

echo -n "[ro] "



##### now unlink files and then create them before unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
/bin/unlink $MOUNTPOINT/g
# making sure things are gone
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
/bin/touch $MOUNTPOINT/g
# making sure things are created back
checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'f'
checktype $MOUNTPOINT/c 'f'
checktype $MOUNTPOINT/d 'f'
checktype $MOUNTPOINT/d1/d2/e 'f'
checktype $MOUNTPOINT/g 'f'

unmount_union
( files ; afterfiles_createback_ro )  | check_hierarchy $LOWER_DIR


echo -n "[ro createback] "




##### now unlink files and then create them after unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
/bin/unlink $MOUNTPOINT/g
# making sure things are gone
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

unmount_union
( files ; afterfiles_ro )  | check_hierarchy $LOWER_DIR
echo -n "[ro] "

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
/bin/touch $MOUNTPOINT/g
# making sure things are created back
checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'f'
checktype $MOUNTPOINT/c 'f'
checktype $MOUNTPOINT/d 'f'
checktype $MOUNTPOINT/d1/d2/e 'f'
checktype $MOUNTPOINT/g 'f'

unmount_union
( files ; afterfiles_createback_ro)  | check_hierarchy $LOWER_DIR

echo -n "[ro createback 2] "

##### simple test with rw branches
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
/bin/unlink $MOUNTPOINT/g
# making sure things are gone
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

unmount_union

( files ; afterfiles_rw)  | check_hierarchy $LOWER_DIR


echo -n "[rw] "

##### now unlink files and then create them before unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
/bin/unlink $MOUNTPOINT/g
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
/bin/touch $MOUNTPOINT/g
# making sure things are created back
checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'f'
checktype $MOUNTPOINT/c 'f'
checktype $MOUNTPOINT/d 'f'
checktype $MOUNTPOINT/d1/d2/e 'f'
checktype $MOUNTPOINT/g 'f'


unmount_union
( files ; afterfiles_createback_rw )  | check_hierarchy $LOWER_DIR

echo -n "[rw createback] "


##### now unlink files and then create them after unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
/bin/unlink $MOUNTPOINT/g
# making sure things are gone
checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'
checktype $MOUNTPOINT/g '-'

unmount_union
( files ; afterfiles_rw )  | check_hierarchy $LOWER_DIR

mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
/bin/touch $MOUNTPOINT/g
# making sure things are created back
checktype $MOUNTPOINT/a 'f'
checktype $MOUNTPOINT/b 'f'
checktype $MOUNTPOINT/c 'f'
checktype $MOUNTPOINT/d 'f'
checktype  $MOUNTPOINT/d1/d2/e 'f'
checktype $MOUNTPOINT/g 'f'

unmount_union
( files ; afterfiles_createback_rw)  | check_hierarchy $LOWER_DIR
echo -n "[rw createback 2] "

complete_test
