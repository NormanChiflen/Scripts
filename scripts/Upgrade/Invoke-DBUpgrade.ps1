########################################################################
# Copyright (C) 2010-2011 Expedia, Inc.
# All rights reserved.
#
# Run database upgrade
#
# Change History:
# Date        Author            Description
# 2010-11-16  Steve Couch       Created.
# 2011-04-21  Steve Couch       Added DataDeploy functionality
# 2012-03-14  Grigory Pogulsky  Switched to using DeployBuild.ps1
########################################################################

param(
	[string] $server,
	[string] $db,
	[ValidateSet("dev", "test", "prod")]
    [string] $environment = "prod"
)

function Display-Usage
{
	"Invoke-DBUpgrade.ps1 : Deploy utility for running database upgrade"
	"Usage: .\Invoke-DBUpgrade.ps1 server, [db], [environment]"
	"Where:"
	"    server      : name (plus instance) of SQL Server to deploy change"
	"    db          : name of database      "
	"    environment : logical name of environment"
	"                : possible values: dev, test, prod (default='prod')"
    ""
	"Observed parameters:"
	"    server = '$server'"
	"    db = '$db'"
	"    environment = '$environment'"
    ""
}

########################################################################
# Script execution starts here
########################################################################

# Load the deployment library
if (Test-Path "FuncLibrary.ps1")
{
	. .\FuncLibrary.ps1
}
else
{
	throw "Error: Cannot find file .\FuncLibrary.ps1"
}

# Verify inbound parameters
if ($server -eq "")
{
	Display-Usage
	exit
}

# Load the deployment library
if (!(Test-Path "DeployBuild.ps1"))
{
	throw "Error: Invoke-DBSetup.ps1: Cannot find file .\DeployBuild.ps1"
}

#  $logfilename, $outfilename are required for logging

$dt = Get-Date
$logfilename = "Setup_"+$dt.ToString("MMddyyhhmmss")+".log";
$file = New-Item -ItemType file $logfilename
$logfilename = $file.FullName

$file = New-Item -ItemType file "out.txt" -Force
$outfilename = $file.FullName 

$file = Get-Item "..\.."
$buildDir = $file.FullName

. .\DeployBuild.ps1 "Upgrade" $buildDir $server $db $environment


