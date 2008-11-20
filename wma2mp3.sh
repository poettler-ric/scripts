#!/bin/sh

# code copied from http://ocaoimh.ie/2005/08/16/how-to-convert-from-wma-to-mp3/

for i in *.wma
do
	mplayer -vo null -vc dummy -af resample=44100 -ao pcm -ao pcm:waveheader "$i" \
		&& lame -m j -h --vbr-new -b 160 audiodump.wav -o "`basename "$i" .wma`.mp3"
done
rm -f audiodump.wav