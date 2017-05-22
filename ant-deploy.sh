#!/bin/bash

#setup environment
. /etc/profile.d/ccm-config.sh
. /etc/profile.d/ccm-devel.sh
. /etc/profile.d/ccm-scripts.sh

CCM_HOME=/var/ccm-devel/dev/user/cms_dev
ORACLE_HOME="/opt/oracle/product/9.2.0"
JAVA_HOME=/opt/IBMJava2-131

CLASSPATH=$CCM_HOME/core-platform/lib/jaas.jar
CLASSPATH=$CLASSPATH:$CCM_HOME/core-platform/lib/jce.jar
CLASSPATH=$CLASSPATH:$CCM_HOME/core-platform/lib/sunjce_provider.jar
CLASSPATH=$CLASSPATH:$CLASSPATH:$ORACLE_HOME/jdbc/lib/classes12.zip
CLASSPATH=$CLASSPATH:$CCM_HOME/core-platform/etc/lib/iDoclet.jar
export CLASSPATH

export ANT_OPTS="-Xms128m -Xmx128m"

##########
#build
##########

#uncomment to make enterprise.init
#cd $CCM_HOME
#ant make-config
#ant make-init

#clean
cd $CCM_HOME
ant clean

#build
cd $CCM_HOME
ant deploy

#javadoc
cd $CCM_HOME
ant javadoc
ant deploy-api