#!/bin/sh

export POSTGRESQL_VERSION=9.0.4
export LD_LIBRARY_PATH=/opt/postgresql/${POSTGRESQL_VERSION}/lib
export PATH=/opt/postgresql/${POSTGRESQL_VERSION}/bin:${PATH}

    chmod a+x /home/postgres/.environment-9.0.4
    /home/postgres/.environment-9.0.4
    /opt/postgresql/9.0.4/bin/initdb -D /opt/postgresql/9.0.4/data/ –encoding=UNICODE
    nano /home/postgres/postgresql-9.0.4

#!/bin/sh -e

# Parameters: start or stop.
export POSTGRESQL_VERSION=9.0.4

# Check parameter.
if [ "$1" != "start" ] && [ "$1" != "stop" ]; then
  echo "Specify start or stop as first parameter."
  exit
fi

# Add stop switch.
__STOP_SWITCH=""
if [ "$1" = "stop" ]; then
  __STOP_MODE="smart"
  __STOP_SWITCH="-m $__STOP_MODE"
  echo "Stop switch is: $__STOP_SWITCH"
fi

# Do it.
export LD_LIBRARY_PATH=/opt/postgresql/${POSTGRESQL_VERSION}/lib
~/.environment-${POSTGRESQL_VERSION}
/opt/postgresql/${POSTGRESQL_VERSION}/bin/pg_ctl \
     -D /opt/postgresql/${POSTGRESQL_VERSION}/data \
     -l /opt/postgresql/${POSTGRESQL_VERSION}/log/postgresql.log \
     $1 $__STOP_SWITCH

    The command ‘~/.environment-${POSTGRESQL_VERSION}’ could not work. Use ‘. .environment-${POSTGRESQL_VERSION}’ instead.
    chmod a+x /home/postgres/postgresql-9.0.4
    exit
    sudo nano /etc/init.d/postgresql.9.0.4

#!/bin/sh -e

case "$1" in

 start)
  echo "Starting postgres"
  /bin/su - postgres -c "/home/postgres/postgresql-9.0.4 start"
  ;;
 stop)
  echo "Stopping postgres" 
  /bin/su - postgres -c "/home/postgres/postgresql-9.0.4 stop"
  ;;
 * )
  echo "Usage: service postgresql-9.0.4 {start|stop}"
  exit 1

esac

exit 0



nano /opt/alfresco/start_oo.sh

#!/bin/sh -e

SOFFICE_ROOT=/usr/bin
"${SOFFICE_ROOT}/soffice" "--accept=socket,host=localhost,port=8100;urp;StarOffice.ServiceManager" --nologo --headless &

    chmod uga+x /opt/alfresco/start_oo.sh
    /opt/alfresco/start_oo.sh
    killall soffice.bin
    nano /opt/alfresco/alfresco.sh

#!/bin/sh -e

# Start or stop Alfresco server

# Set the following to where Tomcat is installed
ALF_HOME=/opt/alfresco
cd "$ALF_HOME"
APPSERVER="${ALF_HOME}/tomcat"
export CATALINA_HOME="$APPSERVER"

# Set any default JVM values
export JAVA_OPTS='-Xms512m -Xmx768m -Xss768k -XX:MaxPermSize=256m -XX:NewSize=256m -server'
export JAVA_OPTS="${JAVA_OPTS} -Dalfresco.home=${ALF_HOME} -Dcom.sun.management.jmxremote"

if [ "$1" = "start" ]; then
 "${APPSERVER}/bin/startup.sh"
 if [ -r ./start_oo.sh ]; then
  "${ALF_HOME}/start_oo.sh"
 fi
elif [ "$1" = "stop" ]; then
 "${APPSERVER}/bin/shutdown.sh"
 killall -u alfresco java
 killall -u alfresco soffice.bin
fi

    chmod uga+x /opt/alfresco/alfresco.sh
    sudo nano /etc/init.d/alfresco

#!/bin/sh -e

ALFRESCO_SCRIPT="/opt/alfresco/alfresco.sh"

if [ "$1" = "start" ]; then
 su - alfresco "${ALFRESCO_SCRIPT}" "start"
elif [ "$1" = "stop" ]; then
 su - alfresco "${ALFRESCO_SCRIPT}" "stop"
elif [ "$1" = "restart" ]; then
 su - alfresco "${ALFRESCO_SCRIPT}" "stop"
 su - alfresco "${ALFRESCO_SCRIPT}" "start"
else
 echo "Usage: /etc/init.d/alfresco [start|stop|restart]"
fi

    sudo chmod uga+x /etc/init.d/alfresco
    sudo chown alfresco:alfresco /etc/init.d/alfresco
    mkdir /opt/alfresco/alf_data
    cp /opt/alfresco/tomcat/shared/classes/alfresco-global.properties.sample /opt/alfresco/tomcat/shared/classes/alfresco-global.properties
    nano /opt/alfresco/tomcat/shared/classes/alfresco-global.properties
