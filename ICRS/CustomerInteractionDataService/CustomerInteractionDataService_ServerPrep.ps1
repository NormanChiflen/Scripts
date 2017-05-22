#################################################################################################################################################
#                  Script for setting up blank CustomerInteractionDataService IIS server                                    					#
#                                                                                                   											#
#                     v0.1 Copied and heavily modified by Michael Craig                             											#
#							-- Using Voyager_prep_step1-server.ps1 as source                        											#
#  Scripts available here: p1986\sait\DeploymentAutomation\CustomerInteractionDataService\CustomerInteractionDataService_ServerPrep.ps1      	#
#################################################################################################################################################
# 
# Script is designed to be exectuted Locally on the server.
#
#
# The "default web site" will be Stopped and it's physical path set to $webroot
# An ApplicationPool (named $WebSiteName) and Virtual Directory (named $WebSiteName) will be created in the path $webroot\$WebSiteName
#
#


param([string]$environment=$(throw 'Missing -environment parameter'), [string]$WebVDirName=$(throw 'Missing -WebVDirName parameter'), [string]$WebAppName="CustomerInteractionDataService", [string]$WebSiteName=$WebAppName, [string]$webroot="d:\webroot")

Import-Module ..\..\lib\Functions_common.psm1 -verbose -Force
Import-Module ..\..\lib\CustomerInteractionDataService_Functions.psm1 -verbose -Force

# logroot is as per spec
$logroot = "e:\logroot"
$webroot_archive = $webroot + "_archive"

# STEP 1 - Environment setup.
Test-Administrator

# Time executiong of the script started - for unique logging per script execution
if($StartTime){ setStartTime $StartTime }

#Create CCT Ops share for centralized file storage and such
$cctshare="c:\cct_ops"
IF (!(TEST-PATH $cctshare)){MD $cctshare}

#Set up the logroot folder, if not exist
CreateLogrootShare $logroot

#If current share for webroot exists, get the physical path and use for $webroot
if(test-path \\$env:computername\webroot) {
		$webroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT'").path
}

# Test if $webroot physical drive exists
if (!(Test-Path (split-path $webroot -qualifier))){
	 LogMessage "error" "Specify valid webroot argument. Drive/Path of webroot does not exist: " + $webroot
}else{
	#Set up the webroot folder, if not exist
	IF (!(TEST-PATH $webroot)){MD $webroot}
}


#Set up the webroot_archive folder, if not exist
if ($webroot_archive -eq (Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT_ARCHIVE'").path) { $webroot_archive }else{$webroot_archive}
IF (!(TEST-PATH $webroot_archive)){MD $webroot_archive}

# Set up file shares
if(!(test-path \\$env:computername\logroot)){	
	net share logroot=$logroot
}
if(!(test-path \\$env:computername\webroot)){	
	net share webroot=$webroot
}
if(!(test-path \\$env:computername\webroot_archive)){	
	net share webroot_archive=$webroot_archive
}

# Is execution policy set to restricted? Attempt to set 
Set-ExecutionPolicyUnrestricted

#load system modules
LoadAllModules

new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force


# STEP 2 - Loading config file (hard coded since there will be one shared across environments)
$defaultconfig ="environments.csv"
$DefaultCSV=Import-Csv .\$defaultconfig

#Was anything specified for environment?
  if($environment -eq "")
	  {Write-host -f yellow "Deployment environment not specified. ";
		 write "example:  Script_name.ps1 Test01"; 
		 write "list of all available environments in the config."
		 foreach($i in $DefaultCSV){write $i.environment};break}
  else {"Executing script for $environment"}

#Write-Host "Press any key to continue ..."
#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


#Testing if specified value exists in environments.
 if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
	 {"environment "+$environment+" not found in the $Defaultconfig"
	 write "list of all available environments in the config."
	 foreach($i in $DefaultCSV){write $i.environment};break}

#Finding values for correct environment.
 $arrayposition=-1    
 Foreach($i in $DefaultCSV){
 $arrayposition++
 if ($i.environment -eq $environment)
	 {$EnvironmentServers= $i.ServersInEnvironment.split(";")
	 $IISCertificatePath = $i.IISCertificatePath
	 $IISCertificatePwd = $i.IISCertificatePwd
	 $appPoolUser = $i.AppPoolUser
	 $appPoolPassword = $i.AppPoolUserPassword
	 $i.AppPoolUserPassword='************'
	 $arrayposition
	 write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
	}

# STEP 3 - install IIS
write-host -f cyan "Installing IIS"
InstallIIS-SetDefaultConfiguration

# Step 3.1 - Disable SSL 2.0
DisableSSL20

# Step 3.2 - Disable EI ESC
Disable-InternetExplorerESC

#Confirm .Net Framework 4.0 is installed
TestAndInstalldotNet40

# Register ASP.net
C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i
C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -ga $AppPoolUser

# Disable IIS Logging
write-host -f cyan "Enable IIS Logging"
DisableIISLogging


# STEP 5 - Install server level cert
write-host -f cyan "Installing Certs"

#
# Should still install Cert
#


# actually installing the cert. () are to display output instead of just processing it.
($iiscert=certinstallloop $iisPfxCertPass $iisPfxcertname)
# saving the cert name for setting up Voyager portion (mostly to assign ngat app pool to e:\ngat)
$iiscert | out-file c:\cct_ops\iis_cert.txt
Write-Host -ForegroundColor Green "Cert name saved to a local file in C:\cct_ops\iis_cert.txt"

#($provcert=certinstallloop $ProvisioningCertPass $ProvisioningCertPath)
#$provcert | out-file c:\cct_ops\prov_cert.txt # test code
#Write-Host -ForegroundColor Green "ProvisioningCert name saved to a local file in C:\cct_ops\prov_cert.txt"

# Grant 
#..\bin\winhttpcertcfg.exe -g -c LOCAL_MACHINE\My -s $ProvisioningCertName -a $AppPoolUser

# collect thumbprints for the certs.
#write-host -f cyan "collect thumbprints for the Provisioning cert."
#$ProvisionCertThumb_installed=($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -match $ProvisioningCertName})
#if ( $ProvisioningCertThumbprint -ne $ProvisionCertThumb_installed.Thumbprint ) {write-error "Installed Provisioning Cert Thumbprint does not match Environments.csv expected thumbprint"}

# Step 6 - apply rights to temp folder
#icacls $env:SystemRoot\temp /grant:R $AppPoolUser:R

# Step 7 -  Create Site & Application pools
#write-host -f cyan "Deleting NGAT website, NGAT App Pool and Application in case they're here"

# STEP 6 - Assign IIS users & AppPools to cert
# write-host -f cyan "Applying security to Cert"
## username - ngat\apppool  - cant do NGAT app pool until NGAT is deployed.
# $uname="$AppPoolUser"
# $keyname=$ProvisionCertThumb_installed.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
# $keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
	# write-host -f cyan "before change"  #debug code
	# icacls $keypath$keyname #debug code
# write-host -f cyan "after change"
# icacls $keypath$keyname /grant:r $uname":R"
# icacls $keypath$keyname #debug code


# STEP 7 - Enable PS Remoting on system
write-host -f cyan "Enable PS Remoting on system"
pushd wsman::localhost\client 
Set-Item TrustedHosts * -Force
Set-Item AllowUnencrypted True -Force
Enable-PSRemoting -Force
test-wsman -ComputerName $env:computername -Authentication none
if ($? -eq $false){Write-Host "Enable PSRemoting failed."}
popd


#  - CreateEventLogSource
#..\bin\CreateEventLogSource.exe RollCall

# Stop Default Web Site
if ((Test-Path("IIS:\Sites\Default Web Site"))) { 
	Stop-Website -Name "Default Web Site" 
}

# Create New "CustomerInteractionDataService web site
if (!(Test-Path("IIS:\Sites\$WebSiteName"))) {
	#Create Site
	New-Website -Name $WebSiteName -port 80 -PhysicalPath $webroot 
}else{
	#Set Site physical path and properties
	Set-ItemProperty "IIS:\Sites\$WebSiteName" -Name physicalPath -value "$webroot"
}

# Create New "CustomerInteractionDataService" ApplicationPool
if (!(test-path IIS:\AppPools\$WebAppName)) {New-Item "IIS:\AppPools\$WebAppName" -force}
Set-ItemProperty "IIS:\AppPools\$WebAppName" managedRuntimeVersion v4.0

# Create New "CustomerInteractionDataService web application
if (!(Test-Path("IIS:\Sites\$WebSiteName\$WebAppName"))) {
	#Create Site
	New-WebApplication -Site $WebSiteName -Name $WebAppName -PhysicalPath "$webroot\$WebSiteName" -ApplicationPool $WebAppName -force
}else{
	#Set Site physical path and properties
	Set-ItemProperty "IIS:\Sites\$WebSiteName\$WebAppName" -Name physicalPath -value "$webroot\$WebSiteName\"
}

# Stop site, if it is started
("$WebSiteName") | %{ if ((gi "IIS:\Sites\$_").State -eq "Started")  { (gi "IIS:\Sites\$_").Stop() }; "$_ is " + (gi "IIS:\Sites\$_").State }

# Remove all site bindings
Get-WebBinding -Name $WebSiteName | Remove-WebBinding

# Add Site Binding for :443 only
New-WebBinding -Name $WebSiteName -Port 443 -IPAddress * -Protocol https
if (!(test-path IIS:\SslBindings\0.0.0.0!443)) { Get-ChildItem cert:\LocalMachine\MY | ?{$_.Subject -match "\*.karmalab.net"} | New-Item IIS:\SslBindings\0.0.0.0!443 }

#Set up virtual directory
CreateSiteVdir $WebRoot  $WebSiteName $WebAppName $WebVDirName $appPoolUser $appPoolPassword

("$WebSiteName") | %{ if ((gi "IIS:\Sites\$_").State -eq "Stopped")  { (gi "IIS:\Sites\$_").Start() }; "$_ is " + (gi "IIS:\Sites\$_").State }

# Testing if reboot is required
write-host -f cyan "Testing if reboot is required"

# Set extended properties for HTTPErr
EnableExtendedHTTPErrAttributes

set_enableVersionHeader_false

# Force reboot to enable HTTPErr configuration
RebootRequired("True")