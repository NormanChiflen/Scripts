saved as “/etc/init.d/jenkins”):
# Example Jenkins auto-start service script
#
# description: manages Jenkins as a service
# processname: jenkins
# pidfile: /var/run/jenkins.pid
# author: www.DonaldSimpson.co.uk# The user and the home dir that Jenkins runs under
jenkins=/usr/local/jenkins
# Your startup and stop scripts (see below)
startup=$jenkins/bin/startup.sh
shutdwn=$jenkins/bin/shutdown.sh

start_jenkins() {
echo “Starting Jenkins services…”
su – jenkins -c “sh $startup”
}

stop_jenkins() {
echo “Stopping Jenkins services…”
su – jenkins -c “sh $shutdwn”
}

status_jenkins() {
# Check for any other process containing jenkins.war
# This could be improved upon (see script below)
numproc=`ps -ef | grep [j]enkins.war | wc -l`
if [ $numproc -ne 0 ]; then
echo “Jenkins is running…”
else
echo “Jenkins is NOT running…”
fi
}

case “$1″ in
start)
start_jenkins
;;
stop)
stop_jenkins
;;
status)
status_jenkins
;;
restart)
stop_jenkins
start_jenkins
;;
*)
echo “Usage: $0 {start|stop|status|restart}”
exit 1
esac
exit 0

Update that to suit then save and change the permissions to make it executable:
chmod +x /etc/init.d/jenkins

then you can check (as root) that you can call the methods in the script:
service jenkins statusservice jenkins stop

service jenkins start

/usr/local/jenkins/bin/startup.sh

and
/usr/local/jenkins/bin/shutdown.sh

added and included some basic tests to my scripts and some (very) rudimentary error handling/checking, but you shoudl get the idea and all you really need is this line (with the variables set correctly):
${NOHUP} ${JAVA} -jar ${JENKINS_WAR} -D${MARKER} –httpListenAddress=0.0.0.0 –httpPort=${HTTP_PORT} > ${LOG_FILE} &

The stop part of my Jenkins management script finds the correct PID like this (and you could use a filter for the correct -D${MARKER} if you want that too):
PID=`${LSOF} -w -n -i tcp:${HTTP_PORT} | ${GREP} -v COMMAND | ${AWK} {‘print $2′}`

The stop part of my Jenkins management script finds the correct PID like this (and you could use a filter for the correct -D${MARKER} if you want that too):
PID=`${LSOF} -w -n -i tcp:${HTTP_PORT} | ${GREP} -v COMMAND | ${AWK} {‘print $2′}`
