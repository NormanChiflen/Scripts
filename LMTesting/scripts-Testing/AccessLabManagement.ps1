
# Load Client Assembly
#[Reflection.Assembly]::Load(“Microsoft.TeamFoundation.Lab.Workflow.Activities, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a”);
#[void][reflection.assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Lab.Workflow.Activities")
# Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\PrivateAssemblies\Microsoft.TeamFoundation.Lab.Workflow.Activities.dll"
#Add-Type -AssemblyName ('Microsoft.TeamFoundation.Lab.Workflow.Activities, Version=10.0.0.0, ' +
#                        'Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
						
# TFS and Lab Connections
$tfsCollectionUrl = “http://expediatfs.SEA.CORP.EXPECN.com:8080/tfs/DefaultCollection”;
#$tfsCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($tfsCollectionUrl);
#$labService = $tfsCollection.GetService([Microsoft.TeamFoundation.Lab.Client.LabService]);

#$labActivities = New-Object Microsoft.TeamFoundation.Lab.Workflow.Activities

#$labURI = GetLabEnvironmentUri

# Random URI for the Environment
#$labEnv = $labService.GetLabEnvironment(“vstfs:///LabManagement/LabEnvironment/584”);
 
Write-Host ” “
Write-Host “Environment State:” $labEnv.StatusInfo.State
Write-Host “Environment Number of VMs:” $labEnv.LabSystems.Count
Write-Host ” “
 
foreach($labSystem in $labEnv.LabSystems)
{
    Write-Host “VM Name: “$labSystem.Name
    Write-Host “Hyper-V Host: “$labSystem.ExtendedInfo.HostName
    Write-Host “Guest OS: “$labSystem.ExtendedInfo.GuestOperatingSystem
    Write-Host ” “
}


#GetLabEnvironmentInUseMarker
#GetLabEnvironmentStatus 
