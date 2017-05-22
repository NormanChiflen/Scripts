# WebService Install Only
#	
#	Assumption:
#	: The server prep script for ADFS (MPADFS) has already been run. This service is deployed on a standalone ADFS instance.
#	
#	: Used to Deploy the Merchant Point Provisioning Service
#	: A copy of this script has been manually copied to \\Cheladfsmtp001.cctlab.expecn.com\c$\cct_ops\MPDeploy
#	: To remain 'stand alone' it also has it's own copy of .\lib\functions_common.ps1 which it relies on
#
#
#
# MerchantPoint Provisioning Service Deployment:

# •	Log into deploymnet server  (eg. cheladfsmtp001)
# •	Open Powershell as Administrator
# •	net use * \\chelapperp01.karmalab.net\c$ /u:sea\USERNAME *
# 	• (eg. net use the root folder containing the build)
# •	cd C:\cct_ops\MPDeploy
# •	Execute: .\ProvisioningService_Install.ps1
# •	When prompted, answer Dev or Prod for install version to use




param([string]$environment="none")

# Import common functions
ImportSystemModules
Import-Module .\lib\Functions_common.psm1 -verbose -Force

#variables:
$appname			= "MPProvisioningService"
$BuildLabel			= $appname + "_" + $buildversion
if ($logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path) { $logroot }else{$logroot="d:\logroot"}
if ($webroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT'").path) { $webroot }else{$webroot="e:\webroot"}

$logroot_install	="$logroot\install"
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"
$ServerName			="$env:ComputerName"
$webroot_backup	    ="d:\webroot_archive"
$webConfig			="$webroot\web.config"
$AppPoolName		=$appname
$EmailTO            ="vcirel@expedia.com"
$EmailFROM          ="MPProvisionInstall@expedia.com"
$appPoolUser        ="cctlab\s-adfsmp"
$appPoolUserPassword="Password1!"
$DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain

Test-Administrator

# Select which build to install
do{
	Write-host "Which build do you want to install, Dev or Prod?"
	$environment= Read-Host 
	
}while(@("dev", "prod") -notcontains $environment)


$buildStorageRoot   = "\\chelapperp01.karmalab.net\c$"

if ($environment -eq "prod"){ $buildstorage=".\webroot\FSR034\merch\prod\MPProvisioningService"}
if ($environment -eq "dev"){ $buildstorage=".\webroot\FSR034\merch\dev\MP"}


If($DnsDomain -match "cct.expecn.com"){
	$versionTxt			="version.txt.config"
	$historyTxt			="History.txt.config"
	}Else{
	$versionTxt			="version.txt"
	$historyTxt			="History.txt"
}



# Step 1b - Is execution policy set to restricted? Attempt to set 
Set-ExecutionPolicyUnrestricted

# Step 2f - Verify build location
write-host "Getting build location"
pushd $buildStorageRoot

if(!(test-path $buildstorage)){
	Write-error "Path not found, please make sure $buildstorage exists"
	break;
		}else{
		Write "Getting Build from: $buildStorageRoot"
		}
	

#Step 3 - Make sure IIS is running - known good
if (($s=get-service w3svc).status -ne "running"){Start-Service -name w3svc}else{
	write-host $($s.name + " " + $s.status)
	}

# Make sure AppPool is created
if (!(Test-Path "iis:\apppools\$AppPoolName")){ New-Item "IIS:\AppPools\$AppPoolName"}

# Stop Web AppPool
if ((Get-WebAppPoolState $AppPoolName).Value -ne "Stopped") {Stop-WebAppPool $AppPoolName}

# Make sure VDIR is created on Default Web Site
if (!(test-path "$webroot\$appname")){ md "$webroot\$appname" }

# Create AppPool and set to .net V4.0
New-Item "IIS:\Sites\Default Web Site\$appname" -physicalPath "$webroot\$appname" -type Application -force
Set-ItemProperty "IIS:\AppPools\$AppPoolName" managedRuntimeVersion v4.0

# Set app pool identity
$pool = Get-Item "IIS:\AppPools\$AppPoolName"
$pool.processModel.username = [string]("$appPoolUser")
$pool.processModel.password = [string]("$appPoolPassword")
$pool.processModel.identityType = "SpecificUser"
$pool | Set-Item


# Set apppool to vdir	
set-ItemProperty "IIS:\Sites\Default Web Site\$appname" -name applicationPool -value "$AppPoolName"
	
# STEP 6 - Start Deployment of App
Write-host "Starting deployment: $appname"

# Delete webroot Share to prevent open handles
if(test-path \\$ServerName\webroot){net share webroot /d /y 2>&1 | Out-Null}
if (!$?){
	write-host "Webroot could not be deleted. Trying $webroot.."
	net share webroot /d /y}else{
		write-host "Webroot share deleted"
		}

# Step 5 - Backup
Write-host "Back up current version"
if(!(test-path $webroot_backup)){md $webroot_backup}
	
if(test-path "$webroot\$appName"){	
	robocopy "$webroot\$appName" "$webroot_backup\$appName.$installTimeStamp" *.* /E /NP /NS /NFL /NDL
	Remove-item "$webroot\$appName" -recurse -force
	}else{Write-Warning "$webroot\$appName does not exist, nothing to back up."}


# Step 6a - Robocopy steps
$SourceDir= "$buildstorage"
$DestDir= "$webroot\$appname"

# Copy using Robocopy
write-host "robocopy $SourceDir $DestDir *.* /E /NP /NS /NFL /NDL"
robocopy $SourceDir $DestDir *.* /MIR

# Select web.config to use
if (Test-Path "$DestDir\config\web.config.$environment") 
	{ 
		copy "$DestDir\config\web.config.$environment" "$DestDir\web.config" -Force
		rd "$DestDir\config" -Force -Recurse
	}else{
		$a=(gci "$DestDir\config" -Recurse -Include "web.config") | %{$_.Name}
		#LogMessage "warn" (gci "$WebAppFilePath\configs" -Recurse -Include "web.config") | %{$_.Directory})
		LogMessage "error" "Must specify one of these valid environment names:`t $a`n`n" 
	}

# Step 6b - setting User and other info in Version.txt
write-host "setting User and version number in $versionTxt"



"<pre>"															| out-file "$DestDir\$versionTxt"
$buildpath														| out-file "$DestDir\$versionTxt" -append
[string]$currentuser=whoami
"Server:  $ServerName" 						                    | out-file "$DestDir\$versionTxt" -append
"Deployment executed by $currentuser on $installTimeStamp"	 	| out-file "$DestDir\$versionTxt" -append

# Step 6C - Creating History.txt file to keep track of ALL deployments ever done.
if (!(test-path "$webroot_backup\$historyTxt")){"<pre>"				| out-file "$webroot_backup\$historyTxt"}
"Build updated from $OldVersion to $buildnum by $currentuser on $installTimeStamp" | out-file "$webroot_backup\$historyTxt" -append
Copy-item "$webroot_backup\$historyTxt" "$DestDir\$historyTxt"

# STEP 8 - Post deployment steps.
write-host "Restarting AppPool"
if ((Get-WebAppPoolState $AppPoolName).Value -ne "Started") {Start-WebAppPool $AppPoolName}

#Recreating Webroot share
write-host "Recreating Webroot share"
$webRootShare = Split-Path -parent $webroot
if(!(test-path $webroot)){	
	net share webroot=$webRootShare
}
if(!(test-path $webroot_backup)){	
	net share webroot_backup=$webroot_backup
}

#Create Logroot share if not exist
if(!(Test-Path("\\$ServerName\logroot"))) { net share logroot=$logroot }

# Post deployment tasks - mostly cosmetic and usability
# Displays logs for the whole deployment making it a little easier to pull up other servers from inside a log.

write-host   "                 *********************************"
write-host   " Build updated from $OldVersion to $buildNum"
write-host   " Setup Complete, please scroll up and Examine output for errors."
write-host   " notes if any: "
write-host   " $notes "
write-host   "                 *********************************"
write-host   "                  THIS Server: $env:computername  "

#Sending email to person who ran deployment.

$emailbody = gc "$DestDir\$versionTxt"
popd
amail "$EmailFROM" @("$EmailTO") "$appname Deployment in $environment - $env:computername completed"  $emailbody 
