#!/bin/bash

################################## 
#                                # 
# POSTGRES DUMPS FOR PILOTROI    # 
# Vincent Teyssier               # 
# 19/11/2010                     # 
#                                # 
##################################

echo "******************************************************" 
echo "Database dump is starting at : " `date` 
echo "******************************************************"

PG_DUMP="/usr/lib/postgresql/8.4/bin/pg_dump" 
S3PUT="/mnt/postgres/s3tools/s3cmd-1.0.0-rc1/s3cmd"

BASE=$1 
SPLITS=$2 
DUMP_FILE="/mnt/postgres/dumps/$BASE.gz" 
S3ENDPOINT="s3://postgresql-dumps/pilotroi/$BASE/"

echo "*****************************" 
echo "Parameters : " 
echo "Base : " $BASE 
echo "Splits : " $SPLITS 
echo "S3 Endpoint : " $S3ENDPOINT 
echo "*****************************"

echo "Dump started at " `date` 
su - postgres -c "$PG_DUMP $BASE | gzip | split -b $SPLITS - $DUMP_FILE" 
echo "Dump ended at " `date` 
echo "*****************************" 
echo "Send to S3 started at " `date` 
$S3PUT put $DUMP_FILE* $S3ENDPOINT 
echo "Send ended at " `date` 
echo "*****************************" 
echo "Deleting local dump files" 
rm /mnt/postgres/dumps/$BASE.gz*

echo "******************************************************" 
echo "Database dump is finished at : " `date` 
echo "******************************************************" 