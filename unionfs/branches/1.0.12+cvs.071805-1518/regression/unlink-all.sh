#!/bin/sh

# TEST: Branches: b0,b1=ro and b0,b1
# TEST: unlink(F) where F is
# TEST:  a file in b1
# TEST:  a file in b0,b1
# TEST:  a file in b0
# TEST:
# TEST: Branches: b0,b1=ro
# TEST: D exists in b1
# TEST: unlink(D/F)
# TEST:
# TEST: Branches: b0,b1,b2
# TEST: unlink(F)
# TEST:  a file in b0,b1,b2 (b1 is immutable)

source scaffold

function files {
cat <<FILES
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b2
d /n/lower/b1/d1
d /n/lower/b1/d1/d2
FILES
}

function beforefiles {
cat <<FILES
f /n/lower/b1/a

f /n/lower/b0/b
f /n/lower/b1/b

f /n/lower/b0/c

f /n/lower/b1/d

f /n/lower/b1/d1/d2/e
FILES
}

function beforefiles_i {
cat <<FILES
f /n/lower/b0/f
i /n/lower/b1/f
f /n/lower/b2/f
FILES
}

function afterfiles_ro {
cat <<FILES
f /n/lower/b0/.wh.a
f /n/lower/b1/a

f /n/lower/b0/.wh.b
f /n/lower/b1/b

f /n/lower/b0/.wh.d
f /n/lower/b1/d

d /n/lower/b0/d1
d /n/lower/b0/d1/d2
f /n/lower/b0/d1/d2/.wh.e
f /n/lower/b1/d1/d2/e
FILES
}
 
function afterfiles_i {
cat <<FILES
f /n/lower/b0/f
f /n/lower/b1/f
FILES
}

( files ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b0 /n/lower/b1=ro

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e

# XXX: Existence checks

unmount_union

( files ; afterfiles_ro )  | check_hierarchy /n/lower

( files ; beforefiles) | create_hierarchy

mount_union "" /n/lower/b[0-1]

/bin/unlink $MOUNTPOINT/a
/bin/unlink $MOUNTPOINT/b
/bin/unlink $MOUNTPOINT/c
/bin/unlink $MOUNTPOINT/d
/bin/unlink $MOUNTPOINT/d1/d2/e

checktype $MOUNTPOINT/a '-'
checktype $MOUNTPOINT/b '-'
checktype $MOUNTPOINT/c '-'
checktype $MOUNTPOINT/d '-'
checktype $MOUNTPOINT/d1/d2/e '-'

unmount_union
( files )  | check_hierarchy /n/lower

# The immutable test
( files ; beforefiles_i) | create_hierarchy
mount_union "" /n/lower/b[0-2]
shouldfail /bin/unlink $MOUNTPOINT/f
checktype $MOUNTPOINT/f 'f'
unmount_union
( files ; afterfiles_i )  | check_hierarchy /n/lower


echo "OK"
exit 0
