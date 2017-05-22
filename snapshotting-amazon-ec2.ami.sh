#!/bin/bash
# EBS Snapshot volume script
# Constants - You'll want to edit these
JAVA_HOME="/usr"
EC2_HOME="/opt/aws"
ec2_bin="/opt/aws/bin"
export EC2_HOME
export JAVA_HOME
LOGFILE='/var/log/aws_snapshot.log'
TMPFILE='/tmp/snap_info.txt'
 
VOLTMPFILE='/tmp/volume_info.txt'
 
# Retention in days
RETENTION="7"
 
# AWS ACCESS INFO
access_key='SOMEACCESSKEY'
secret_key='SOMESECRETKEY'
instance_id=`wget -q -O- http://169.254.169.254/latest/meta-data/instance-id`
 
# Dates
datecheck_7d=`date +%Y-%m-%d --date "$RETENTION days ago"`
datecheck_s_7d=`date --date="$datecheck_7d" +%s`
datenow=`date +%Y-%m-%d-%H:%M:%S`
 
# Add entry in logfile for run begin
echo "${datenow} ======= BEGIN SNAPSHOT SCRIPT =========" 2>&1 >> $LOGFILE
# Get all volume info and copy to temp file
$ec2_bin/ec2-describe-volumes -O $access_key -W $secret_key  --filter "attachment.instance-id=$instance_id" > $VOLTMPFILE 2>&1
 
# Get all snapshot info
$ec2_bin/ec2-describe-snapshots -O $access_key -W $secret_key | grep "$instance_id" > $TMPFILE 2>&1
 
# Loop to remove any snapshots older than 7 days
for obj0 in $(cat $TMPFILE | awk '{print $5}')
do
        snapshot_name=`cat $TMPFILE | grep "$obj0" | awk '{print $2}'`
        datecheck_old=`cat $TMPFILE | grep "$snapshot_name" | awk '{print $5}' | awk -F "T" '{print $1}'`
        datecheck_s_old=`date --date="$datecheck_old" +%s`
 
        # Check if snapshot is older than retention days
        if (( $datecheck_s_old <= $datecheck_s_7d ));
        then
                echo "deleting snapshot $snapshot_name ... older than $RETENTION days" 2>&1 >> $LOGFILE
                $ec2_bin/ec2-delete-snapshot -O $access_key -W $secret_key $snapshot_name
        else
                echo "not deleting snapshot $snapshot_name ... not older than $RETENTION days" 2>&1 >> $LOGFILE
        fi
done
 
# Create snapshot
for volume in $(cat $VOLTMPFILE | grep "VOLUME" | awk '{print $2}')
do
        # Description cannot have spaces
        description="instance-id:${instance_id}_vol-id:${volume}_`hostname`_backup-`date +%Y-%m-%d`"
        echo "Creating Snapshot for the volume: $volume with description: $description" 2>&1 >> $LOGFILE
        $ec2_bin/ec2-create-snapshot -O $access_key -W $secret_key -d "$description" $volume 2>&1 >> $LOGFILE
done

#Install the below script in cron on your snapshot interval and change the “Constants” and also plugin your AWS Keys
#http://cookingclouds.com/2012/10/24/amazon-ec2-snapshotting-ebs-script/