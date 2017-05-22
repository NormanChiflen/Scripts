########################################################################
# Copyright (C) 2012 Expedia, Inc.
# All rights reserved.
#
# Sync p4 tree from the given $root
# Logs p4 in using encrypted password stored in a secret file
#
# Change History:
# Date        Author            Description
# 2010-03-21  Grigory Pogulsky  Created. Based on script provided by Steve Couch.
########################################################################

param([parameter(Mandatory=$true, ParameterSetName="main", Position=1)] [string] $root)

$version = "1.0 3/16/12"

"Sync script version " + $version
(Get-Date).ToString()
""
" ROOT: " + $root
""

#"SETUP"
#
#   Setup has to run once to create a secret file.
#   It has to be run in the same security context as the future use context will be
#   (run under the same credentials).
#
#$p4pwd = ConvertTo-SecureString "ENTER_PASSWORD_HERE" -AsPlainText -Force
#$p4pwd | ConvertFrom-SecureString | Set-Content ("Sync-$env:COMPUTERNAME.ps1.credential")

# DB Logging
. .\LogLibrary.ps1
    
$secretfile = "Sync-$env:COMPUTERNAME.ps1.credential"

if (!(Test-Path $secretfile))
{
    throw "Secret file $secretfile is not found."
}

Push-Location

trap
{
    Pop-Location
    throw $_
}

[string] $s = Get-Content ($secretfile) 
$p4pwd =  ConvertTo-SecureString -String $s

if (Test-Path $root)
{
    cd $root

    LogSync
    
    [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p4pwd)) | p4 login
    p4 sync
}
else
{
    throw "ERROR: $root does not exist."
}

Pop-Location

""
