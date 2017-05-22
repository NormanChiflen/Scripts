########################################################################
# Copyright (C) 2010 Expedia, Inc.
# All rights reserved.
#
# Set the global build environment variables for a database build.
#
# Change History:
# Date        Author            Description
# 2011-03-12  Grigory Pogulsky  Created.
########################################################################

########################################################################
# Declare functions for later use
########################################################################

function TestPath ([string] $path)
{
	if (!(Test-Path $path))
	{
	    throw "Error: path not found: $path"
	}
}

########################################################################
# Script execution starts here
########################################################################

[string] $bld_version = "1.0 3/12/2012"

[string] $bld_startLocation = Get-Location

# Set $db_outputRoot & $db_server
if (Test-Path ".\Set-GlobalBuildVars_Local.ps1")
{
    . .\Set-GlobalBuildVars_Local.ps1
}


[System.IO.FileSystemInfo] $file = $null

# $bld_setvars
[string] $bld_setvars = ".\Set-BuildVars.ps1"
TestPath $bld_setvars
$file = Get-Item -Path $bld_setvars
$bld_setvars = $file.FullName


# $bld_invokeBuild
[string] $bld_invokeBuild = ".\BuildDatabase.ps1"
TestPath $bld_invokeBuild
$file = Get-Item -Path $bld_invokeBuild
[string] $bld_invokeBuild = $file.FullName


# $bld_vsdbcmdPath
[string] $bld_vsdbcmdPath = "..\buildsupport\db\Deploy\vsdbcmd.exe"
TestPath $bld_vsdbcmdPath
$file = Get-Item -Path $bld_vsdbcmdPath
$bld_vsdbcmdPath = $file.FullName


# $bld_runSqlScripts
[string] $bld_runSqlScripts = ".\RunSqlScripts.ps1"
TestPath $bld_runSqlScripts
$file = Get-Item -Path $bld_runSqlScripts
$bld_runSqlScripts = $file.FullName


# $bld_deployBuild
[string] $bld_deployBuild = ".\DeployBuild.ps1"
TestPath $bld_deployBuild
$file = Get-Item -Path $bld_deployBuild
$bld_deployBuild = $file.FullName


# $bld_funcLig
[string] $bld_funcLib = ".\FuncLibrary.ps1"
TestPath $bld_funcLib
$file = Get-Item -Path $bld_funcLib
$bld_funcLib = $file.FullName


# $bld_scriptGlobal
[string] $bld_scriptGlobal = ".\Scripts\Global"
TestPath $bld_scriptGlobal
$file = Get-Item -Path $bld_scriptGlobal
$bld_scriptGlobal = $file.FullName


# $bld_scriptSetup
[string] $bld_scriptSetup = ".\Scripts\Setup"
TestPath $bld_scriptSetup
$file = Get-Item -Path $bld_scriptSetup
$bld_scriptSetup = $file.FullName


# $bld_scriptUpgrade
[string] $bld_scriptUpgrade = ".\Scripts\Upgrade"
TestPath $bld_scriptUpgrade
$file = Get-Item -Path $bld_scriptUpgrade
$bld_scriptUpgrade = $file.FullName


# $bld_scriptRollback
[string] $bld_scriptRollback = ".\Scripts\Rollback"
TestPath $bld_scriptRollback
$file = Get-Item -Path $bld_scriptRollback
$bld_scriptRollback = $file.FullName







