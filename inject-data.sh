how we inject our data and the simple format we use:

#!/bin/bash
echo "boot = 1" >> /home/fedora/cloud-build.data
echo""satserver=1" >> /home/fedora/cloud-build.data
echo "hostname = web4.cloud.lab" >> /home/fedora/cloud-build.data
echo "pkgs = httpd|vim|php|mod_ssl" >> /home/fedora/cloud-build.data
echo "users = Tim|Jerry|Linda" >> /home/fedora/cloud-build.data
echo "update = 1" >> /home/fedora/cloud-build.data
echo "mail = 1" >> /home/fedora/cloud-build.data