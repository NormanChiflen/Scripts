#!/usr/bin/env bash
echo Starting to provision server with role: $1
 
echo -e "\nInstalling and bootstrapping chef-solo..."
 
apt-get -y update
apt-get --no-install-recommends -y install build-essential ruby ruby-dev rubygems libopenssl-ruby
gem install chef ruby-shadow --no-ri --no-rdoc
echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/lib/gems/1.8/bin"' > /etc/environment
 
echo -e "\nRunning chef provisioning script..."
 
#chef solo ruby file
echo "file_cache_path \"/tmp/chef\"
cookbook_path \"/tmp/chef/cookbooks\"
role_path []
log_level :debug" > ./solo.rb
 
chef-solo -c /tmp/chef/solo.rb -j /tmp/chef/$1.json -r /tmp/chef/cookbooks.tgz && rm -r -f * && touch provisioned

