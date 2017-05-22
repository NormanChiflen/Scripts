#http://marksdevserver.com/2013/06/19/chef-bootstrap-autoscaled-ec2-instance/
#!/bin/bash

# The script is set to run at multiple RC runlevels so make sure it can only be ran once
if [ -f /etc/chef/chef-bootstrap.done ]
then
  exit
fi
touch /etc/chef/chef-bootstrap.done

# define a function for later use
function getmeta() {
  wget -qO- http://169.254.169.254/latest$1
}

# get EC2 meta-data
env=-
role=-

oldifs="$IFS"
IFS='&'
for datum in $(getmeta /user-data)
do
  case "$datum" in
    env=*) env=${datum#env=};;
    role=*) role=${datum#role=};;
  esac
done
IFS="$oldifs"

hostname="$(getmeta /meta-data/local-hostname)"

# write first-boot.json to be used by the chef-client command.
# this sets the ROLE of the node.
echo -e "{"run_list": ["role[$role]"]}" >> /etc/chef/first-boot.json

# write client.rb
# this sets the ENVIRONMENT of the node, along with some basics.
echo -e "log_level               :info" >> /etc/chef/client.rb
echo -e "log_location            STDOUT" >> /etc/chef/client.rb
echo -e "chef_server_url         'https://chef.domain.com'" >> /etc/chef/client.rb
echo -e "validation_client_name  'chef-validator'" >> /etc/chef/client.rb
echo -e "environment             '$env'" >> /etc/chef/client.rb

# append the node FQDN to knife.fb
echo -e "node_name               '$hostname'" >> /etc/chef/knife.rb

# run chef-client to register the node and to bootstrap the instance
chef-client -d -j /etc/chef/first-boot.json
