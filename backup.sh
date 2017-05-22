#!/usr/bin/env bash
mongodump --db expedia-dictionary
cd dump
NOW=$(date +"%m_%d_%Y_%H%M%S")
FILENAME="dictionary-backup_$NOW.tar.gz"
tar -zcvf $FILENAME expedia-dictionary/
aws s3 cp $FILENAME s3://ewe-softwares/backup/dictionary/

cd ../
rm -rf dump