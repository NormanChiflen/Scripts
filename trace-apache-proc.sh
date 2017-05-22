ps -C apache o pid= | sed 's/^/-p /' | xargs strace
ps auxw | grep sbin/apache | awk '{print"-p " $2}' | xargs strace
ps auxw|grep bin/apache | awk '{print $2":"$10}'|awk -F ':' ' {print "-p "$1}'|xargs strace