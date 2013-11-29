#!/bin/sh

# needed so we have the right amount of fields when reading the cpu load
export LC_TIME=en_US.UTF-8

time=`date +%Y%m%d-%H%M`
prefix=`hostname`:$time

# get cpu reading
# order: overall cpu1 cpu2 ... cpun
printf "%s:cpu:" "$prefix"
for idle in `mpstat -P ALL | sed -e '1,3d' | tr -s ' ' | cut -d ' ' -f 12`
do
	usage=`echo "100-$idle" | bc`
	printf " %s" "$usage"
done
echo

# get memory reading
# order: total used free
printf "%s:mem: " "$prefix"
free -m | sed -n -e '2,3p' | tr -d '\n' | tr -s ' ' | cut -d ' ' -f 2,9,10

# get swap reading
# order: total used free
printf "%s:swap: " "$prefix"
free -m | sed -n -e '4p' | tr -s ' ' | cut -d ' ' -f 2,3,4

# get load reading
# order: last1m last5m last15m
printf "%s:load: " "$prefix"
cat /proc/loadavg | tr -s ' ' | cut -d ' ' -f 1,2,3

# get nic reading in bytes
# order: nic1 nic1-rx nic1-tx nic2 nic2-rx nic2-tx ... nicn nicn-rx nicn-tx
printf "%s:nic: " "$prefix"
cat /proc/net/dev | sed -n -e '/eth/p' | sed -e 's/^[ \t]*//' | tr -d : \
	| tr -s ' ' | cut -d ' ' -f 1,2,10 | tr '\n' ' '
echo

# get hdd reading in megabytes
# order: dev1 total1 used1 free1 mount1 dev2 total1 used2 free1 mount2 ...
printf "%s:hdd: " "$prefix"
df -BM | sed -n -e '/^\/dev/p' | sed -e 's/\([0-9]\+\)M/\1/g' \
	| tr -s ' ' | cut -d ' ' -f 1,2,3,4,6 | tr '\n' ' '
echo
