#!/bin/bash

CONFFILE="$HOME/.wpchanger"

RESOLUTION="1680x1050"
DIRECTORY="/mnt/data/wp"
IMGFILE="$HOME/.wp.jpg"
HISTORYFILE="$HOME/.wp.history"
SETCOMMAND="gconftool-2 --type string --set /desktop/gnome/background/picture_filename $IMGFILE"

TMPBLACK="/tmp/black.jpg"
TMPRESIZE="/tmp/resize.jpg"

if [[ -r $CONFFILE ]]
then
	. $CONFFILE
fi

while getopts "ec:d:h:o:r:" OPT
do
	case $OPT in
		e)
		EXECUTE=1
		;;
		c)
		SETCOMMAND=$OPTARG
		;;
		d)
		DIRECTORY=$OPTARG
		;;
		h)
		HISTORYFILE=$OPTARG
		;;
		r)
		RESOLUTION=$OPTARG
		;;
		o)
		IMGFILE=$OPTARG
		;;
	esac
done

FILES=($(find $DIRECTORY -type f -iname "*.jpg"))
FILE=${FILES[$(($RANDOM % ${#FILES[*]}))]}

convert $FILE -resize $RESOLUTION $TMPRESIZE
convert xc:black -resize $RESOLUTION! $TMPBLACK
composite -gravity center $TMPRESIZE $TMPBLACK -compose src-over $IMGFILE

rm $TMPBLACK $TMPRESIZE

if [[ -n "$HISTORYFILE" ]]
then
	echo $FILE >> $HISTORYFILE
fi

if [[ "$EXECUTE" == "1" ]]
then
	$SETCOMMAND
fi
