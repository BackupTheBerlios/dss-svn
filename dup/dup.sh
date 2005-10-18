#!/bin/sh

# DSS-LV 
#
# dup.sh: script to upgrade DSS-Live testing
#
# Daniele Favara <danjele@gmail.com> 2005
# <http://dss.berlios.de>

# check for new version of of dup.sh
#set -x
# define vars
MIRROR=ftp://ftp.berlios.de/pub/dss/preA
MD5SUM=cdrom/md5sums
# define dialog vars
: ${DIALOG=dialog}
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_ESC=255}

TITLE1="DSS-Live Testing Update"
TITLENEW="New files to download"
COMMENTNEW="This is the list of the new files available \n \
select the ones you want to download"

TITLEUP="Files to upgrade"
COMMENTUP="This is the list of the files to upgrade \n \
select the ones you want to download \n \
(old files will be deleted)"
#########################################
#
#	FUNCTIONS
#
#########################################

#generate checklist options
print_checklist (){
input=$1
name_to_clean=$(echo $input | cut -d/ -f2- )
#name=$(basename $name_to_clean)
#path=${name_to_clean/$name}
echo "$name_to_clean" '-' "on"
}


#show checklist dialog
show_checklist(){
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
#trap "rm -f $tempfile" 0 1 2 5 15
backtitle=$1
title=$2
ckinfo=$3
size="17 55 7"
ckopts=$4
 $DIALOG --single-quoted --backtitle "'$backtitle'" --title "'$title'" --checklist "'$ckinfo'" $size $ckopts 2> $tempfile
retval=$?
choice=`cat $tempfile`
rm -f $tempfile 
case $retval in
  $DIALOG_OK)
    files_to_dwnl=$choice;;
  $DIALOG_CANCEL)
    exit 0;;
  $DIALOG_ESC)
    exit 0;;
  *)
    echo "Unexpected return code: $retval (ok would be $DIALOG_OK)";;
esac
}
print_welcome(){
$DIALOG --title "$TITLE1"  --clear \
        --msgbox "\n\
        This tool will upgrade \n\
           DSS Live Testing " 10 41

case $? in
  0)
    ok="OK";;
  255)
    exit 0;;
esac

}
print_new(){
$DIALOG --title "$TITLE1"  --clear \
        --msgbox "\
 It seems the first time you run dup.sh \
suggest you to select all the files that 
       can be downloaded" 10 41

case $? in
  0)
    ok="OK";;
  255)
    exit 0;;
esac

}
print_error(){
$DIALOG --title "$TITLE1"  --clear \
        --msgbox "ERROR: server down" 10 41

case $? in
  0)
    exit 0;;
  255)
    exit 0;;
esac

}
usage() {
print_noupgrade(){
$DIALOG --title "$TITLE1"  --clear \
        --msgbox "\
	 DSS Live Testing         \       
	http://dss.berlios.de      \                   

   type:                            \               
   #sudo ./make-iso cdrom DSS-Live.iso\     
   to generate the iso file            \            
                                                   
   maybe you want to test it using qemu:\           
   # qemu -cdrom DSS-Live-testing.iso  " 10 41

case $? in
  0)
    ok="OK";;
  255)
    exit 0;;
esac

}


print_help () {
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

cat cdrom/README > $tempfile

TEXT=cdrom/COPYING

cat $TEXT | expand >> $tempfile

$DIALOG --clear --exit-label OK --title "README" --textbox "$tempfile" 15 79 

case $? in
  0)
    echo "OK";;
  255)
    echo "ESC pressed.";;
esac
}

print_noupgrade(){
$DIALOG --title "$TITLE1"  --clear \
        --msgbox "Nothing to upgrade" 10 41

case $? in
  0)
    ok="OK";;
  255)
    exit 0;;
esac

}
print_makeiso(){
$DIALOG --timeout 20 --title "$TITLE1" \
        --yesno "Do you want to generate the iso image ?" 0 0

case $? in
  0)
    makeiso=yes;;
  1)
    makeiso=no;;
  255)
    exit 0;;
esac
}
select_isoname() {
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --title "$TITLE1" --clear \
        --inputbox "Insert the name of the iso file\n
you want to generate: \n
ex: DSS-Live to generate DSS-Live.iso \n
(You can use BACKSPACE to correct errors.) \n\n
Try entering the name below:" 16 51 2> $tempfile

retval=$?

case $retval in
  0)
    isoname=`cat $tempfile`;;
  1)
    echo "Cancel pressed.";;
  255)
    if test -s $tempfile ; then
      cat $tempfile
    else
      echo "ESC pressed."
    fi
    ;;
esac
}
gen_iso () {
	(
	sleep 1
	echo XXX
	echo  "Generating $1"
	echo XXX
	echo 10
	sh make-iso cdrom $1 2>&1 | 	sed -u -n -r 's/([0-9]{1,3})%.*$/\1/p' | awk 'BEGIN { FS = "[.]"}{print $1 }'	
	echo 100
	sleep 1
	)|  $DIALOG --title "$TITLE1" --gauge "Starting" 0 70 0

}
###########################################



if [ ! -d "cdrom" ];then
	print_new
else 
	print_welcome
fi

if [ ! -f "cdrom/README" ];then
		(
	sleep 1
	echo XXX
	echo "Downloading README"
	echo XXX
	wget -x  -nH --cut-dirs=3 $MIRROR/cdrom/README 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "README" --gauge "Starting" 0 70 0

fi
if [ ! -f "cdrom/COPYING" ];then
		(
	sleep 1
	echo XXX
	echo "Downloading COPYING"
	echo XXX
	wget -x  -nH --cut-dirs=3 $MIRROR/cdrom/COPYING 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "COPYING" --gauge "Starting" 0 70 0

fi
	



print_help 

if [ "test" = "" ];then



#remove old dup.md5sum
[ -f dup.md5sum ] && rm dup.md5sum

# start downloding dup.md5sum

####################
#
#  dialog dup.md5sum
#
####################
(
sleep 1
echo XXX
echo "Downloading dup.md5sum"
echo XXX
wget -nc "$MIRROR/dup.md5sum" 2>&1 | sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
echo 100
sleep 1
)|  $DIALOG --title "Checking for new version of dup.sh" --gauge "Starting" 0 70 0

# exit if dup.md5sum doesn't exist (server down?)
[ ! -f "dup.md5sum" ] && print_error

[ -f dup.md5sum ] && ver=$(cat dup.md5sum | awk '{print $1}' )
[ -f dup.sh ] && md5dup=$(md5sum dup.sh | awk '{print $1}')
if [ "$ver" != "$md5dup" ];then
#	echo ""
#	echo "Downloading new version of dup.sh"
#	echo "ftp://ftp.berlios.de/pub/dss/preA/dup.sh"
#	echo "and run again the script"
#	echo ""

	#make a bk
	mv dup.sh dup.sh.bk

#########################
#
# 	dialog dup.sh
#
#########################
	(
	sleep 1
	echo XXX
	echo "Downloading new version of dup.sh"
	echo XXX
	wget -nc "$MIRROR/dup.sh" 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "Found new version of dup.sh" --gauge "Starting" 0 70 0

        if [ -f "dup.sh" ];then 
		rm dup.sh.bk && sh dup.sh && exit 0
	else
	print_error
	fi
		

# remove dup.md5sum
else
[ -f dup.sh ] && [ -f dup.md5sum ]  && rm dup.md5sum
fi
#test stop
fi
#set +x


# backup md5sums od current files
#[  -d cdrom ]  && md5sum `find cdrom -type f `> md5sums.old

#echo "Downloading md5sums"
#########################
#
# 	dialog md5sums
#
#########################

	(
	sleep 1
	echo XXX
	echo "Downloading md5sums"
	echo XXX
	wget -x  -nH --cut-dirs=3 $MIRROR/$MD5SUM 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "md5sums" --gauge "Starting" 0 70 0

:> wget.list

# generate list of files upgradable

while read line
do 
md5=$(echo $line | awk '{print $1}')
file=$(echo $line | awk '{print $2}')
if [ "$file" != "$MD5SUM" ];then
	if [ -e "$file" ];then
		md5test=$(md5sum $file | awk '{print $1}')
		if [ $md5 != "$md5test"  ];then
		upgrades="$upgrades $file"
	fi
	else
		newfiles="$newfiles $file"
	fi
fi
done < $MD5SUM
:>wget.list
empty="$upgrades$newfiles"
if [ "$empty" != "" ];then
	if [ -n "$upgrades" ];then
		listup=$upgrades
		for  fileold in $listup
		do
			checklistup="$checklistup $(print_checklist $fileold)"
			
		done
		show_checklist "$TITLE1" "$TITLEUP" "$COMMENTUP" "$checklistup"
		for newwget in $files_to_dwnl;do
			echo cdrom/$newwget >> wget.list
			[ -e "cdrom/$newwget" ] && rm cdrom/$newwget
		done
	fi
	if [ -n "$newfiles" ];then
		listnew=$newfiles
		echo $listnew > /tmp/new
		for  fileold in $listnew
		do
			checklistnew="$checklistnew $(print_checklist $fileold)"
		done
		show_checklist "$TITLE1" "$TITLENEW" "$COMMENTNEW" "$checklistnew"
		for newwget in $files_to_dwnl;do
			echo cdrom/$newwget >> wget.list
			[ -e "cdrom/$newwget" ] && rm cdrom/$newwget
		done
	fi
while read toget
do
(
	sleep 1
	echo XXX
	echo "Downloading $(basename $toget)"
	echo XXX
	wget  -x  -nH --cut-dirs=3   $MIRROR/$toget 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "$MIRROR/$toget" --gauge "Starting" 0 70 0
done < wget.list	
	
else
	print_noupgrade
fi

#if [ -z $(which make-iso) ];then
[ -e "make-iso" ] && mv make-iso make-iso.bk

	(
	sleep 1
	echo XXX
	echo "Downloading make-iso"
	echo XXX
	wget -nH  http://svn.berlios.de/viewcvs/*checkout*/dss/debaser/trunk/make-iso 2>&1 | 	sed -u -n -r 's/^.* ([0-9]{1,3})%.*$/\1/p'
	echo 100
	sleep 1
	)|  $DIALOG --title "make-iso" --gauge "Starting" 0 70 0

if [ -e "make-iso" ];then
	chmod +x make-iso && rm make-iso.bk
	print_makeiso
	if [ "$makeiso" = "yes" ];then
		select_isoname
		if [ -n "$isoname" ];then
		gen_iso $isoname.iso		
		fi
	fi
		
else
	print_error
fi

#fi

usage
