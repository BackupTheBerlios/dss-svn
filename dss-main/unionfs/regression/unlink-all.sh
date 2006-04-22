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
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
d $LOWER_DIR/b1/d1
d $LOWER_DIR/b1/d1/d2
FILES
}

function beforefiles {
cat <<FILES
f $LOWER_DIR/b1/a

f $LOWER_DIR/b0/b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/c

f $LOWER_DIR/b1/d

f $LOWER_DIR/b1/d1/d2/e
FILES
}

function beforefiles_i {
cat <<FILES
f $LOWER_DIR/b0/f
i $LOWER_DIR/b1/f
f $LOWER_DIR/b2/f
FILES
}

function beforefiles_319 {
cat <<FILES
f $LOWER_DIR/b1/a
FILES
}

function beforefiles_whcheck {
cat <<FILES
f $LOWER_DIR/b0/a
f $LOWER_DIR/b1/.wh.a
FILES
}


function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/.wh.a
f $LOWER_DIR/b1/a

f $LOWER_DIR/b0/.wh.b
f $LOWER_DIR/b1/b

f $LOWER_DIR/b0/.wh.d
f $LOWER_DIR/b1/d

d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d1/d2
f $LOWER_DIR/b0/d1/d2/.wh.e
f $LOWER_DIR/b1/d1/d2/e
FILES
}

function afterfiles_ro2 {
cat <<FILES
f $LOWER_DIR/b1/a
f $LOWER_DIR/b0/b
f $LOWER_DIR/b1/b
f $LOWER_DIR/b0/c
f $LOWER_DIR/b1/d

d $LOWER_DIR/b0/d1
d $LOWER_DIR/b0/d1/d2
f $LOWER_DIR/b0/d1/d2/.wh.e
f $LOWER_DIR/b1/d1/d2/e
FILES
}

function afterfiles_i {
cat <<FILES
f $LOWER_DIR/b0/f
f $LOWER_DIR/b1/f
FILES
}

function afterfiles_319 {
cat <<FILES
f $LOWER_DIR/b0/.wh.a
f $LOWER_DIR/b1/a
FILES
}

function afterfiles_whcheck {
cat <<FILES
f $LOWER_DIR/b1/.wh.a
FILES
}

function ro2 {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

	/bin/unlink $MOUNTPOINT/d1/d2/e
	checktype $MOUNTPOINT/d1/d2/e '-'

	unmount_union

	( files ; afterfiles_ro2 )  | check_hierarchy $LOWER_DIR
}

function ro {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro

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

	( files ; afterfiles_ro )  | check_hierarchy $LOWER_DIR
}

function rw {
	( files ; beforefiles) | create_hierarchy

	mount_union "" $LOWER_DIR/b[0-1]

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
	( files )  | check_hierarchy $LOWER_DIR
}

function immutable {
	# The immutable test
	( files ; beforefiles_i) | create_hierarchy
	mount_union "" $LOWER_DIR/b[0-2]
	shouldfail /bin/unlink $MOUNTPOINT/f
	checktype $MOUNTPOINT/f 'f'
	unmount_union
	( files ; afterfiles_i )  | check_hierarchy $LOWER_DIR
}

function BUG319 {
	( files ; beforefiles_319) | create_hierarchy
	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro
	checktype $MOUNTPOINT/a 'f'
	rm -f $MOUNTPOINT/a
	checktype $MOUNTPOINT/a '-'
	touch $MOUNTPOINT/a
	checktype $MOUNTPOINT/a 'f'
	rm -f $MOUNTPOINT/a
	checktype $MOUNTPOINT/a '-'
	unmount_union
	( files ; afterfiles_319 )  | check_hierarchy $LOWER_DIR
}

function whcheck {
	( files ; beforefiles_whcheck) | create_hierarchy
	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1
	checktype $MOUNTPOINT/a 'f'
	rm -f $MOUNTPOINT/a
	checktype $MOUNTPOINT/a '-'
	unmount_union
	( files ; afterfiles_whcheck )  | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="rw ro BUG319 whcheck"
	if havechattr $LOWER_DIR ; then
		FXNS="$FXNS immutable"
	fi
fi

for x in $FXNS
do
	$x
	echo -n "[$x] "
done

complete_test
