#!/bin/bash
#gnome-volume-manager &
USER=$( ps aux | grep $PPID | awk '{print $1}' | head -1 )

#[ -f /morphix/include.sh ] && . /morphix/include.sh 
if [ "$USER" = "root" ];then
	sed -i -e "s,/home/[^/]\+/.xtdesktop/,/root/.xtdesktop/,g" $HOME/.xtdesktop/*.lnk 
else
 	sed -i -e "s,/home/[^/]\+/.xtdesktop/,/home/$USER/.xtdesktop/,g" $HOME/.xtdesktop/*.lnk
sed -i -e "s,/root/.xtdesktop/,/home/$USER/.xtdesktop/,g" $HOME/.xtdesktop/*.lnk 
fi
#sed -i -e "s,/root/,/$HOME/,g" $HOME/.xtdesktop/*.lnk
[ -e /tmp/.lasticon ] && rm -f  /tmp/.lasticon
rm -f $HOME/.xtdesktop/allow*.lnk
rm -f $HOME/.xtdesktop/added*.lnk
x=300
y=300
num=1
entry=$(cat /etc/pmount.allow | grep -w dev)
echo $entry
for i in $entry; do
	lnk=$(basename $i)
	if [ ! -e "$HOME/.xtdesktop/$lnk.lnk" ];then
	echo "table Icon" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "Type: Program" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "Caption: $lnk" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "Command: /usr/share/xtdesktop/pmount.sh openfolder $i" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "Icon: $HOME/.xtdesktop/hd.png" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "X: $x" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "Y: $y" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "MenuCommand1: Mount $lnk : /usr/share/xtdesktop/pmount.sh pmount $i" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "MenuCommand2: Umount $lnk : /usr/share/xtdesktop/pmount.sh pumount $i" >> $HOME/.xtdesktop/allow$lnk.lnk
	echo "end" >> $HOME/.xtdesktop/allow$lnk.lnk
	let x+=80 
	if [ "$num" = "6" ];then
	let y+=90
	num=0
	fi
	let num+=1
#	[ ! -e /etc/sysconfig/lasticon  ] && touch /etc/sysconfig/lasticon
	echo $x $y $num> /tmp/.lasticon
	fi
done
xtdesk &

