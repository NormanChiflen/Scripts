########################################################################
# Copyright (C) 2012 Expedia, Inc.
# All rights reserved.
#
# Run SQL scripts listed in given $scriptsFile
#
# Change History:
# Date        Author            Description
# 2012-03-08  Grigory	        Created.
########################################################################

param(
	[string] $server,
	[string] $db,
	[string] $scriptsFile = "SqlScripts.xml",
	[string] $user = "",
	[string] $pwd = ""
)

$version = "1.0 3/08/2012"

function FixSourcePath ([string] $path)
{
    if ($path -eq $null -or $path -eq "" -or !$path.StartsWith("\"))
    {
        return $path
    }
    else
    {
        return ("."+$path)
    }
}

# Define function to support recursion
function Invoke-RunScripts([string] $xmlFile, [string] $server, [string] $db,
	[string] $user = "", [string] $pwd = "")
{
    "Reading file $xmlFile" | Write-Log

    if (!(Test-Path "$xmlFile"))
    {
        throw "Error: RunSqlScripts: file does not exist ($xmlFile)" 
    }
    
    $dataDeployXml = [xml] (Get-Content "$xmlFile")
    foreach ($includeXmlFile in $dataDeployXml.DataDeploy.Includes.IncludeXmlFile)
    {
        if ($includeXmlFile -ne $null)
        {
            [string] $includeFile = (FixSourcePath $includeXmlFile.sourcePath) + $includeXmlFile.fileName
            "`$includeFile: $includeFile"

			Invoke-RunScripts -xmlFile $includeFile -server $server -db $db -user $user -pwd $pwd
        }
    }
    
    foreach ($sqlDataScript in $dataDeployXml.DataDeploy.Deployments.SqlDataScript)
    {
        if ($sqlDataScript -ne $null)
        {
            [string] $sqlFile = (FixSourcePath $sqlDataScript.sourcePath) + $sqlDataScript.fileName
            "`$sqlDataScript: $sqlFile"

            Invoke-SQLFile -sqlFile $sqlFile -db $db -server $server -user $user -pwd $pwd
        }
    }
}



########################################################################
# Script execution starts here
########################################################################

Write-Log
Format-LogText ("RunSqlScripts.ps1 $server $db $scriptsFile $user $pwd") | Write-Log
Write-Log
Write-Log ("Script version "+$version)
Write-Log

if ($scriptsFile -eq "" -or $scriptsFile -eq "SqlScripts.xml")
{
	"Executing scripts in " + (Get-Location).Path | Write-Log
	
	$scriptsFile = "SqlScripts.xml"
	
	if (!(Test-Path $scriptsFile))
	{
		" SqlScripts.xml is not found in " + (Get-Location).Path | Write-Log
		Format-LogText " Exiting script." | Write-Log
		return
	}
}

Invoke-RunScripts $scriptsFile $server $db $user $pwd
	
Write-Log
Format-LogText "Finished running scripts" | Write-Log
Write-Log
