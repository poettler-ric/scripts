#!/bin/sh

# script to syncronize distributed openfoam calculations to one local directory

NUMBER_OF_NODES=4
REMOTE_DIR=/mnt/sgeadmin/calc
LOCAL_DIR=/calc/sgeadmin
# minimum delay between syncronizations in seconds
MINIMUM_DELAY=$((5*60))

$DEBUG # use with 'export DEBUG="set -x"'

while true
do
	LAST_RUN=`date +%s`

	for i in `seq 1 $NUMBER_OF_NODES`
	do
		NODE=`printf "node%03d" $i`
		echo syncing $NODE
		rsync -arc $NODE:$REMOTE_DIR $LOCAL_DIR
	done

	NOW=`date +%s`
	TIME_DIFF=$(($NOW-$LAST_RUN))
	if [ $TIME_DIFF -gt 0 ]
	then
		TO_SLEEP=$(($MINIMUM_DELAY-$TIME_DIFF))
		sleep $TO_SLEEP
	fi
done
