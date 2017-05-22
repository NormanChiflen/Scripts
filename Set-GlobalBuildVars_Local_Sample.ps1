########################################################################
# Copyright (C) 2010-2012 Expedia, Inc.
# All rights reserved.
#
# Set the machine local build environment variables
#
# NOTE:
# 
# This file is used to customize a build for a specific machine.
# Copy and rename this file to: Set-GlobalBuildVars_Local.ps1
# Customize the build variables as needed.
#
# Change History:
# Date        Author            Description
# 2011-02-11  Steve Couch       Created.
# 2012-03-12  Grigory Pogulsky  Elevated to global.
########################################################################


########################################################################
# Script execution starts here
########################################################################

[string] $db_outputRoot = $db_outputRoot
if (($db_outputRoot -eq $null) -or ($db_outputRoot -eq ""))
{
    $db_outputRoot = "E:\builds\depot\agtexpe\databases"
}

[string] $db_server = $db_server
if (($db_server -eq $null) -or ($db_server -eq ""))
{
    $db_server = $env:COMPUTERNAME
}

