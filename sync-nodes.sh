#!/bin/sh

# script to syncronize distributed openfoam calculations to one local directory

NUMBER_OF_NODES=4
REMOTE_DIR=/mnt/sgeadmin/calc
LOCAL_DIR=/calc/sgeadmin
# minimum delay between syncronizations in seconds
MINIMUM_DELAY=$((5*60))

debug() {
	if [ $DEBUG ]
	then
		echo $@
	fi
}

debug minimum delay: $MINIMUM_DELAY

while true
do
	LAST_RUN=`date +%s`
	debug last run: $LAST_RUN

	for i in `seq 1 $NUMBER_OF_NODES`
	do
		NODE=`printf "node%03d" $i`
		echo syncing $NODE
		rsync -arc $NODE:$REMOTE_DIR $LOCAL_DIR
	done

	TIME_DIFF=$((`date +%s`-$LAST_RUN))
	if [ $TIME_DIFF -gt 0 ]
	then
		TO_SLEEP=$(($MINIMUM_DELAY-$TIME_DIFF))
		debug sleeping: $TO_SLEEP
		sleep $TO_SLEEP
	fi
done
