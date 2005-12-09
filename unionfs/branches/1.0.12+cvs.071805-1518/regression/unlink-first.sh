#!/bin/sh

# TEST: Branches: b0,b1=ro and b0,b1 
#       unlink_first(F) where F is a file in b0,b1
# TEST:
# TEST:

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

f /n/lower/b1/c

f /n/lower/b1/d

f /n/lower/b0/d1/d2/e
f /n/lower/b1/d1/d2/e
FILES
}

function afterfiles {
cat <<FILES
f /n/lower/b1/a

f /n/lower/b1/d1/d2/e
FILES
}




( files ; beforefiles) | create_hierarchy

mount_union "delete=first" /n/lower/b0 /n/lower/b1 

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e

# XXX: You need to have check to see that the files that don't exist don't and the files that do exist do!

unmount_union
( files ; afterfiles )  | check_hierarchy /n/lower



( files ; beforefiles) | create_hierarchy

mount_union "delete=first" /n/lower/b0 /n/lower/b1

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e

# XXX: You need to have check to see that the files that don't exist don't and the files that do exist do!

unmount_union

( files ; afterfiles)  | check_hierarchy /n/lower

echo "OK"
exit 0
