#!/bin/bash

CONFFILE="$HOME/.wpchanger"

RESOLUTION="1680x1050"
DIRECTORY="/mnt/data/wp"
IMGFILE="$HOME/.wp.jpg"
HISTFILE="$HOME/.wp.history"

TMPBLACK="/tmp/black.jpg"
TMPRESIZE="/tmp/resize.jpg"

if [[ -r $CONFFILE ]]
then
	. $CONFFILE
fi

while getopts "d:h:o:r:s" OPT
do
	case $OPT in
		d)
		DIRECTORY=$OPTARG
		;;
		h)
		HISTFILE=$OPTARG
		;;
		r)
		RESOLUTION=$OPTARG
		;;
		o)
		IMGFILE=$OPTARG
		;;
		s)
		SHOW=1
		;;
	esac
done

FILES=($(find $DIRECTORY -type f -iname "*.jpg"))
FILE=${FILES[$(($RANDOM % ${#FILES[*]}))]}

convert $FILE -resize $RESOLUTION $TMPRESIZE
convert xc:black -resize $RESOLUTION! $TMPBLACK
composite -gravity center $TMPRESIZE $TMPBLACK -compose src-over $IMGFILE

rm $TMPBLACK $TMPRESIZE

echo $FILE >> $HISTFILE

if [[ "$SHOW" == "1" ]]
then
	display -window root $IMGFILE
fi
