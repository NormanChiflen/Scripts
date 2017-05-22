#http://lucbei.wordpress.com/2011/11/01/team-foundation-server-2010-tfs-deployer-and-stuff/
#Files to copy
 
$Package_dir = ‘\\[IP]\builds\ProjCI\ProjCI_20111103.6\_PublishedWebsites\*’
 
$Dest = ‘D:\Test’
 
if ((Test-Path -path $Dest)  -ne $True)
 
{
 
New-Item $dest -type directory -force
 
}
 
Copy-Item $Package_dir $Dest -recurse -force
 

#Backup the IIS site
 & $MsDeploy_dir -verb:sync -source:appHostConfig=”TestSite” -dest:package=d:\IISArchive\$backupPkgName
 


#Install the deploy package
 & $localPackageDeployCmd “-setParam:name=’IIS Web Application Name’,value=TestSite” /y
 

 
 # Post Deployment======================================================
 
# There are some nifty things you can do post deployment.
 # ie. precompile IIS 7
 
# START C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_compiler.exe -v [app]
 # Encrypt web.config data
 # C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -pef “connectionStrings” “D:\wwwroot\[app]“
 # C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -pef “system.web/machineKey” “D:\wwwroot\[app]“
