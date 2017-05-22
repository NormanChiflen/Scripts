#!/bin/sh
 
MNT_DEPREPS=/mnt/depreps
MNT_DEPLOY=/mnt/deployment
OLD_PASSWORD=PASSWD
read -er -p "SEA User:" SEA_USER
read -ers -p "$SEA_USER Password:" PASSWD
echo
export PASSWD
mkdir -p $MNT_DEPREPS
mkdir -p $MNT_DEPLOY
echo "Mounting depreps $MNT_DEPREPS"
mount -t cifs -o username=$SEA_USER,domain=sea,file_mode=0555,ro //chelfilrtt02.karmalab.net/depreps $MNT_DEPREPS
echo "Mounting deployment $MNT_DEPLOY"
mount -t cifs -o username=$SEA_USER,domain=sea,file_mode=0555,ro //chelfilrtt01.karmalab.net/deployment-net $MNT_DEPLOY
PASSWD=$OLD_PASSWORD
export PASSWD