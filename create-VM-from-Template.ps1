#------------------------------------------------------------------------------------
# Author:        Pete Zerger
# Filename:      CreateVMFromTemplate.ps1
# Description:   Creates a virtual machine from a template and
#                then deploys it to the highest rated host.
#
#                Based on sample code at:         
#                http://technet.microsoft.com/en-us/library/dd349315.aspx
#create a new virtual machine from an existing VM template in any SCVMM library. Requires SCVMM 2008 Powershell extensions.
#Script has 3 required parameters. Run with no parameters and syntax will be echoed to the screen. Be sure to add a license key and administrator password to your template first!
#
#------------------------------------------------------------------------------------

param($VMMServer,$VMName, $TemplateName)

#Echo Syntax
#Echo syntax if script is run with no parameters
     if ($VMMServer -eq $null) {
        Write-Host ""
        Write-Host "SYNTAX:";
        Write-Host "This script has 3 required parameters.";
        Write-Host ""
        Write-Host "-VMMServer: FQDN of the SCVMM 2008 Server";
        Write-Host "Ex: scvmm.fqdn.local";
        Write-Host ""
        Write-Host "-VMName: Name that will be given to the virtual machine when created";
        Write-Host "Ex: ‘dc.contoso.com";
        Write-Host ""
        Write-Host "-TemplateName: Name of the VM template upon which the VM is based.”;
        Write-Host "Ex: ‘MYW2K3TEMPLATE’”;
        Write-Host ""
 exit;
     }

#Connect to the VMM Server
Get-VMMServer -ComputerName $VMMServer

# Supply the name of the template, the number of virtual machines to create, and 
# the host group in which to deploy the virtual machines.
$VMTemplate = $TemplateName
$VMHostGroup = Get-VMHostGroup -Name "All Hosts"

# Get and sort the host ratings for all the hosts in the host group.
$HostRatings = @(Get-VMHostRating -DiskSpaceGB 16 -Template $VMTemplate -VMHostGroup $VMHostGroup -VMName $VMName | where { $_.Rating -gt 0 } | Sort-Object -property Rating -descending)

 If($HostRatings.Count -eq "0") { throw "No hosts meet the requirements." }

 # If there is at least one host that will support the virtual machine,
 # create the virtual machine on the highest-rated host.
 If ($HostRatings.Count -ne 0)
 {

  $VMHost = $HostRatings[0].VMHost
  $VMPath = $HostRatings[0].VMHost.VMPaths[0]

  #Generate a new job group (a random Guid). 
  #Job Group comes in handy for checking job progress
  $VMJobGroup = [System.Guid]::NewGuid()

  Get-Template -VMMServer $VMMServer | where { $_.Name -eq $VMTemplate }

  # Create the virtual machine.
  # You can set VM owner, start and stop actions, and several other options here
  New-VM -Template $VMTemplate -Name $VMName -Description "Virtual machine created from a `
  template with a script" -VMHost $VMHost -Path $VMPath -JobGroup $VMJobGroup -RunAsynchronously `
  -ComputerName "*" -OrgName "" -TimeZone 4 -JoinWorkgroup "WORKGROUP"  `
  -AnswerFile $null -RunAsSystem -StartAction NeverAutoTurnOnVM -StopAction SaveVM 
}
