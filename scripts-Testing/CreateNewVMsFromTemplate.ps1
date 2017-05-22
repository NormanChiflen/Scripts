# Filename:      NewVMsFromTemplate.ps1
# Description:   Creates a specified number of virtual machines from a template and
#                then deploys them on a host.

# Connect to the VMM server.
Get-VMMServer -ComputerName "CHC-T2VMM01.sea.corp.expecn.com"

# Supply the name of the template, the number of virtual machines to create, and 
# the host group in which to deploy the virtual machines.
$VMTemplate = "CHELT2S2003-01"
$NumVMs = "2"
$VMHostGroup = Get-VMHostGroup -Name "All Hosts"

While($NumVMs -gt 0)
{
   # Generate a unique virtual machine name.
   $Random = New-Object System.Random
   $VMRnd = $Random.next()
   $VMName = "VM_"+$VMRnd

   # Get and sort the host ratings for all the hosts in the host group.
   $HostRatings = @(Get-VMHostRating -DiskSpaceGB 16 -Template $VMTemplate -VMHostGroup $VMHostGroup -VMName $VMName | where { $_.Rating -gt 0 } | Sort-Object -property Rating -descending)

   If($HostRatings.Count -eq "0") { throw "No hosts meet the requirements." }

   # If there is at least one host that will support the virtual machine,
   # create the virtual machine on the highest-rated host.
   If ($HostRatings.Count -ne 0)
   {

      $VMHost = $HostRatings[0].VMHost
      $VMPath = $HostRatings[0].VMHost.VMPaths[0]

      #Generate a new job group.
      $VMJobGroup = [System.Guid]::NewGuid()

      Get-Template -VMMServer "CHC-T2VMM01.sea.corp.expecn.com" | where { $_.Name -eq $VMTemplate }

      # Create the virtual machine.
      New-VM -Template $VMTemplate -Name $VMName -Description "Virtual machine created from a template with a script" -VMHost $VMHost -Path $VMPath -JobGroup $VMJobGroup -RunAsynchronously -Owner "CONTOSO\Phyllis" -ComputerName "*" -OrgName "" -TimeZone 4 -JoinWorkgroup "WORKGROUP"  -AnswerFile $null -RunAsSystem -StartAction NeverAutoTurnOnVM -StopAction SaveVM 
   }

   $NumVMs = $NumVMs -1
}