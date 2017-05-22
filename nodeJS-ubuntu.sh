I had to upgrade to 12.10 Quantal Quetzal to get a recent enough set of nodejs packages for this to work.

# First install nodejs and the the nodejs package manager
sudo apt-get install nodejs npm
# The Amateur Radio 'node' package installs /usr/sbin/node, so nodejs installs /usr/bin/nodejs on Debian/Ubuntu. Node scripts don't like this.
sudo ln -s /usr/bin/nodejs /usr/bin/node
#Now install the azure tools using NPM
sudo npm install azure-cli -g

# Get your azure credentials with the link provided
azure account download
# Import these credentials
azure account import foo-credentials.publishsettings
# Get a list of VM images
azure vm image list
# Get the list of hosting locations
azure vm location list
# Create an instance. Change UNIQUE_SERVERNAME and USERNAME to your fitting.
azure vm create UNIQUE_SERVERNAME CANONICAL__Canonical-Ubuntu-12.04-amd64-server-20120924-en-us-30GB.vhd USERNAME --location "East US" --ssh
azure vm start UNIQUE_SERVERNAME
ssh USERNAME@UNIQUE_SERVERNAME.cloudapp.net