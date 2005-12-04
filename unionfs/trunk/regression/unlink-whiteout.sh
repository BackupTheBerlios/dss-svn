#!/bin/sh

# TEST: Branches: b0,b1=ro and b0,b1 
#       unlink_whiteout(F) where F is a file in b0 or b1 or both
#       F is in b0, b1
#       F is in b0
#       F is in b1
#
# TEST: after unlinking create same files again
#       1. create them before unmount
#       2. create them after unmount and then mount


source scaffold

function files {
cat <<FILES
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b0/d1
d /n/lower/b0/d1/d2
d /n/lower/b1/d1
d /n/lower/b1/d1/d2
FILES
}


function beforefiles {
cat <<FILES
f /n/lower/b0/a
f /n/lower/b1/a

f /n/lower/b1/b

f /n/lower/b0/c
f /n/lower/b1/c

f /n/lower/b0/d

f /n/lower/b1/d1/d2/e
FILES
}

function afterfiles_ro {
cat <<FILES
f /n/lower/b0/.wh.a
f /n/lower/b1/a

f /n/lower/b0/.wh.b
f /n/lower/b1/b

f /n/lower/b0/.wh.c
f /n/lower/b1/c

f /n/lower/b0/.wh.d

f /n/lower/b0/d1/d2/.wh.e
f /n/lower/b1/d1/d2/e
FILES
}



function afterfiles_rw {
cat <<FILES
f /n/lower/b0/.wh.a
f /n/lower/b1/a

f /n/lower/b1/.wh.b

f /n/lower/b0/.wh.c
f /n/lower/b1/c

f /n/lower/b0/.wh.d

f /n/lower/b1/d1/d2/.wh.e
FILES
}




function afterfiles_createback_ro {
cat <<FILES
f /n/lower/b0/a
f /n/lower/b1/a

f /n/lower/b0/b
f /n/lower/b1/b

f /n/lower/b0/c
f /n/lower/b1/c

f /n/lower/b0/d

f /n/lower/b0/d1/d2/e
f /n/lower/b1/d1/d2/e
FILES
}



function afterfiles_createback_rw {
cat <<FILES
f /n/lower/b0/a
f /n/lower/b1/a

f /n/lower/b1/b

f /n/lower/b0/c
f /n/lower/b1/c

f /n/lower/b0/d

f /n/lower/b1/d1/d2/e
FILES
}




##### simple test
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1=ro

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e

# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_ro )  | check_hierarchy /n/lower







##### now unlink files and then create them before unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1=ro 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
# making sure things are created back
checkfile_after_create $MOUNTPOINT/a
checkfile_after_create $MOUNTPOINT/b
checkfile_after_create $MOUNTPOINT/c
checkfile_after_create $MOUNTPOINT/d
checkfile_after_create $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_createback_ro )  | check_hierarchy /n/lower






##### now unlink files and then create them after unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1=ro 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_ro )  | check_hierarchy /n/lower

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1=ro 

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
# making sure things are created back
checkfile_after_create $MOUNTPOINT/a
checkfile_after_create $MOUNTPOINT/b
checkfile_after_create $MOUNTPOINT/c
checkfile_after_create $MOUNTPOINT/d
checkfile_after_create $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_createback_ro)  | check_hierarchy /n/lower








##### simple test with rw branches
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

unmount_union

( files ; afterfiles_rw)  | check_hierarchy /n/lower







##### now unlink files and then create them before unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
# making sure things are created back
checkfile_after_create $MOUNTPOINT/a
checkfile_after_create $MOUNTPOINT/b
checkfile_after_create $MOUNTPOINT/c
checkfile_after_create $MOUNTPOINT/d
checkfile_after_create $MOUNTPOINT/d1/d2/e


unmount_union
( files ; afterfiles_createback_rw )  | check_hierarchy /n/lower







##### now unlink files and then create them after unmount
( files ; beforefiles) | create_hierarchy

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e
# making sure things are gone
checkfile_after_remove $MOUNTPOINT/a
checkfile_after_remove $MOUNTPOINT/b
checkfile_after_remove $MOUNTPOINT/c
checkfile_after_remove $MOUNTPOINT/d
checkfile_after_remove $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_rw )  | check_hierarchy /n/lower

mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1 

# create back files
/bin/touch $MOUNTPOINT/a
/bin/touch $MOUNTPOINT/b
/bin/touch $MOUNTPOINT/c
/bin/touch $MOUNTPOINT/d
/bin/touch $MOUNTPOINT/d1/d2/e
# making sure things are created back
checkfile_after_create $MOUNTPOINT/a
checkfile_after_create $MOUNTPOINT/b
checkfile_after_create $MOUNTPOINT/c
checkfile_after_create $MOUNTPOINT/d
checkfile_after_create  $MOUNTPOINT/d1/d2/e

unmount_union
( files ; afterfiles_createback_rw)  | check_hierarchy /n/lower

echo "OK"
exit 0
