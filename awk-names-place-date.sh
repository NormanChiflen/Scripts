#bash script that put names, dates, and place in to a sample file. The code looks like this
#http://www.copyquery.com/bash-script-rewrite-in-powershell/
#/bin/bash

if [ $# -ne 2 ]; then
    echo You should give two parameters!
    exit
fi

while read line
do
    name=`echo $line | awk '{print $1}'`
    date=`echo $line  | awk '{print $2}'`
    place=`echo $line | awk '{print $3}'`
    echo `cat $1 | grep "<NAME>"|  sed -e's/<NAME>/'$name'/g'`
    echo `cat $1 | grep "<DATE>" | sed -e's/<DATE>/'$date'/g'`
    echo `cat $1 | grep "<PLACE>" | sed -e's/<PLACE>/'  $place'/g'`
    echo 
done < $2
