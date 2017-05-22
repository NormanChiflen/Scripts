##########################################################################################
#                  Script for setting up Voyager IIS once server has been configured     #
#                                                                                        #
#                     v1.4 Crude but effective by Alex Vinyar                            #
#  Scripts available here: //sait/DeploymentAutomation/Voyager_IIS/Deployment/           #
##########################################################################################
# 
# Script is designed to be exectuted Locally on the server.
# 

param([string]$environment="none",$buildversion="none" )

##Loading common functions
Import-Module ..\..\lib\Functions_common.psm1 -verbose -Force


#variables:
$buildstorage = "\\chc-filidx\cctss\Voyager\Web_UI"  								# prod - NGAT_00.001.0012.23971
$buildstorage = "\\karmalab.net\builds\directedbuilds\sait\CRM\products\ngat"       # Test
$envusername="expeso\_voyager"
$envusername="karmalab\_crmdev"
$ngatshare="E:\NGAT"

# STEP 1 - Environment setup.
write-host -f Magenta "Environment setup."
## - Alex - 12/26/2012 - now consuming from common function
EnvironmentPrep

#write-host -f cyan "Testing if User is an administrator."
# function Test-Administrator{
	# $user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	# (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
#$a=Test-Administrator
#if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

# Time executiong of the script started - for unique logging per script execution
$installtime=get-date -uformat "%Y_%h_%d_%H_%M"

## - Alex - 12/26/2012 - now consuming from common function
# Is execution policy set to restricted? Attempt to set 
#write-host -f cyan "Testing execution policy."
#try {Set-ExecutionPolicy bypass -scope localmachine -force}
#catch { "Unable to set Group Policy"}
#$a=Get-ExecutionPolicy
#if ($a -eq "Restricted"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy "
#break}

#load system modules
#Get-Module -listavailable| foreach{write-host -ForegroundColor Cyan loading $_.name; Import-Module $_.name}
Import-module webadministration,ServerManager

# Set appcmd Alias
write-host -f cyan "Seting appcmd Alias"
new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force



# commented out on April 6 2012 by alex - not needed due to voyager_iis_upgrade_only script
# STEP 2 - Loading config file and validating user input (hard coded since there will be one shared across environments)
	# write-host -f magenta "Loading config file and validating user input"
	# $defaultconfig ="environments.csv"
	# $DefaultCSV=Import-Csv .\$defaultconfig


# commented out on April 6 2012 by alex - not needed due to voyager_iis_upgrade_only script
#Was anything specified for environment?
#if($environment -eq "none")
#if($environment -eq "none" -or $buildversion -eq "none"){
	Write-host -f yellow "Deployment environment or build version not specified. ";
	Write-host -f yellow "you executed: script.ps1 $environment $buildversion"
	write "**********************************************************"
	write "                                                          "
	write "                    Warning !!!!                          "
	write " This script will blow away NGAT folders and remake them  "
	write "                                                          "
	write "**********************************************************"

#	foreach($i in $DefaultCSV){write $i.environment};
#	write-host -f yellow "list of available build versions: 0.5, 0.6"
#	dir $buildstorage; break
#	}else {
#	write-host -f cyan "Executing script for Environment: $environment Build version: $buildversion"}

# commented out on April 6 2012 by alex - not needed due to voyager_iis_upgrade_only script
#Testing if specified value exists in environments.
#if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
#	{write-host -f yellow "environment " $environment " not found in the $Defaultconfig"
#	write "list of all available environments in the config."
#	foreach($i in $DefaultCSV){write $i.environment};break}

#if(!(test-path $buildstorage\$buildversion*)){"path not found, please make sure $buildstorage\Release_$buildversion exists"; break
#	}else{
	#manual work around against network hickups.
#	$r=1..3;$r|foreach{
#		$buildnumber = gci $buildstorage\$buildversion* | sort $_.name | select -last 1
#		start-sleep 1
#		write "Searching for the latest build..."}
#	write-host -f cyan "build number: $buildnumber"	
#	}

# commented out on April 6 2012 by alex - not needed due to voyager_iis_upgrade_only script
#Loading values for correct environment.
# $arrayposition=-1    
# Foreach($i in $DefaultCSV){
# $arrayposition++
# if ($i.environment -eq $environment)
	# {$EnvironmentServers= $i.Servers_in_Environment.split(";")
	# $tokenproviderURL	= $i.Token_Provider_Url
	# $CertName			= $i.Cert_Name
	# $EndpointURL		= $i.End_Point_URL
	# $App_Fabric_Cache	= $i.App_Fabric_Cache
	# $App_Fabric_Hosts	= $i.App_Fabric_Hosts.split(";")
			## - stay commented out - $App_Fabric_Hosts_h= @{};foreach($r in $i.App_Fabric_Hosts.split(";")){$App_Fabric_Hosts_h.add($r,"22233")}
	# $ADFSUrl			= $i.ADFS_Url
	# $SSLThumbprint		= $i.SSLThumbprint
	# $TrustURL			= $i.TrustURL
	# $iiscertname		= $i.PFXfilename
	# $iiscertpass		= $i.PFXPassword
	# $arrayposition
		# write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
	# }



	
#Add some logic to see if website exists, if not create it. - for now its safe to assume that most websites use wrong settings, so it's ok to remake them.
#$w=get-website
# if $w.name = ngat (what is idle timeout)
# if idle timeout -ne 240, wipe the website and create from scratch


# STEP 3 - Deleting NGAT Website and folder and recreating
#Step 3a - Make sure IIS is running
write-host -f cyan "Starting IIS service if not running"
if (($s=get-service w3svc).status -ne "running"){Start-Service -name w3svc}else{write-host -f cyan $s.name $s.status}

write-host -f cyan "Deleting NGAT website, NGAT App Pool and Application in case they're here"
appcmd delete app "ngat/"
appcmd delete site "ngat"
appcmd delete apppool "ngat"

# STEP 3b - Deleting NGAT folder.
write-host -f cyan "Deleting NGAT folder"
if (Test-Path e:\ngat) { rd e:\ngat -recurse -force }


# STEP 4 - Setting up websites.
# Creating NGAT Website, App Pool and Application
write-host -f magenta "Creating NGAT Website, App Pool and Application"
Write-host -f cyan "Setting up App Pool"
type NGAT_AppPool_config_basic.xml | appcmd add apppool /in
Write-host -f cyan "Setting up NGAT Website and Application"
type NGAT_site_config_full.xml | appcmd add site /in
#type NGAT_App_config_full.xml |  appcmd add app /in    -  created as part of Site

	

# STEP 4a - Create NGAT folders
write-host -f Cyan "Creating NGAT Folders and Granting permissions"
$folderlist=$ngatshare,"$ngatshare\EndCall","$ngatshare\EndCall\Drop","$ngatshare\EndCall\Temp","c:\cct_ops"
$folderlist |foreach {IF (!(TEST-PATH $_)){MD $_}}
#cleanup rd e:\ngat -recurse

# STEP 4b - Grant permissions
write-host -f Cyan "Grant permissions to folders"
net share ngat=$ngatshare "/grant:$envusername,full"
icacls $ngatshare /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)(RX)"
icacls $ngatshare /grant:r "IIS APPPOOL\DefaultAppPool:(OI)(CI)(RX)"
icacls $ngatshare /grant:r "IIS APPPOOL\NGAT:(OI)(CI)(F)"
icacls $ngatshare /grant:r "SEA\s-tfxlabrun%:(OI)(CI)(RX)"

# STEP 4c - Granting AppPool\NGAT access to the cert.
#  Collecting Cert for IIS
write-host -f cyan "collect Cert name for the IIS cert."
if(!(test-path c:\cct_ops\iis_cert.txt)){
	write-host -f red "iis_cert.txt is not found in C:\cct_ops. Please run Server Prep script or manually populate the file..... "
	write-host -f red "Coninuing with Errors..."
}ELSE{
	$iiscert= gc c:\cct_ops\iis_cert.txt
	($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})
	}


# STEP 4d - Granting IIS apppool\ngat read access to the cert
write-host -f cyan "Granting IIS apppool\ngat read access to the cert."
$uname="IIS APPPOOL\NGAT"
$keyname=$a.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
write-host "before change";icacls $keypath$keyname       #debug code
icacls $keypath$keyname /grant:r $uname":R"
write-host "";"";"after change";icacls $keypath$keyname  #debug code




# STEP 5 - Assign cert to the NGAT website
write-host -f cyan "Assign cert to the NGAT website"
Stop-Website "default web site"
Remove-WebBinding -Name "NGAT" -IP "*" -Port 443 -Protocol https
if (Test-Path "IIS:\SslBindings\0.0.0.0!443") { remove-item "IIS:\SslBindings\0.0.0.0!443" }
#   Create a binding on 443 with cert from above
New-WebBinding -Name "NGAT" -IP "*" -Port 443 -Protocol https
#   Set thumbprint for specific cert
Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | New-Item IIS:\SslBindings\0.0.0.0!443



#	#Creating backup of existing Web.Config
#	$webConfig = "E:\NGAT\web.config"
#	Write-host -f cyan "Creating backup of existing Web.Config to: "$webConfig"_backup_$installtime"
#	$webconfig | Set-Content e:\$webConfig+"_backup_"+$installtime



# commented out on April 6 2012 by alex - not needed due to voyager_iis_upgrade_only script
# STEP 6 - Deploy NGAT
# Write-host -f Magenta "Deploying NGAT";""
# Stop-Website "NGAT"
# write-host -f cyan " $buildnumber"
# robocopy $buildnumber\deliverables $ngatshare *.* /E /XA:H /PURGE /XO /XD ".svn" /NDL /NC /NS /NP /R:5 /W:5 /IS
# write-host -f cyan "build number: $buildnumber"
# write-host -f yellow " Errorlevel: $LASTEXITCODE   0 or 1 = ok"

#setting version number in Version.txt
#$buildnumber | out-file "$ngatshare\Version.txt"


#Set up the logroot folder, if not exist
#if ($logroot -eq (Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path) { $logroot }else{$logroot="d:\logroot"}
$logroot = "d:\logroot"
if ((Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path -eq $null) {
	write-warning 'Missing a Logroot Folder. Creating a Logroot folder, and map share as \\ServerName\logroot'
	If (!(TEST-PATH $logroot)){MD $logroot}	
	If(!(test-path \\$env:computername\logroot)) {
		net share logroot=$logroot
	}
	
}else{
	$logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path
}
IF (!(TEST-PATH $logroot)){MD $logroot}



############################################
write-host ############################################
write-host -f magenta "To update web.config and to capture the latest changes please run Voyager_upgrade_IIS_only.ps1"
write-host "Execute adding ADFS claims on ADFS server to allow this server login authentication";"";""
write-host ############################################
############################################

# Write-host -f cyan "Starting NGAT Website"
# Start-Website "NGAT"

# pushd $ngatshare
# Write-host -f Magenta "Running CreateEventLogSource.exe "
# .\CreateEventLogSource.exe 'Expedia.ContactCenter.NGAT'


Write-host -f cyan "                 *********************************"
Write-host -f Yellow "Setup Complete, please scroll up and Examine output for errors."
Write-host -f cyan "                 *********************************"

# remotely execute adding ADFS claims on ADFS server
# test server hash table

