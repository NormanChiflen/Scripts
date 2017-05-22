########################################################################
# Copyright (C) 2010 Expedia, Inc.
# All rights reserved.
#
# Set the build environment variables for a database build.
# Normally you should not need to change these settings.
#
# Change History:
# Date        Author            Description
# 2010-12-21  Steve Couch       Created.
# 2011-07-14  Steve Couch       Added auto calculation of buildNumber
# 2012-03-23  Grigory Pogulsky  Added $db_systemValueSchema and 
#                               and Set-BuildVars_LocalOverrides.ps1 call 
########################################################################

########################################################################
# Declare functions for later use
########################################################################

function Get-LastBuildDir([string] $buildRootDir, [string] $majorVersion, [string] $minorVersion)
{
    if (Test-Path "$buildRootDir")
    {
        [string] $buildDirPath = $buildRootDir + "\v" + $majorVersion + "." + $minorVersion + "*"
        [string] $lastBuildDir = dir $buildDirPath | Sort-Object -Property Name -Descending | Select-Object -First 1
        return $lastBuildDir
    }
    else
    {
        return ""
    }
}

function Get-NextBuildNumber([string] $buildRootDir, [string] $majorVersion, [string] $minorVersion)
{
    [int] $buildNumberMax = "0"
    [string] $buildDirPath = $buildRootDir + "\v" + $majorVersion + "." + $minorVersion + "*"
    if (Test-Path "$buildDirPath")
    {
        foreach ($d in dir $buildDirPath)
        {
            if ($d.PSIsContainer -eq $true)
            {
                [int] $build = $d.Name.SubString($d.Name.LastIndexOf(".")+1)
                if ($build -ge $buildNumberMax)
                {
                    $buildNumberMax = $build + 1
                }
            }
        }
    }
    [string] $buildNumber = "{0:d3}" -f $buildNumberMax
    return $buildNumber
}

########################################################################
# Script execution starts here
########################################################################

if (Test-Path ".\Set-BuildVars_CanonicalDB.ps1")
{
    . .\Set-BuildVars_CanonicalDB.ps1
}
else
{
    throw "Error: File not found: Set-BuildVars_CanonicalDB.ps1"
}

# Build Variables

[string] $db_server = $db_server
if (($db_server -eq $null) -or ($db_server -eq ""))
{
    if ($env:db_server -eq $null -or $env:db_server -eq "")
    {
        $db_server = $env:COMPUTERNAME
    }
    else
    {
        $db_server = $env:db_server
    }
}

[string] $db_outputRoot = $db_outputRoot
if (($db_outputRoot -eq $null) -or ($db_outputRoot -eq ""))
{
    if ($env:db_outputRoot -eq $null -or $env:db_outputRoot -eq "")
    {
        $db_outputRoot = ".\build"
    }
    else
    {
        $db_outputRoot = $env:db_outputRoot
    }
}

[string] $db_buildNumber= Get-NextBuildNumber  "$db_outputRoot\$db_canonicaldb" $db_majorVersion $db_minorVersion
[string] $db_version="v$db_majorVersion.$db_minorVersion.$db_buildNumber"
[string] $db_buildDir = $db_outputRoot + "\$db_canonicaldb\$db_version"

[string] $db_lastBuildDir = Get-LastBuildDir  "$db_outputRoot\$db_canonicaldb" $db_majorVersion $db_minorVersion
[string] $db_branch = (Get-Location | Split-Path -Leaf).Replace(".","_")
[string] $db_logFile="$db_buildDir\buildlogs\dbbuildlog.$db_canonicaldb.$db_branch.txt"

[string] $db_setupdb = $env:USERNAME + "_" + $db_canonicaldb + "_" + $db_branch + "_Setup"
[string] $db_upgradedb = $env:USERNAME + "_" + $db_canonicaldb + "_" + $db_branch + "_Upgrade"
[string] $db_rollbackdb = $env:USERNAME + "_" + $db_canonicaldb + "_" + $db_branch + "_Rollback"

[string] $db_setupFile = "$db_buildDir\deliverables\setup\$db_canonicaldb.setup.sql"
[string] $db_vstsSetupFile = "$db_buildDir\deliverables\vsts\$db_canonicaldb.setup.autogen.sql"

[string] $db_upgradeFile = "$db_buildDir\deliverables\upgrade\$db_canonicaldb.upgrade.autogen.sql"
[string] $db_vstsUpgradeFile = "$db_buildDir\deliverables\vsts\$db_canonicaldb.upgrade.autogen.sql"

[string] $db_rollbackFile = "$db_buildDir\deliverables\rollback\$db_canonicaldb.rollback.autogen.sql"
[string] $db_vstsRollbackFile = "$db_buildDir\deliverables\vsts\$db_canonicaldb.rollback.autogen.sql"

[string] $db_upgradeCompareFile = "$db_buildDir\buildlogs\$db_canonicaldb.upgrade.compare.autogen.sql"
[string] $db_vstsUpgradeCompareFile = "$db_buildDir\deliverables\vsts\$db_canonicaldb.upgrade.compare.autogen.sql"

[string] $db_rollbackCompareFile = "$db_buildDir\buildlogs\$db_canonicaldb.rollback.compare.autogen.sql"
[string] $db_vstsRollbackCompareFile = "$db_buildDir\deliverables\vsts\$db_canonicaldb.rollback.compare.autogen.sql"

[string] $db_vstsDeployDir = "Source\sql\debug"
[string] $db_vstsDeployManifestFile = $db_canonicaldb + ".deploymanifest"
[string] $db_vstsDeployConfigFile = $db_canonicaldb + "_Database.sqldeployment"
[string] $db_vstsDeployVarsFile = $db_canonicaldb + "_Database.sqlcmdvars"

[string] $db_priorSetupFile = "$db_priorVersionFolder\deliverables\setup\$db_canonicaldb.setup.sql"

[string] $db_systemValueSchema = "dbo"

if (Test-Path Set-BuildVars_LocalOverrides.ps1)
{
    . .\Set-BuildVars_LocalOverrides.ps1
}
