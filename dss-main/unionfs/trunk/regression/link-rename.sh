#!/bin/sh
# TEST: Branches: b0,b1=ro,b2=ro
# This checks some rename and copyup issues where the
# copyup crosses a ro branch

source scaffold

function files {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
d $LOWER_DIR/b1
d $LOWER_DIR/b2
f $LOWER_DIR/b2/abc
FILES
}

function afterfiles_ro {
cat <<FILES
d $LOWER_DIR
d $LOWER_DIR/b0
l $LOWER_DIR/b0/abc
f $LOWER_DIR/b0/abc_
d $LOWER_DIR/b1
d $LOWER_DIR/b2
f $LOWER_DIR/b2/abc
FILES
}

( files ) | create_hierarchy
mount_union "" $LOWER_DIR/b0 $LOWER_DIR/b1=ro $LOWER_DIR/b2=ro

cd /mnt/unionfs/ > /dev/null
ln -s abc abc3
mv abc abc_
mv abc3 abc
cd - > /dev/null

unmount_union
( afterfiles_ro ) | check_hierarchy $LOWER_DIR

complete_test
