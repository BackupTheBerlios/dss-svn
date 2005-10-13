#!/bin/sh

# DSS-LV 
#
# dup.sh: script to upgrade DSS-Live testing
#
# Daniele Favara <danjele@gmail.com> 2005
# <http://dss.berlios.de>

# check for new version of of dup.sh
#echo "Checking dup.sh version"
[ -f dup.md5sum ] && rm dup.md5sum
wget -nv ftp://ftp.berlios.de/pub/dss/preA/dup.md5sum
#set -x
[ -f dup.md5sum ] && ver=$(cat dup.md5sum | awk '{print $1}' )
[ -f dup.sh ] && md5dup=$(md5sum dup.sh | awk '{print $1}')
if [ "$ver" != "$md5dup" ];then
	echo ""
	echo "I found a new version of dup.sh download it from:"
	echo "ftp://ftp.berlios.de/pub/dss/preA/dup.sh"
	echo "and run again the script"
	echo ""
	mv dup.sh dup.sh.bk
	exit 0
else
[ -f dup.sh ] && [ -f dup.md5sum ] && echo "[Ok]" && rm dup.md5sum
fi
#set +x
MIRROR=ftp://ftp.berlios.de/pub/dss/preA/
MD5SUM=cdrom/md5sums
md5sum `find -type f | cut -d/ -f2- `> md5sums.old
echo "Downloading md5sums from $MIRROR"
wget -x -nv --progress=dot -nH --cut-dirs=3 $MIRROR/$MD5SUM
:> wget.list
while read line
do 
md5=$(echo $line | awk '{print $1}')
file=$(echo $line | awk '{print $2}')
if [ "$file" != "$MD5SUM" ];then
	if [ -e "$file" ];then
		md5test=$(md5sum $file | awk '{print $1}')
		if [ $md5 != "$md5test"  ];then
		upgrades="$upgrades $file"
		echo $MIRROR/$file >> wget.list
	fi
	else
		newfiles="$newfiles $file"
		echo $MIRROR/$file >> wget.list
	fi
fi
done < $MD5SUM

empty="$upgrades$newfiles"
if [ "$empty" != "" ];then
	if [ -n "$upgrades" ];then
		echo 
		echo ----------------------------------
		echo "these files will be upgraded:"
		listup=$(echo "$upgrades" | tr ' ' '\n')
		echo "$listup"
		echo
		echo ----------------------------------
	fi
	if [ -n "$newfiles" ];then
		echo "these files will be downloaded:"
		listnew=$(echo "$newfiles" | tr ' ' '\n')
		echo "$listnew"
		echo
		echo ----------------------------------
	fi
	echo -n "Should I upgrade?: [N/y]"
	read ansfer
	if [ "$ansfer" = "n" ];then
        	exit 0
	elif [ "$ansfer" = "N" ];then
	        exit 0
	elif [ "$ansfer" = "y" ];then
	        echo
	        echo "Starting"
	        echo
	elif [ "$ansfer" = "Y" ];then
	        echo
	        echo "Starting"
	        echo
	else
        	exit 0
	fi
	wget  -c -x   -nH --cut-dirs=3  -i wget.list
else
	echo
	echo ----------------------------------	
	echo "nothing to upgrade"
	echo ----------------------------------	
	echo
fi

if [ -z $(which make-iso) ];then
wget -nH  http://svn.berlios.de/viewcvs/*checkout*/dss/debaser/trunk/make-iso
fi

usage() {

         cat >&2 << EOF
/---------------------------------------------------\
|                                                   |
|      DSS Live Testing                             |             
|     http://dss.berlios.de                         |
|                                                   | 
|   type:                                           |
|   #sudo ./make-iso cdrom DSS-Live-testing.iso     |
|   to generate the iso file                        |
|                                                   |
|   maybe you want to test it using qemu:           |
|   # qemu -cdrom DSS-Live-testing.iso              |
|                                                   | 
\---------------------------------------------------/

EOF
        exit 1
}
usage
