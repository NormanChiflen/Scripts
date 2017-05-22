#!/bin/sh

HOSTNAME="${COLLECTD_HOSTNAME:-`hostname`}"
INTERVAL="${COLLECTD_INTERVAL:-10}"

while sleep "$INTERVAL"
do
	info=`echo srvr | nc localhost 2181`
	received=`echo "$info" | grep Received | awk -F : {'print $2'} | tr -d ' '`
	sent=`echo "$info" | grep Sent | awk -F : {'print $2'} | tr -d ' '`
	connections=`echo "$info" | grep Connections | awk -F : {'print $2'} | tr -d ' '`
	echo "PUTVAL $HOSTNAME/zookeeper-received/total_requests interval=$INTERVAL N:$received"
	echo "PUTVAL $HOSTNAME/zookeeper-sent/total_requests interval=$INTERVAL N:$sent"
	echo "PUTVAL $HOSTNAME/zookeeper-connections/connections interval=$INTERVAL N:$connections"
done