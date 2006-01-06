# readdir.sh:  Author: Tom Young, twyun@twyoung.com,  Date: 10/22/05
# Test for many files and directories at multiple levels.

# TEST: Branches: b0,b1
# TEST: Create many files in b0 and b1 then see if all appear in the unionfs.

source scaffold

function files {
cat <<FILES0
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
FILES0
}

# This works for 1-92 failing if > 92.
if [ -z $1 ]; then
        NGEN=100
else
        NGEN=$1
fi

# Generate N files
function filesx {
        N=$(($NGEN))
        while [ $N -gt 0 ]; do
                echo f ${LOWER_DIR}/b0/aljlelhkagekhakjdhfkjhakdhfaekcj_$N
                N=$(($N-1))
        done
}

# Generate N files
function filesy {
        N=$(($NGEN))
        while [ $N -gt 0 ]; do
                echo f ${LOWER_DIR}/b1/aljlelhkagekhakjdhfkjhakdhfaekcj_$N
                N=$(($N-1))
        done
}

( files; filesx; filesy ) | create_hierarchy
mount_union ""  $LOWER_DIR/b0 $LOWER_DIR/b1
FILES=`ls /mnt/unionfs/* |wc -l`
if [ $FILES != $NGEN ] ; then
	echo "There is a discrepancy in the number of files."
	echo -n "Unionfs: $FILES"
	echo -n "Expected: $NGEN"
	exit 1
fi
( files; filesx; filesy )  | check_hierarchy $LOWER_DIR

unmount_union

complete_test
