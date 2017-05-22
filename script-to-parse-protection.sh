#!/bin/bash

 

if [ "$1" == "" ]; then

            echo "usage: user_info <userID>"

            exit -1

fi

 

p4 users | grep -i $1 | while read line; do

            if [ "$line" == "" ]; then

                        echo "User ID \"$1\" does not exist"

                        exit -1

            fi

 

            user=`echo $line | awk '{print $1}'`

 

            echo "$line"

 

            for i in `p4 groups`; do

                        assign=`p4 group -o $i | grep "$user

"`

 

                        if [ "$assign" != "" ]; then

                                    p4 protect -o | grep " $i "

                        fi

            done

done