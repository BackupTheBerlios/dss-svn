#!/bin/sh

# TEST: Branches: b0,b1,b2 and b0,b1=ro,b2=ro
# TEST: rename(S, D) where S and D are in the following configurations
# TEST:  +--------+----------+
# TEST:  |b0|b1|b2| filename |
# TEST:  |--|--|--|----------|
# TEST:  |  |  | S| rA       |
# TEST:  |  |  |  |          |
# TEST:  |--|--|--|----------|
# TEST:  |  | S| S| rB       |
# TEST:  |  |  |  |          |
# TEST:  |--|--|--|----------|
# TEST:  | S| S|  | rC       |
# TEST:  |  |  |  |          |
# TEST:  |--|--|--|----------|
# TEST:  | S| S|  | rD       |
# TEST:  |  |  | D|          |
# TEST:  |--|--|--|----------|
# TEST:  |  | S| S| rE       |
# TEST:  |  |  | D|          |
# TEST:  |--|--|--|----------|
# TEST:  |  |  | S| rF       |
# TEST:  |  | D| D|          |
# TEST:  |--|--|--|----------|
# TEST:  |  |  | S| rG       |
# TEST:  | D|  | D|          |
# TEST:  |--|--|--|----------|
# TEST:  | S| S| S| rH       |
# TEST:  | D| D| D|          |
# TEST:  +--------+----------+
# TEST:
# TEST:  With all branches writeable, the following test with the source
# TEST:  file in branch 1 immutable (this tests revert).
# TEST:  +--------+----------+
# TEST:  |b0|b1|b2| filename |
# TEST:  |--|--|--|----------|
# TEST:  | S| S| S| rI       |
# TEST:  | D| D| D|          |
# TEST:  +--------+----------+

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
FILES
}

function beforefiles {
cat <<FILES
fs $LOWER_DIR/b2/rA.S

fs $LOWER_DIR/b1/rB.S
fs $LOWER_DIR/b2/rB.S

fs $LOWER_DIR/b0/rC.S
fs $LOWER_DIR/b1/rC.S

fs $LOWER_DIR/b0/rD.S
fs $LOWER_DIR/b1/rD.S
f $LOWER_DIR/b2/rD.D

fs $LOWER_DIR/b1/rE.S
fs $LOWER_DIR/b2/rE.S
f $LOWER_DIR/b2/rE.D

fs $LOWER_DIR/b2/rF.S
f $LOWER_DIR/b1/rF.D
f $LOWER_DIR/b2/rF.D

fs $LOWER_DIR/b2/rG.S
f $LOWER_DIR/b0/rG.D
f $LOWER_DIR/b2/rG.D

fs $LOWER_DIR/b0/rH.S
fs $LOWER_DIR/b1/rH.S
fs $LOWER_DIR/b2/rH.S
f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D
FILES
}

function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b2/rA.D

f $LOWER_DIR/b1/rB.D
f $LOWER_DIR/b2/rB.D

f $LOWER_DIR/b0/rC.D
f $LOWER_DIR/b1/rC.D

f $LOWER_DIR/b0/rD.D
f $LOWER_DIR/b1/rD.D
f $LOWER_DIR/b2/rD.D

f $LOWER_DIR/b1/rE.D
f $LOWER_DIR/b2/rE.D

f $LOWER_DIR/b2/rF.D

f $LOWER_DIR/b2/rG.D

f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D
FILES
}

function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/rA.D
f $LOWER_DIR/b0/.wh.rA.S
f $LOWER_DIR/b2/rA.S

f $LOWER_DIR/b0/rB.D
f $LOWER_DIR/b0/.wh.rB.S
f $LOWER_DIR/b1/rB.S
f $LOWER_DIR/b2/rB.S

f $LOWER_DIR/b0/.wh.rC.S
f $LOWER_DIR/b1/rC.S
f $LOWER_DIR/b0/rC.D

f $LOWER_DIR/b0/rD.D
f $LOWER_DIR/b0/.wh.rD.S
f $LOWER_DIR/b1/rD.S
f $LOWER_DIR/b2/rD.D

f $LOWER_DIR/b0/rE.D
f $LOWER_DIR/b0/.wh.rE.S
f $LOWER_DIR/b1/rE.S
f $LOWER_DIR/b2/rE.S
f $LOWER_DIR/b2/rE.D

f $LOWER_DIR/b0/rF.D
f $LOWER_DIR/b0/.wh.rF.S
f $LOWER_DIR/b2/rF.S
f $LOWER_DIR/b1/rF.D
f $LOWER_DIR/b2/rF.D

f $LOWER_DIR/b0/rG.D
f $LOWER_DIR/b0/.wh.rG.S
f $LOWER_DIR/b2/rG.S
f $LOWER_DIR/b2/rG.D

f $LOWER_DIR/b0/.wh.rH.S
f $LOWER_DIR/b1/rH.S
f $LOWER_DIR/b2/rH.S
f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D
FILES
}

function beforefiles_i {
cat <<FILES
f $LOWER_DIR/b0/rI.S
fi $LOWER_DIR/b1/rI.S
f $LOWER_DIR/b2/rI.S
f $LOWER_DIR/b0/rI.D
f $LOWER_DIR/b1/rI.D
f $LOWER_DIR/b2/rI.D
FILES
}


function afterfiles_i {
cat <<FILES
f $LOWER_DIR/b0/rI.S
f $LOWER_DIR/b1/rI.S
f $LOWER_DIR/b2/rI.S
f $LOWER_DIR/b0/rI.D
f $LOWER_DIR/b1/rI.D
FILES
}

function beforefiles_388 {
cat <<FILES
d $LOWER_DIR/b1/d
FILES
}


function afterfiles_388 {
cat <<FILES
f $LOWER_DIR/b0/.wh.d
d $LOWER_DIR/b1/d
FILES
}

function rw {
	rwro rw
}
function ro {
	rwro ro
}

function rwro {
	STATE=$1
	( files ; beforefiles) | create_hierarchy
	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=$STATE $LOWER_DIR/b2=$STATE
	for X in A B C D E F G H
	do
		mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
		checktype "$MOUNTPOINT/r$X.S" '-'
		checktype "$MOUNTPOINT/r$X.D" 'f'
		echo "Source file." | diff "$MOUNTPOINT/r$X.D" -
	done
	unmount_union

	( files ; afterfiles_$STATE )  | check_hierarchy $LOWER_DIR
}

function immutable {
	( files ; beforefiles_i) | create_hierarchy
	mount_union "" $LOWER_DIR/b?
	X=I
	shouldfail mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
	checktype "$MOUNTPOINT/r$X.S" 'f'
	checktype "$MOUNTPOINT/r$X.D" 'f'
	unmount_union
	( files ; afterfiles_i )  | check_hierarchy $LOWER_DIR
}

function BUG388 {
	( files ; beforefiles_388) | create_hierarchy
	mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro
	mv $MOUNTPOINT/d $MOUNTPOINT/d.new
	mv $MOUNTPOINT/d.new $MOUNTPOINT/d
	rm -rf $MOUNTPOINT/d
	unmount_union
	( files ; afterfiles_388 )  | check_hierarchy $LOWER_DIR
}

if [ -z "$FXNS" ] ; then
	FXNS="rw ro BUG388"
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
