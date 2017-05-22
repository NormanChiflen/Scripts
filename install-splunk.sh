#!/usr/bin/ksh

SPLUNKDIR="/storage/splunk"
SPARCSPLUNK="${SPLUNKDIR}/splunk-4.3.2-123586-solaris-8-sparc.pkg"
SOLARISx64SPLUNK="${SPLUNKDIR}/splunk-4.3.2-123586-solaris-10-intel.pkg"
LINUXx64SPLUNK="${SPLUNKDIR}/splunk-4.3.2-123586-linux-2.6-x86_64.rpm"

function splunkSPARC {
    set -x
    sudo scp $SPARCSPLUNK  ${1}:/var/tmp
    sudo scp $SPLUNKDIR/response ${1}:/var/tmp
    sudo scp $SPLUNKDIR/admin ${1}:/var/tmp
    xNAME=`basename $SPARCSPLUNK`
    sudo ssh $1 "pkgadd -nr /var/tmp/response -a /var/tmp/admin -d /var/tmp/${xNAME} all"
    doSplunk $1
}
function splunkSolarisx64 {
    set -x
    sudo scp $SOLARISx64SPLUNK ${1}:/var/tmp
    sudo scp $SPLUNKDIR/response ${1}:/var/tmp
    sudo scp $SPLUNKDIR/admin ${1}:/var/tmp
    xNAME=`basename $SOLARISx64SPLUNK`
    sudo ssh $1 "pkgadd -nr /var/tmp/response -a /var/tmp/admin -d /var/tmp/${xNAME} all"
    doSplunk $1
}
function splunkLinuxx64 {
    set -x
    sudo scp $LINUXx64SPLUNK ${1}:/var/tmp
    xNAME=`basename $LINUXx64SPLUNK`
    sudo ssh $1 "rpm -Uvh /var/tmp/${xNAME}"
    doSplunk $1
}
function doSplunk {
    # start splunk accept default licensing

    sudo ssh $1 '/opt/splunk/bin/splunk start --accept-license'

    # configure the instance of splunk to become Universal Forwarder

    sudo ssh $1 '/opt/splunk/bin/splunk add forward-server splunk-01:9997 -auth admin:changeme'

    # Configure the instance of splunk to become a license slave to splunk-01

    sudo ssh $1 '/opt/splunk/bin/splunk edit licenser-localslave -master_uri "https://splunk-01.mydomain.com:8089"
-auth admin:changeme'
    # configure the instance of splunk to become a deployment client to splunk-01
    sudo ssh $1 '/opt/splunk/bin/splunk set deploy-poll splunk-01.mydomain.com:8089'

    # configure to disable web frontend and only enable the lightweight forwarder

    sudo ssh $1 '/opt/splunk/bin/splunk enable app SplunkLightForwarder'

    # restart splunk

   sudo ssh $1 '/opt/splunk/bin/splunk restart'

    # configure splunk to autostart on boot

   sudo ssh $1 '/opt/splunk/bin/splunk enable boot-start'
}

# Push the splunk pkg for sparc, uncompress the pkg and pkgadd it
CLIENT=$1
set -x
ID=`id|awk '{print $1}'|awk -F\= '{print $2}'|sed -e"s!(root)!!g"`

if [ $ID -ne 0 ]; then
    echo "You have to run this script as root or using sudo" && exit 1;
fi

PLATFORM=`sudo ssh $CLIENT 'uname -p'`
if [ $PLATFORM = "sparc" ]; then
    splunkSPARC $CLIENT
    sudo ssh splunk-01 '/opt/splunk/bin/splunk list deploy-clients -auth admin:changeme'
else
    if [ $PLATFORM = "x86_64" -o $PLATFORM = "i386" ]; then
        OS=`sudo ssh $CLIENT 'uname -s'`
        if [ $OS = "SunOS" ]; then
            splunkSolarisx64 $CLIENT
            sudo ssh splunk-01 '/opt/splunk/bin/splunk list deploy-clients -auth admin:changeme'
        elif [ $OS = "Linux" ]; then
            splunkLinuxx64 $CLIENT
            sudo ssh splunk-01 '/opt/splunk/bin/splunk list deploy-clients -auth admin:changeme'
        else
            echo "Unknown OS type $OS" && exit 1
        fi
    else
        echo "Unknown Platform $PLATFORM" && exit 1
    fi
fi
