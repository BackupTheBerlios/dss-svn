#!/bin/bash

DIR=$2 
TRUNK=$1
cd $TRUNK/trunk
tar -v -c --exclude ".svn" . | tar x -C ../../$DIR
exit 
