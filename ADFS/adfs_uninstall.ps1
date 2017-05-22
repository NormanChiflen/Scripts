######################################################################
#                    Script for Uninstalling ADFS                    #
#                                                                    #
#              v1.5 Crude but effective by Alex Vinyar               #
#     Scripts available here: p1986\sait\users\Automation\ADFS\      #
######################################################################

#Start logging
try {stop-transcript}
catch { "Unable to Stop Transcript, probably already stopped"}

try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$pwd\ADFS_Uninstall_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile}
catch { "Unable to Start Transcript"}

# Step 1 - is command window open as administrator?
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

try {set-executionpolicy remotesigned -force}
catch { "Unable to set Group Policy"}


# Step 2 - Uninstalling App and deleting various artifacts.
wusa /uninstall /kb:974408 /quiet /norestart
C:\Windows\System32\inetsrv\appcmd delete app "Default Web Site/adfs/ls"
C:\Windows\System32\inetsrv\appcmd delete app "Default Web Site/adfs"
C:\Windows\System32\inetsrv\appcmd delete app "Default Web Site/adfs/card"
C:\Windows\System32\inetsrv\appcmd delete apppool ADFSAppPool
Pushd c:\inetpub
cmd /c Rd c:\inetpub\adfs /s /q


# Step 3 - Remove IIS stuff.

#load system modules - for iis manipulation
Import-Module WebAdministration

# ==================================Add override flag and Put both of the commands below in IF flag exist execute loops.
#$allinputs=Import-Csv "adfs config file.txt"
#$iiscertname=$allinputs[2].value
#$iiscert=certutil -f -importpfx -p $iiscertpass $iiscertname | select -first 1
#$iiscert=$iiscert.split('"') 
#$iiscert=$iiscert[1]
#$iiscert
#Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | remove-Item IIS:\SslBindings\0.0.0.0!443
Remove-WebBinding  -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
#Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | New-Item IIS:\SslBindings\0.0.0.0!443

#Step 4 - Restart
Shutdown /r /t 20 /c "ADFS installation is done. Computer restarting in 20 seconds."

#Stop Transcript
try {stop-transcript}
catch { "Unable to Stop Transcript, probably already stopped"}
