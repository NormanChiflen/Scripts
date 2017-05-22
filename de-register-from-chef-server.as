#When the instance is being shutdown either manually or automatically it needs to deregister it’s self with the Chef Server to keep things tidy.

#!/bin/bash

function getmeta() {
  wget -qO- http://169.254.169.254/latest$1
}

hostname="$(getmeta /meta-data/local-hostname)"

/usr/local/bin/knife node delete -y -c /etc/chef/knife.rb $hostname
/usr/local/bin/knife client delete -y -c /etc/chef/knife.rb $hostname

#Get the FQDN of the EC2 instance and perform some knife commands to delete the node and client from the Server. This script would be added to the relevant RC runtimes for when the instance is being shutdown.