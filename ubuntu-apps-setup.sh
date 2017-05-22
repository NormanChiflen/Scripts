#!/bin/sh
###############################################
# Ubuntu 13.04 AutoSetup script
# Author: Neal Buerger (www.nealbuerger.com)
################################################
#
# Installs Eclipse, VLC, Chrome, Skype
# Removes Games, Amazon Search Integration, Ubuntu One, Rhythmbox, Firefox
# Updates all Packages
#
###############################
#To run script
#
# add executable permission to file:
# chmod +x autosetup.sh
# Run Script with:
# sudo ./autosetup.sh
###############################
 
########################
# Install Applications #
########################
printf "Eclipse \n"
sudo apt-get install -y eclipse
 
printf "vlc \n"
sudo apt-get install -y vlc
 
printf "Chrome \n"
sudo apt-add-repository -y 'deb http://dl.google.com/linux/chrome/deb/ stable main'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get install -y google-chrome-stable
 
printf "Skype \n"
wget http://www.skype.com/go/getskype-linux-beta-ubuntu-64
sudo dpkg -i getskype-*
sudo apt-get -f install
 
##################
#remove packages #
##################
printf "remove games \n"
sudo apt-get remove -y --purge aisleriot gnome-sodoku gnome-mines
 
printf "remove amazon integration"
sudo apt-get remove -y unity-lens-shopping
 
printf "remove ubuntu one"
sudo apt-get remove -y ubuntuone-client-proxy ubuntuone-control-panel-qt ubuntuone-client-gnome
sudo apt-get purge -y ubuntuone-client python-ubuntuone-storage*
sudo apt-get remove -y rhythmbox-ubuntuone
 
printf "remove rhythmbox"
sudo apt-get remove -y rhythmbox
 
#remove firefox
sudo apt-get -y purge firefox firefox-globalmenu firefox-gnome-support
 
 
##################
# update dist    #
##################
sudo apt-get update
sudo apt-get -y dist-upgrade