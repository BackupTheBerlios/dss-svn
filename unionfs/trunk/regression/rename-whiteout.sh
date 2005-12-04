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
# TEST:  | S|iS| S| rI       |
# TEST:  | D| D| D|          |
# TEST:  +--------+----------+
# TEST:  |  |  |iS| rJ       |
# TEST:  |  |  |  |          |
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
s $LOWER_DIR/b2/rA.S

s $LOWER_DIR/b1/rB.S
s $LOWER_DIR/b2/rB.S

s $LOWER_DIR/b0/rC.S
s $LOWER_DIR/b1/rC.S

s $LOWER_DIR/b0/rD.S
s $LOWER_DIR/b1/rD.S
f $LOWER_DIR/b2/rD.D

s $LOWER_DIR/b1/rE.S
s $LOWER_DIR/b2/rE.S
f $LOWER_DIR/b2/rE.D

s $LOWER_DIR/b2/rF.S
f $LOWER_DIR/b1/rF.D
f $LOWER_DIR/b2/rF.D

s $LOWER_DIR/b2/rG.S
f $LOWER_DIR/b0/rG.D
f $LOWER_DIR/b2/rG.D

s $LOWER_DIR/b0/rH.S
s $LOWER_DIR/b1/rH.S
s $LOWER_DIR/b2/rH.S
f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D

fs $LOWER_DIR/b0/rI.S
fsi $LOWER_DIR/b1/rI.S
fs $LOWER_DIR/b2/rI.S
f $LOWER_DIR/b0/rI.D
f $LOWER_DIR/b1/rI.D
f $LOWER_DIR/b2/rI.D
FILES
}

function afterfiles_rw {
cat <<FILES
f $LOWER_DIR/b2/rA.D

f $LOWER_DIR/b1/rB.D
f $LOWER_DIR/b1/.wh.rB.S
f $LOWER_DIR/b2/rB.S

f $LOWER_DIR/b0/.wh.rC.S
f $LOWER_DIR/b0/rC.D
f $LOWER_DIR/b1/rC.S

f $LOWER_DIR/b0/.wh.rD.S
f $LOWER_DIR/b0/rD.D
f $LOWER_DIR/b1/rD.S
f $LOWER_DIR/b2/rD.D

f $LOWER_DIR/b1/rE.D
f $LOWER_DIR/b1/.wh.rE.S
f $LOWER_DIR/b2/rE.S
f $LOWER_DIR/b2/rE.D

f $LOWER_DIR/b2/rF.D

f $LOWER_DIR/b2/rG.D

f $LOWER_DIR/b0/.wh.rH.S
f $LOWER_DIR/b1/rH.S
f $LOWER_DIR/b2/rH.S
f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D

f $LOWER_DIR/b0/.wh.rI.S
f $LOWER_DIR/b1/rI.S
f $LOWER_DIR/b2/rI.S
f $LOWER_DIR/b0/rI.D
f $LOWER_DIR/b1/rI.D
f $LOWER_DIR/b2/rI.D
FILES
}

function afterfiles_ro {
cat <<FILES
f $LOWER_DIR/b0/.wh.rA.S
f $LOWER_DIR/b0/rA.D
f $LOWER_DIR/b2/rA.S

f $LOWER_DIR/b0/.wh.rB.S
f $LOWER_DIR/b0/rB.D
f $LOWER_DIR/b1/rB.S
f $LOWER_DIR/b2/rB.S

f $LOWER_DIR/b0/rC.D
f $LOWER_DIR/b0/.wh.rC.S
f $LOWER_DIR/b1/rC.S

f $LOWER_DIR/b0/rD.D
f $LOWER_DIR/b0/.wh.rD.S
f $LOWER_DIR/b1/rD.S
f $LOWER_DIR/b2/rD.D

f $LOWER_DIR/b0/rE.D
f $LOWER_DIR/b0/.wh.rE.S
f $LOWER_DIR/b1/rE.S
f $LOWER_DIR/b2/rE.S
f $LOWER_DIR/b2/rE.D

f $LOWER_DIR/b0/.wh.rF.S
f $LOWER_DIR/b0/rF.D
f $LOWER_DIR/b2/rF.S
f $LOWER_DIR/b1/rF.D
f $LOWER_DIR/b2/rF.D

f $LOWER_DIR/b0/.wh.rG.S
f $LOWER_DIR/b2/rG.S
f $LOWER_DIR/b0/rG.D
f $LOWER_DIR/b2/rG.D

f $LOWER_DIR/b0/.wh.rH.S
f $LOWER_DIR/b1/rH.S
f $LOWER_DIR/b2/rH.S
f $LOWER_DIR/b0/rH.D
f $LOWER_DIR/b1/rH.D
f $LOWER_DIR/b2/rH.D

f $LOWER_DIR/b0/.wh.rI.S
f $LOWER_DIR/b1/rI.S
f $LOWER_DIR/b2/rI.S
f $LOWER_DIR/b0/rI.D
f $LOWER_DIR/b1/rI.D
f $LOWER_DIR/b2/rI.D
FILES
}

function beforefiles_fail {
cat <<FILES
fi $LOWER_DIR/b2/rJ.S
FILES
}


function afterfiles_fail {
cat <<FILES
f $LOWER_DIR/b2/rJ.S
FILES
}


for STATE in rw ro
do
	( files ; beforefiles) | create_hierarchy
	mount_union "delete=whiteout" $LOWER_DIR/b0 $LOWER_DIR/b1=$STATE $LOWER_DIR/b2=$STATE
	for X in A B C D E F G H I
	do
		mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
		checktype "$MOUNTPOINT/r$X.S" '-'
		checktype "$MOUNTPOINT/r$X.D" 'f'
		echo "Source file." | diff "$MOUNTPOINT/r$X.D" -
	done
	unmount_union

	( files ; afterfiles_$STATE )  | check_hierarchy $LOWER_DIR


	echo -n "[$STATE] "

done

if havechattr $LOWER_DIR ; then
	( files ; beforefiles_fail) | create_hierarchy
	mount_union "delete=whiteout" $LOWER_DIR/b?
	for X in J
	do
		shouldfail mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
		checktype "$MOUNTPOINT/r$X.S" 'f'
		checktype "$MOUNTPOINT/r$X.D" '-'
	done
	unmount_union
	( files ; afterfiles_fail )  | check_hierarchy $LOWER_DIR
fi

complete_test
