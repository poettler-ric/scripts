#!/bin/bash

while getopts "n" OPT
do
	case $OPT in
		n)
		NO_DISPLAY=1
		;;
	esac
done

RESOLUTION="1680x1050"
DIRECTORY="/mnt/data/wp"
IMGFILE="$HOME/.wp.jpg"
HISTFILE="$HOME/.wp.history"

TMPBLACK="/tmp/black.jpg"
TMPRESIZE="/tmp/resize.jpg"

FILES=($(find $DIRECTORY -type f -iname "*.jpg"))
FILE=${FILES[$(($RANDOM % ${#FILES[*]}))]}

convert $FILE -resize $RESOLUTION $TMPRESIZE
convert xc:black -resize $RESOLUTION! $TMPBLACK
composite -gravity center $TMPRESIZE $TMPBLACK -compose src-over $IMGFILE

rm $TMPBLACK $TMPRESIZE

echo $FILE >> $HISTFILE

if [[ -z $NO_DISPLAY ]]
then
	display -window root $IMGFILE
fi
