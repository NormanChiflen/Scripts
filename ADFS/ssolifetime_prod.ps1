$newssolifetime=240
#SSo Life Time has to be in minutes


# Is command window open as administrator?
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

#Start Logging
try {stop-transcript}
catch { "Unable to Stop Transcript, probably already stopped"}
try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$pwd\SSOTimeout_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile}
catch { "Unable to Start Transcript"}

#Load modules
$a=Get-Module -listavailable
foreach($a.count in $a){write-host  -ForegroundColor Cyan loading $a.name
Import-Module $a.name}

#Make the SSO Change
"current SSO lifetime is " + (get-ADFSProperties).SsoLifetime
"Setting Timeout to $newssolifetime minutes"
Set-ADFSProperties –SsoLifetime $newssolifetime
if($newssolifetime -ne (get-ADFSProperties).SsoLifetime){write-host -f red "There was an error changing the SSOLifeTime, please execute: Set-ADFSProperties –SsoLifetime $newssolifetime   and examime screen output for errors."}else{
	"current SSO lifetime is " + (get-ADFSProperties).SsoLifetime
	}


# End transcript
try {stop-transcript}
catch { "Unable to Stop Transcript"}