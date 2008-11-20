#!/bin/sh

# downloads all sources of a git repository

echo "doing $1";

for i in `ls $1` ; do
	if [ -d $1/$i ] ; then
		echo "package $i";
		cd $1/$i;
		pkgmk -do;
	fi;
done;
