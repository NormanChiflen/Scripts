# ---------- SCRIPT STARTS HERE--------------

$waitstart = 200
$waitshutdown = 120

if ($args[1] -match "0") {
$inputfile=get-content $args[0]
foreach ($guest in $inputfile) {
write-host "Starting $guest"
$vm = gwmi -namespace root\virtualization -query "select * from msvm_computersystem where elementname='$guest'"
$result = $vm.requeststatechange(2)
if ($result.returnvalue -match "0") {
start-sleep -s $waitstart
write-host ""
write-host "$guest is started" -foregroundcolor green
write-host ""
}
else {
write-host ""
write-host "unable to start $guest" -foregroundcolor red
write-host ""
}}}

if ($args[1] -match "1") {
$inputfile=get-content $args[0]
foreach ($guest in $inputfile) {
write-host "shutting down $guest"
$vm = gwmi -namespace root\virtualization -query "select * from msvm_computersystem where elementname='$guest'"
$vmname = $vm.name
$vmshut = gwmi -namespace root\virtualization -query "SELECT * FROM Msvm_ShutdownComponent WHERE SystemName='$vmname'"
$result = $vmshut.InitiateShutdown("$true","no comment")
if ($result.returnvalue -match "0") {
start-sleep -s $waitshutdown
write-host ""
write-host "no error while shutting down $guest"
write-host "shutdown of $guest completed" -foregroundcolor green
write-host ""}

else {
write-host ""
write-host "unable to shutdown $guest" -foregroundcolor red
write-host ""
}}}

else {
write-host "USAGE: to shutdown VMs," -nonewline; write-host ".\managehyperV.ps1 c:\hosts.txt 1" -foregroundcolor yellow
write-host "USAGE: to start VMs," -nonewline; write-host ".\managehyperV.ps1 c:\hosts.txt 0" -foregroundcolor yellow
}

# ---------- SCRIPT ENDS HERE--------------
# you will need to create a simple text file containing a list of the virtual machine names you want started and/or stopped. In my case I called the file "hosts.txt"

# for example:
# Virtual Srv1
# Virtual Srv2
# VirtXP 1 
# http://community.spiceworks.com/how_to/show/1793-powershell-script-to-shutdown-startup-backup-virtual-machines