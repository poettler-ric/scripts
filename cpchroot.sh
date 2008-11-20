#!/bin/sh

# copies a binary with all it's linked dependencies into a
# direcory for later use with chroot

if [ $# -lt 2 ]; then 
	echo "usage is: $0 <binary> <chroot dir>";
	exit;
fi;
if [ ! -f $1 ]; then
	echo "$1 doesn't exist";
	exit;
fi;

dest=`echo $2 | sed -e 's|/[\ \	]*$||'`;

for i in `ldd $1 | cut -d " " -f 3`; do 
	if [ ! -f $dest$i ]; then
		dir=`echo $dest$i | sed -e 's|/[^/]\+$||'`;
		if [ ! -d $dir ]; then 
			echo "mkdir -p $dir";
			mkdir -p $dir
		fi;
		echo "cp $i $2$i";
		cp $i $dest$i;
	fi;
done;
