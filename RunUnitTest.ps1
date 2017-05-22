########################################################################
# Copyright (C) 2012 Expedia, Inc.
# All rights reserved.
#
# Runs Database Unit tests
#
# Change History:
# Date        Author            Description
# 2013-03-11  Grigory Pogulsky  Created.
########################################################################

########################################################################
# Declare parameters and global variables
########################################################################

# Action
# 1 - Execute only
# 2 - Setup and Execute
# 3 - Setup, Execute, and Teardown


param(
# Path to db main\Test folder
[parameter(Mandatory=$true, ParameterSetName="main", Position=1)] [string] $testpath,
[parameter(Mandatory=$true, ParameterSetName="main", Position=2)] [string] $action,
[parameter(Mandatory=$true, ParameterSetName="main", Position=3)] [string] $server,
[parameter(Mandatory=$true, ParameterSetName="main", Position=4)] [string] $database,
[parameter(Mandatory=$false, ParameterSetName="main", Position=5)] [string] $user = "",
[parameter(Mandatory=$false, ParameterSetName="main", Position=6)] [string] $pwd = ""
)

$buildVersion = "1.0.1 3/12/13"

[string] $testMaster = ".\UnitTest\TestMasterPS.sql"
$file = Get-Item -Path $testMaster
$testMaster = $file.FullName

[string] $testTeardown = ".\UnitTest\TestMaster_teardown.sql"
$file = Get-Item -Path $testTeardown
$testTeardown = $file.FullName


trap
{
	Pop-Location
    Stop-Transcript 
	throw $_
}

Push-Location $testpath

[bool]$stepSetup = $false
[bool]$stepExecute = $true
[bool]$stepTeardown = $false

$stepSetup = ($action -ge 2)
$stepTeardown = ($action -ge 3)

#
# SETUP
#
if ($stepSetup)
{
    "RUNNING SETUP STEPS... "

    " Set up schema "
    foreach ($file in (Get-ChildItem ".\schema\*.sql"))
    {
        $file.FullName
        Invoke-SQLFile -sqlFile $file.FullName -db $database -server $server -user $user -pwd $pwd
    }

    # By running only the Private sprocs first then we avoid getting the SQL warnings about dependencies.
    # The Private sprocs will get run again in the next step, but the output is still cleaner without the warnings.
    ""
    " Set up testPrivate procs "
    foreach ($file in (Get-ChildItem ".\sp\testPrivate*.sql"))
    {
        Invoke-SQLFile -sqlFile $file.FullName -db $database -server $server -user $user -pwd $pwd
    }

    ""
    " Set up other test procs "
    foreach ($file in (Get-ChildItem ".\sp\*.sql" -Exclude "testPrivate*.sql"))
    {
        Invoke-SQLFile -sqlFile $file.FullName -db $database -server $server -user $user -pwd $pwd
    }

    ""
    " Set up Exceptions procs "
    foreach ($file in (Get-ChildItem ".\Exceptions\*.sql"))
    {
        Invoke-SQLFile -sqlFile $file.FullName -db $database -server $server -user $user -pwd $pwd
    }


    "SETUP STEPS COMPLETED SUCCESSFULLY."
}

#
# EXECUTE
#
"EXECUTING TEST PROCEDURES... "

Invoke-SQLFile -sqlFile $testMaster -db $database -server $server -user $user -pwd $pwd


[bool] $testResult = $false
# Check output file for the result
foreach($rs in (Get-Content $outfilename))
{
    if ($rs -match "# OVERALL TEST RESULT:" -and $rs -match "SUCCESS")
    {
        $testResult = $true
        break
    }
}


#
# TEARDOWN
#
if ($stepTeardown)
{
    "RUNNING TEARDOWN STEP "
    Invoke-SQLFile -sqlFile $testTeardown -db $database -server $server -user $user -pwd $pwd
}

Pop-Location

if ($testResult)
{
    ""
    " SUCCESS "
    ""
}
else
{
    ""
    $color = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = 'Red'
    " UnitTests FAILED "
    $host.ui.RawUI.ForegroundColor = $color
    ""
}

