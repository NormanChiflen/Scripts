#chef-clientrun.ps1

# install chef gem – This ensures only the latest stable version is installed

$installchef= “gem install chef –no-rdoc –no-ri”"

# Download userdata

$webclient = new-object system.net.webclient

$awsurl =”http://169.254.169.254/latest/user-data ”

$targetfile =”c:\chef\etc\runlist.json”

$webClient.DownloadFile(“$awsurl”,”$targetfile”)

# Run chef-client passing json file which contains runlist

$runchef = “C:\Ruby192\bin\chef-client -j”+  $targetfile

invoke-expression $installchef

invoke-expression $runchef