#!/bin/sh

time=`date +%Y%m%d-%H%M`

# get cpu reading
# order: overall cpu1 cpu2 ... cpun
echo -n "`hostname`:$time:cpu:"
for idle in `mpstat -P ALL | sed -e '1,3d' | tr -s ' ' | cut -d ' ' -f 12`
do
	usage=`echo 100-$idle | bc`
	echo -n " $usage"
done
echo

# get memory reading
# order: total used free
echo -n "`hostname`:$time:mem:"
echo -n " `free -m | sed -n -e '2p' | tr -s ' ' | cut -d ' ' -f 2`"
echo -n " `free -m | sed -n -e '3p' | tr -s ' ' | cut -d ' ' -f 3,4`"
echo

# get swap reading
# order: total used free
echo -n "`hostname`:$time:swap:"
echo -n " `free -m | sed -n -e '4p' | tr -s ' ' | cut -d ' ' -f 2,3,4`"
echo

# get load reading
# order: last1m last5m last15m
echo -n "`hostname`:$time:load:"
echo -n " `cat /proc/loadavg | tr -s ' ' | cut -d ' ' -f 1,2,3`"
echo

# get nic reading in bytes
# order: nic1 nic1-rx nic1-tx nic2 nic2-rx nic2-tx ... nicn nicn-rx nicn-tx
echo -n "`hostname`:$time:nic:"
echo -n " "
cat /proc/net/dev | sed -n -e '/eth/p' | sed -e 's/^[ \t]*//' | tr -d : \
	| tr -s ' ' | cut -d ' ' -f 1,2,10 | tr '\n' ' '
echo
