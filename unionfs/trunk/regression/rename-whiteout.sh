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
d /n/lower
d /n/lower/b0
d /n/lower/b1
d /n/lower/b2
FILES
}

function beforefiles {
cat <<FILES
s /n/lower/b2/rA.S

s /n/lower/b1/rB.S
s /n/lower/b2/rB.S

s /n/lower/b0/rC.S
s /n/lower/b1/rC.S

s /n/lower/b0/rD.S
s /n/lower/b1/rD.S
f /n/lower/b2/rD.D

s /n/lower/b1/rE.S
s /n/lower/b2/rE.S
f /n/lower/b2/rE.D

s /n/lower/b2/rF.S
f /n/lower/b1/rF.D
f /n/lower/b2/rF.D

s /n/lower/b2/rG.S
f /n/lower/b0/rG.D
f /n/lower/b2/rG.D

s /n/lower/b0/rH.S
s /n/lower/b1/rH.S
s /n/lower/b2/rH.S
f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D

fs /n/lower/b0/rI.S
fsi /n/lower/b1/rI.S
fs /n/lower/b2/rI.S
f /n/lower/b0/rI.D
f /n/lower/b1/rI.D
f /n/lower/b2/rI.D
FILES
}

function afterfiles_rw {
cat <<FILES
f /n/lower/b2/rA.D

f /n/lower/b1/rB.D
f /n/lower/b1/.wh.rB.S
f /n/lower/b2/rB.S

f /n/lower/b0/.wh.rC.S
f /n/lower/b0/rC.D
f /n/lower/b1/rC.S

f /n/lower/b0/.wh.rD.S
f /n/lower/b0/rD.D
f /n/lower/b1/rD.S
f /n/lower/b2/rD.D

f /n/lower/b1/rE.D
f /n/lower/b1/.wh.rE.S
f /n/lower/b2/rE.S
f /n/lower/b2/rE.D

f /n/lower/b2/rF.D

f /n/lower/b2/rG.D

f /n/lower/b0/.wh.rH.S
f /n/lower/b1/rH.S
f /n/lower/b2/rH.S
f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D

f /n/lower/b0/.wh.rI.S
f /n/lower/b1/rI.S
f /n/lower/b2/rI.S
f /n/lower/b0/rI.D
f /n/lower/b1/rI.D
f /n/lower/b2/rI.D
FILES
}

function afterfiles_ro {
cat <<FILES
f /n/lower/b0/.wh.rA.S
f /n/lower/b0/rA.D
f /n/lower/b2/rA.S

f /n/lower/b0/.wh.rB.S
f /n/lower/b0/rB.D
f /n/lower/b1/rB.S
f /n/lower/b2/rB.S

f /n/lower/b0/rC.D
f /n/lower/b0/.wh.rC.S
f /n/lower/b1/rC.S

f /n/lower/b0/rD.D
f /n/lower/b0/.wh.rD.S
f /n/lower/b1/rD.S
f /n/lower/b2/rD.D

f /n/lower/b0/rE.D
f /n/lower/b0/.wh.rE.S
f /n/lower/b1/rE.S
f /n/lower/b2/rE.S
f /n/lower/b2/rE.D

f /n/lower/b0/.wh.rF.S
f /n/lower/b0/rF.D
f /n/lower/b2/rF.S
f /n/lower/b1/rF.D
f /n/lower/b2/rF.D

f /n/lower/b0/.wh.rG.S
f /n/lower/b2/rG.S
f /n/lower/b0/rG.D
f /n/lower/b2/rG.D

f /n/lower/b0/.wh.rH.S
f /n/lower/b1/rH.S
f /n/lower/b2/rH.S
f /n/lower/b0/rH.D
f /n/lower/b1/rH.D
f /n/lower/b2/rH.D

f /n/lower/b0/.wh.rI.S
f /n/lower/b1/rI.S
f /n/lower/b2/rI.S
f /n/lower/b0/rI.D
f /n/lower/b1/rI.D
f /n/lower/b2/rI.D
FILES
}

function beforefiles_fail {
cat <<FILES
fi /n/lower/b2/rJ.S
FILES
}

 
function afterfiles_fail {
cat <<FILES
f /n/lower/b2/rJ.S
FILES
}


for STATE in rw ro
do
	( files ; beforefiles) | create_hierarchy
	mount_union "delete=whiteout" /n/lower/b0 /n/lower/b1=$STATE /n/lower/b2=$STATE
	for X in A B C D E F G H I
	do
		mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D"
		checktype "$MOUNTPOINT/r$X.S" '-'
		checktype "$MOUNTPOINT/r$X.D" 'f'
		echo "Source file." | diff "$MOUNTPOINT/r$X.D" -
	done
	unmount_union

	( files ; afterfiles_$STATE )  | check_hierarchy /n/lower
	

	echo -n "[$STATE] "

done

( files ; beforefiles_fail) | create_hierarchy
mount_union "delete=whiteout" /n/lower/b? 
for X in J
do
	shouldfail mv -f "$MOUNTPOINT/r$X.S" "$MOUNTPOINT/r$X.D" 
	checktype "$MOUNTPOINT/r$X.S" 'f'
	checktype "$MOUNTPOINT/r$X.D" '-'
done
unmount_union
( files ; afterfiles_fail )  | check_hierarchy /n/lower


echo "OK"
exit 0
