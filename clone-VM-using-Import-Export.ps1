# script retrieves the Msvm_VirtualSystemManagmentService class and the MasterVM’s Msvm_ComputerSystem. It then loops 10 times, first changing the name of the VM and then exporting the VM and finally re-importing the VM. After it completes the 10 interactions it restores the name of original name of the MasterVM.
# http://blogs.msdn.com/b/taylorb/archive/2008/06/07/hyper-v-wmi-cloning-virtual-machines-using-import-export.aspx
# http://www.systemcentercentral.com/download/cloning-hyper-v-vms-in-powershell-using-importexport/
# script takes 4 parameters:
     # MasterVM – this is the name of the VM that will be cloned
     # Path – this is the base path where the clones will reside
     # NewName – this is what the cloned VM’s will be named
     # HyperVHost – this is the name of the host that the script will execute against

The function ProcessWMIJob takes the return of a WMI method call and then processes the job waiting for the job to complete  and throwing an exception if the job failed.

param
(
    [string]$MasterVM = $(Throw "MasterVM required"),
    [string]$Path = $(Throw "Path required"),
    [string]$NewName = "VMCopy",
    [string]$HyperVHost = "localhost"
)


function ProcessWMIJob
{
    param
    (
        [System.Management.ManagementBaseObject]$Result
    )

    if ($Result.ReturnValue -eq 4096)
    {
        $Job = [WMI]$Result.Job

        while ($Job.JobState -eq 4)
        {
            Write-Progress -Id 2 -ParentId 1 $Job.Caption -Status "Executing" -PercentComplete $Job.PercentComplete
            Start-Sleep 1
            $Job.PSBase.Get()
        }
        if ($Job.JobState -ne 7)
        {
            Write-Error $Job.ErrorDescription
            Throw $Job.ErrorDescription
        }
    }
    elseif ($Result.ReturnValue -ne 0)
    {
        Throw $Result.ReturnValue
    }
    Write-Progress $Job.Caption -Status "Completed" -PercentComplete 100 -Id 2 -ParentId 1
}

#Main Script Body
$VMManagementService = Get-WmiObject -Namespace root\virtualization -Class Msvm_VirtualSystemManagementService -ComputerName $HyperVHost
$SourceVm = Get-WmiObject -Namespace root\virtualization -Query "Select * From Msvm_ComputerSystem Where ElementName='$MasterVM'" -ComputerName $HyperVHost
$a = 0


while ($a -lt 10) {
    write-progress -Id 1 "Cloning Vm's" -Status "Executing" -percentcomplete (($a / 10)*100)
    $tempVMName = "$NewName - $a"
    $VMSettingData = Get-WmiObject -Namespace root\virtualization -Query "Associators of {$SourceVm} Where ResultClass=Msvm_VirtualSystemSettingData AssocClass=Msvm_SettingsDefineState" -ComputerName $HyperVHost
    $VMSettingData.ElementName = $tempVMName

    $Result = $VMManagementService.ModifyVirtualSystem($SourceVm, $VMSettingData.PSBase.GetText(1))
    ProcessWMIJob $Result

    $Result = $VMManagementService.ExportVirtualSystem($SourceVm, $TRUE, "$Path")
    ProcessWMIJob $Result

    $Result = $VMManagementService.ImportVirtualSystem("$Path\$tempVMName", $TRUE)
    ProcessWMIJob $Result

    $a ++
}


write-progress -Id 1 -Completed $TRUE -Activity "Cloning Vm's"
$VMSettingData = Get-WmiObject -Namespace root\virtualization -Query "Associators of {$SourceVm} Where ResultClass=Msvm_VirtualSystemSettingData AssocClass=Msvm_SettingsDefineState" -ComputerName $HyperVHost
$VMSettingData.ElementName = $MasterVM

$Result = $VMManagementService.ModifyVirtualSystem($SourceVm, $VMSettingData.PSBase.GetText(1))
ProcessWMIJob $Result 