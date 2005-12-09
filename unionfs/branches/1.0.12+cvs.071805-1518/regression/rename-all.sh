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
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b2
FILES
}

function beforefiles {
cat <<FILES
fs /n/lower/b2/rA.S

fs /n/lower/b1/rB.S
fs /n/lower/b2/rB.S

fs /n/lower/b0/rC.S
fs /n/lower/b1/rC.S

fs /n/lower/b0/rD.S
fs /n/lower/b1/rD.S
f /n/lower/b2/rD.D

fs /n/lower/b1/rE.S
fs /n/lower/b2/rE.S
f /n/lower/b2/rE.D

fs /n/lower/b2/rF.S
f /n/lower/b1/rF.D
f /n/lower/b2/rF.D

fs /n/lower/b2/rG.S
f /n/lower/b0/rG.D
f /n/lower/b2/rG.D

fs /n/lower/b0/rH.S
fs /n/lower/b1/rH.S
fs /n/lower/b2/rH.S
f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D
FILES
}

function afterfiles_rw {
cat <<FILES
f /n/lower/b2/rA.D

f /n/lower/b1/rB.D
f /n/lower/b2/rB.D

f /n/lower/b0/rC.D
f /n/lower/b1/rC.D

f /n/lower/b0/rD.D
f /n/lower/b1/rD.D
f /n/lower/b2/rD.D

f /n/lower/b1/rE.D
f /n/lower/b2/rE.D

f /n/lower/b2/rF.D

f /n/lower/b2/rG.D

f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D
FILES
}

function afterfiles_ro {
cat <<FILES
f /n/lower/b0/rA.D
f /n/lower/b0/.wh.rA.S
f /n/lower/b2/rA.S

f /n/lower/b0/rB.D
f /n/lower/b0/.wh.rB.S
f /n/lower/b1/rB.S
f /n/lower/b2/rB.S

f /n/lower/b0/.wh.rC.S
f /n/lower/b1/rC.S
f /n/lower/b0/rC.D

f /n/lower/b0/rD.D
f /n/lower/b0/.wh.rD.S
f /n/lower/b1/rD.S
f /n/lower/b2/rD.D

f /n/lower/b0/rE.D
f /n/lower/b0/.wh.rE.S
f /n/lower/b1/rE.S
f /n/lower/b2/rE.S
f /n/lower/b2/rE.D

f /n/lower/b0/rF.D
f /n/lower/b0/.wh.rF.S
f /n/lower/b2/rF.S
f /n/lower/b1/rF.D
f /n/lower/b2/rF.D

f /n/lower/b0/rG.D
f /n/lower/b0/.wh.rG.S
f /n/lower/b2/rG.S
f /n/lower/b2/rG.D

f /n/lower/b0/.wh.rH.S
f /n/lower/b1/rH.S
f /n/lower/b2/rH.S
f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D
FILES
}

function beforefiles_i {
cat <<FILES
f /n/lower/b0/rI.S
fi /n/lower/b1/rI.S
f /n/lower/b2/rI.S
f /n/lower/b0/rI.D
f /n/lower/b1/rI.D
f /n/lower/b2/rI.D
FILES
}

 
function afterfiles_i {
cat <<FILES
f /n/lower/b0/rI.S
f /n/lower/b1/rI.S
f /n/lower/b2/rI.S
f /n/lower/b0/rI.D
f /n/lower/b1/rI.D
FILES
}


for STATE in rw ro
do
	( files ; beforefiles) | create_hierarchy
	mount_union "" /n/lower/b0 /n/lower/b1=$STATE /n/lower/b2=$STATE
	for X in A B C D E F G H
	do
		mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
		checktype "$MOUNTPOINT/r$X.S" '-'
		checktype "$MOUNTPOINT/r$X.D" 'f'
		echo "Source file." | diff "$MOUNTPOINT/r$X.D" -
	done
	unmount_union

	( files ; afterfiles_$STATE )  | check_hierarchy /n/lower

done

( files ; beforefiles_i) | create_hierarchy
mount_union "" /n/lower/b?
X=I
shouldfail mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
checktype "$MOUNTPOINT/r$X.S" 'f'
checktype "$MOUNTPOINT/r$X.D" 'f'
unmount_union
( files ; afterfiles_i )  | check_hierarchy /n/lower


echo "OK"
exit 0
