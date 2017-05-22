$newssolifetime=10
$oldssolifetime=240
$sleeptimer=(24*60*60) 
#timer has to be in seconds


# Is command window open as administrator?
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

#Load modules
$a=Get-Module -listavailable
foreach($a.count in $a){write-host  -ForegroundColor Cyan loading $a.name
Import-Module $a.name}


"current SSO lifetime is " + (get-ADFSProperties).SsoLifetime
"Setting Timeout to $newssolifetime minutes"
"going to sleep for "+($sleeptimer/60/60)+" hours"
Set-ADFSProperties –SsoLifetime $newssolifetime
start-sleep -s $sleeptimer
"Restoring SSO timeout to $oldssolifetime minutes"
Set-ADFSProperties –SsoLifetime $oldssolifetime
"current SSO lifetime is " + (get-ADFSProperties).SsoLifetime