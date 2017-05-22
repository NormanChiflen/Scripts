######################################################################
#     Script for setting up Secondary ADFS on a brand new server     #
#                                                                    #
#              v2 Crude but effective by Alex Vinyar                 #
#     Scripts available here: p1986\sait\users\Automation\ADFS\      #
######################################################################

# This script expects to be either executed from "pushd \\CHELAPPSBX001.karmalab.net\DeploymentAutomation\Voyager_IIS\Deployment"
# Or as part of a copy of the whole DeploymentAutomation folder.

# Start Powershell with Modules (Run as Admin)
# The script must be executed from the same location as the config file.

Import-Module ..\lib\Functions_common.psm1 -Force
ImportSystemModules

#Environment variables
$dotNetInstall = "..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe"

#Start Logging
write-host -f cyan "Environment setup."
write-host -f cyan "Start Transcript."
try {stop-transcript}
catch { "Unable to Stop Transcript, probably already stopped"}
try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$pwd\ADFS_Installation_Secondary_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile}
catch { "Unable to Start Transcript"}

#Step 0 - Environment setup and Verification that everything is good.
# Is command window open as administrator?
write-host -f cyan "Testing if User is an administrator."
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

# Is execution policy set to restricted?
write-host -f cyan "Testing execution policy."
try {set-executionpolicy Bypass -force}
catch { "Unable to set Group Policy"}
$a=Get-ExecutionPolicy
if ($a -eq "Restricted"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy"
break}

#get current location
$script_location=$pwd

#Step 1 - Gathering inputs
#future version this will be a user input
$config_file='adfs_common_config.txt'
if(test-path -path $config_file){$allinputs=Import-Csv $config_file -Delimiter ~
$adfsacctname=$allinputs[0].value
$adfsacctpass=$allinputs[1].value
$iiscertname=$allinputs[2].value
$iiscertpass=$allinputs[3].value
$signcertname=$allinputs[4].value
$signcertpass=$allinputs[5].value
$deccertname=$allinputs[6].value
$deccertpass=$allinputs[7].value
$federationservicename=$allinputs[8].value
$primaryadfsservername=$allinputs[9].value
$Provisioningcert=$allinputs[10].value
$Provisioningpass=$allinputs[11].value
$AttribStoreSQL=$allinputs[12].value
$RollCallSQL=$allinputs[13].value
$RollCallDBName=$allinputs[14].value
$Identifiers=@(($allinputs[15].value).tolower().split(","))
Write-host -ForegroundColor Cyan "Input received"
} ELSE {
write-host -ForegroundColor Red "ERROR
$config_file was not in the same location as the script.";break}


#Test if cert files actually exist.
if(!(test-path -literalpath $iiscertname)){write-host  -ForegroundColor Red "$iiscertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$iiscertname - OK"}
if(!(test-path -literalpath $signcertname)){write-host  -ForegroundColor Red "$signcertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$signcertname - OK"}
if(!(test-path -literalpath $deccertname)){write-host  -ForegroundColor Red "$deccertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$deccertname - OK"}
if(!(test-path -literalpath $Provisioningcert)){write-host  -ForegroundColor Red "$deccertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$Provisioningcert - OK"}


# Step 2 - Install ADFS (iis/.net/wfi/powershell plugin)
write-host "Installing ADFS - process should take between 30 seconds to 10 minutes, depending on missing components"
$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
$ADFSlogfile="$pwd\ADFS_Setup_Secondary_$installtime.log"
$ADFSInstall = "AdfsSetup.exe"
$ADFSInstallParams = "/quiet /logfile $ADFSlogfile"
Start-Process $ADFSInstall $ADFSInstallParams -wait
if ((gc -path $ADFSlogfile | select-string -pattern "AD FS 2.0 is already installed on this computer") -eq $null){write-host -ForegroundColor Cyan "ADFS Installed"} Else{write-host -ForegroundColor Red "There was an error Installing ADFS, please check the log file: $ADFSlogfile"
write-host "last line of file: " (gc -path $ADFSlogfile | select -last 1)
break}

#step 3 - installing IIS Scripting
PKGMGR.EXE /l:log.etw /iu:IIS-ManagementScriptingTools

#step 3a - Install .Net 4.0
write-host -f cyan "Installing .NET 4.0 - process should take 5 to 10 minutes"
$dotNetlogfile="$pwd\dotNet4setup_$installtime.log"
$dotNetParams = '/q /norestart /log '+$dotNetlogfile
Start-Process $dotNetInstall $dotNetParams -wait
write-host -ForegroundColor Cyan ".Net 4.0 Installed.  Log file located here: $dotNetlogfile"

#Step 4 - Add certs to computer

#------------IIS Cert function ----------
function certinstallloop ($certpassin, $certnamein){
$certout=certutil -f -importpfx -p $certpassin $certnamein
	if($? -eq $false){write-host -f red "There was an error in installation of the cert:";"";$certout;break
	}else{
	$certout=($certout | select -first 1).replace('" added to store.',"").replace('Certificate "',"")}
return $certout}

Write-host -f cyan "Installing IIS cert"
$iiscert=certinstallloop $iiscertpass $iiscertname
$iiscert # test code
Write-host -f cyan "Installing Signing cert"
$signcert=certinstallloop $signcertpass $signcertname
$signcert # test code
Write-host -f cyan "Installing Decrypting cert"
$deccert=certinstallloop $deccertpass $deccertname
$deccert # test code
Write-host -f cyan "Installing Provisioning cert"
$provcert=certinstallloop $Provisioningpass $Provisioningcert
$provcert # test code

# step 5 - Remove / Recreate SSL binding on default web site.
#
Remove-WebBinding  -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

#   step 5a - Create a binding on 443 with cert from above
New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

#   step 5b - Get thumbprint for specific cert
Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | New-Item IIS:\SslBindings\0.0.0.0!443


#step 6 - Run config wizard.
#collect thumbprints for the certs.
($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})
($b=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $signcert})
($c=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $deccert})
($d=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $provcert})

pushd "C:\Program Files\Active Directory Federation Services 2.0"
.\FSConfig.exe JoinFarm /PrimaryComputerName $primaryadfsservername /ServiceAccount $adfsacctname /ServiceAccountPassword $adfsacctpass /CertThumbprint $a.thumbprint /cleanconfig
If ($? -eq $true){Write-Host -ForegroundColor Green ("SUCCESS: ADFS Configured")}}
catch{;break}
popd


#Step 10 - add eventlog source
..\bin\CreateEventLogSource.exe "AD FS 2.0"

# Removing Directory Browsing
try {LogMessage "info" "Removing Directory Browsing if installed"
	Remove-WindowsFeature Web-Dir-Browsing}
catch{LogMessage "warn" "WARNING!!!  Unable to remove Directory Browsing. Most likely cause is reboot required"}

set_enableVersionHeader_false

# End transcript
try {stop-transcript}
catch { "Unable to Stop Transcript"}