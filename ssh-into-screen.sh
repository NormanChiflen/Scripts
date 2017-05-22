#!/bin/bash
function s
{
if [[ "$@" == *@* ]];
        then
                ssh -t "$@" /usr/bin/screen -xRR
  
        else
                #assume ssh root@ for hosts completion and speed
                ssh -t root@"$@" /usr/bin/screen -xRR
 fi
  
}
s "$@"
macbook-air:~ aric$ sudo chmod +x /usr/bin/s