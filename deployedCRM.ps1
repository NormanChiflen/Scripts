#checks the version of the currently deployed CRM solution and updates the target system if the version deployed is older than the latest version.

Write-Host “Deployment Started…”

# Import the xRM CI Framework Dynamics CRM Cmdlets
Import-Module “C:\Program Files (x86)\Xrm CI Framework\CRM 2011\PowerShell Cmdlets\Xrm.Framework.CI.PowerShell.dll”

#Define the CRM connection
$targetCrmConnectionUrl = “ServiceUri=http://test/testorg/XRMServices/2011/Organization.svc`;”

# Retrieve the solution details from CRM

$testSolution = Get-XrmSolution -ConnectionString $targetCrmConnectionUrl -UniqueSolutionName “TestSolution”

if ($testSolution -eq $null)
{
Write-Host “Test Solution not currently installed”
}
else
{
Write-Host “Current Test Solution version: “ -NoNewline $testSolution.Version
}

if (($testSolution -eq $null) -or ($testSolution.Version -ne “2.0.1.0”))
{
$importPath = “TestSolution_2_0_1_0_managed.zip”
Write-Host “Importing Solution: $importPath”

# Import CRM Solution
Import-XrmSolution -ConnectionString $targetCrmConnectionUrl -SolutionFilePath $importPath -PublishWorkflows $true -OverwriteUnmanagedCustomizations $true
}
else
{
Write-Host “Skipped import of Test Solution”
}
