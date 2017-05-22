# Install Omnibus Chef
curl -L https://www.opscode.com/chef/install.sh | bash

# Create Chef Solo Config
mkdir -p /etc/chef/
cat <<EOBM > /etc/chef/solo.rb
file_cache_path "/var/chef-solo/cache"
cookbook_path ["/var/chef-solo/cookbooks", "/var/chef-solo/site-cookbooks"]
role_path "/var/chef-solo/roles"
data_bag_path "/var/chef-solo/data_bags"
EOBM

# Clone Chef Cookbooks for chef-solo
rm -rf /var/chef-solo
/usr/bin/git clone http://<git-server>/git/chef.git /var/chef-solo

# chef solo needs fqdn to be set properly
# something that can't be guaranteed during install
/bin/hostname localhost

# Run Chef solo
/opt/chef/bin/chef-solo \
    -o 'recipe[acme::cobbler-install]'
    -c /etc/chef/solo.rb \
    -L /var/log/chef-client.log