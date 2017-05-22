# =================================================================================================
# 
# Microsoft PowerShell Source File -- Created with SAPIEN Technologies PrimalScript 2009
# 
# NAME: Hyper-V Host & Guest Maintenance Script
# 
# AUTHOR: Pete Zerger, MVP - Operations  Manager & Essentials
# DATE  : 4/20/2009
# 
# COMMENT: This script prompts user for SCVMM Server and Hyper-V host and then 
#          -Marks Hyper-V host as unavailable for placement
#		   -Takes a snapshot of all VMs on host and labels as "Checkpoint Before Hotfix Application"
#
#		   Designed to be run from the SCVMM Administrator Console (right-click launch from Library)
# ==================================================================================================

#Prompt user for VMM Server name
$VMMServer = read-host -prompt "Enter VMM Server Name"

get-vmmserver -computername $VMMServer


#Prompt user for Hyper-V host name
$VMHost = read-host -prompt "Enter Host Name:"

$VMs = get-VM | where-object {$_.Status -eq 'Running'} 

foreach ($vm in $VMs)

{

Get-VM -Name $VM | New-VMCheckpoint -RunAsynchronously -JobVariable "NewCheckpointJob"  -Description "Checkpoint Before Hotfix Application"

}

#Put Hyper-V host in maintenance mode (mark as unavailable for placement

Set-VMHost -VMHost $VMHost -AvailableForPlacement $false