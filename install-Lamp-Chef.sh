#download chef-solo from github.

 curl -L https://www.opscode.com/chef/install.sh | bash

chef-solo -v

wget http://github.com/opscode/chef-repo/tarball/master

tar -zxf master

mv opscode-chef-repo* chef-repo

rm master

cd chef-repo

ls

# specify the cookbook path under .chef directory in knife.rb file.
mkdir .chef

echo "cookbook_path [ '/root/chef-repo/cookbooks' ]" > .chef/knife.rb

# Create any cookbook via knife e.g phpappknife cookbook create phpapp
 cd cookbooks/phpapp
ls
cd ..

# install apache
knife cookbook site download apache2

 tar zxf apache2*

 rm apache2*.tar.gz

 knife cookbook site download apt

 tar zxf apt*

 rm apt*.tar.gzbelow line

 knife cookbook site download iptables

 tar zxf iptables*

 rm iptables*.tar.gz

 knife cookbook site download logrotate

 tar zxf logrotate*

 rm logrotate*.tar.gz

 knife cookbook site download pacman

 tar zxf pacman*

 rm pacman*.tar.gz

 cd phpapp

 
 # Open metadata.rb , add below line

# depends “apache2?

# Open recipes/default.rb , add below lines

# include_recipe “apache2?

 # apache_site “default” do

  # enable true

# end
cd ../..

Create a new file called solo.rb in your text editor & make below entries

file_cache_path “/root/chef-solo”

cookbook_path “/root/chef-repo/cookbooks”

This file configures chef-solo, telling it where to keep its cache of files and where our cookbooks are.

Now create a file called web.json & add below lines

{

“run_list”: [ "recipe[apt]“, “recipe[phpapp]” ]

}

Why have we not included the apt cookbook inside our recipe as we did with the apache2 cookbook? It’s because our PHP application requires Apache to function but we don’t necessarily want to tie our cookbook to platforms that only support apt.

chef-solo -c solo.rb -j web.json


open the page in browser it will show default page for apache.


#Installing mysql
cd cookbooks
knife cookbook site download mysql
tar zxf mysql*
rm mysql-*.tar.gz
cd mysql/recipes/
ls
 cd ../../phpapp

 
 Open metadata.rb, add below lines

depends “mysql”

Open recipes/default.rb , add below lines

include_recipe “apache2?

include_recipe “mysql::client” —- This to be added

include_recipe “mysql::server”   —- This to be added

apache_site “default” do

  enable true

end

Run chef-solo again

cd ../..
chef-solo -c solo.rb -j web.json


You will now get errors like

FATAL: Stacktrace dumped to /root/chef-solo/chef-stacktrace.out

FATAL: Chef::Exceptions::CookbookNotFound: Cookbook build-essential not found. If you’re loading build-essential from another cookbook, make sure you configure the dependency in your metadata

Open cookbooks/mysql/metadata.rb & specify the dependencies

depends “openssl”

depends “build-essential”
root@ankush:~/chef-repo# cd cookbooks

root@ankush:~/chef-repo/cookbooks# knife cookbook site download openssl

root@ankush:~/chef-repo/cookbooks# tar zxf openssl*.tar.gz

root@ankush:~/chef-repo/cookbooks# rm openssl*.tar.gz

root@ankush:~/chef-repo/cookbooks# knife cookbook site download build-essential

root@ankush:~/chef-repo/cookbooks# tar zxf build-essential-*.tar.gz>

root@ankush:~/chef-repo/cookbooks# rm build-essential-*.tar.gz


root@ankush:~/chef-repo/cookbooks# cd ..

root@ankush:~/chef-repo# chef-solo -c solo.rb -j web.json

Open web.json to specify the mysql root password

{

“mysql”: {“server_root_password”: “ankush”, “server_debian_password”: “ankush”, “server_repl_password”: “ankush”},

“run_list”: [ "recipe[apt]“, “recipe[phpapp]” ]

}

chef-solo -c solo.rb -j web.json

cd cookbooks/
2	 
3	root@ankush:~/chef-repo/cookbooks# knife cookbook site download php
4	 
5	root@ankush:~/chef-repo/cookbooks# tar zxf php*.tar.gz
6	 
7	root@ankush:~/chef-repo/cookbooks# rm php*.tar.gz


The php cookbook depends on the xml, yum-epel, windows, and iis cookbooks, so we’ll need those even though we won’t be using all of them. We’ll also have to install sub-dependencThe php cookbook depends on the xml, yum-epel, windows, and iis cookbooks, so we’ll need those even though we won’t be using all of them. We’ll also have to install sub-dependencies yum (a dependency of yum-epel), chef_handler, and powershell (dependencies of windows).ies yum (a dependency of yum-epel), chef_handler, and powershell (dependencies of windows).


root@ankush:~/chef-repo/cookbooks# knife cookbook site download xml

root@ankush:~/chef-repo/cookbooks# tar zxf xml-*.tar.gz

root@ankush:~/chef-repo/cookbooks# knife cookbook site download yum

root@ankush:~/chef-repo/cookbooks# tar zxf yum-*.tar.gz

root@ankush:~/chef-repo/cookbooks# knife cookbook site download yum-epel

root@ankush:~/chef-repo/cookbooks# tar zxf yum-epel-*.tar.gz

root@ankush:~/chef-repo/cookbooks# knife cookbook site download powershell

root@ankush:~/chef-repo/cookbooks# tar zxf powershell-*.tar.gz

root@ankush:~/chef-repo/cookbooks# knife cookbook site download iis

root@ankush:~/chef-repo/cookbooks# tar zxf iis-*.tar.gz

root@ankush:~/chef-repo/cookbooks# rm *.tar.gz


cd phpapp


Open metadata.rb add below line

depends “php”

Open recipes/default.rb , add below lines

include_recipe “php”

include_recipe “php::module_mysql”

include_recipe “apache2::mod_php5?

Save the file and we’re good to run chef-solo again to install all of those things


cd ../..
chef-solo -c solo.rb -j web.json

So that’s PHP installed. Let’s confirm that by creating a test page. Open /var/www/test.php in your editor.

<?php phpinfo(); ?>

Now goto http://yourserver/test.php , you will see the phpinfo page.

