########################################################################
# Copyright (C) 2012 Expedia, Inc.
# All rights reserved.
#
# 
#
# Change History:
# Date        Author            Description
# 2012-02-29  Grigory Pogulsky  Created.
# 2012-05-21  Grigory Pogulsky  DB Logging added (v.1.0.1)
# 2012-08-20  Grigory Pogulsky  Deployment environment (v.1.0.2)
# 2012-08-28  Grigory Pogulsky  Upgrade environment (v.1.0.3)
# 2013-03-12  Grigory Pogulsky  RunUnitTest (v.1.0.4)
########################################################################

########################################################################
# Declare parameters and global variables
########################################################################

[CmdletBinding(DefaultParametersetName="main")] 
param([parameter(Mandatory=$true, ParameterSetName="main", Position=1)] [string] $configFile,
[parameter(Mandatory=$false, ParameterSetName="main", Position=2)] [string] $deployUser = "",
[parameter(Mandatory=$true, ParameterSetName="alternate", Position=1)] [string] $deploymentUser,
[parameter(Mandatory=$true, ParameterSetName="alternate", Position=2)] [string] $deploymentConfig,
[parameter(Mandatory=$false)] [string] $db_outputRoot,
[parameter(Mandatory=$false)] [string] $mailto = ""
)

$autoDeployVersion = "1.0.4 3/12/13"

$targetDeploymentFailed = $false


########################################################################
# Declare functions for later use
########################################################################

# Only output to the screen
# Transcript will pick up any output
function Log([string] $message = "")
{
    if ($message -eq "" -or $message -eq $null)
    {
        $message
    }
    else
    {	
        Format-LogText $message 
    }
}

# Fails the target, but continues to the next target
function FailTargetDeployment ([string] $message)
{
    Log ("")
    Log ($message)
    Log ("Target FAILED")
    $targetDeploymentFailed = $true
}

function RunUnitTest ([string] $sourcedb, [string] $targetServer, [string] $targetdb)
{
    Log ("  Run UnitTest ")

    $testpath = "..\databases\"+$sourcedb+"\main\Test"
    $action = 3
    . .\RunUnitTest.ps1 $testpath $action $targetServer $targetdb 
}

function InvokeLatestSetup ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [string] $psbuildversion, [string] $deployEnvironment)
{
    if ($psbuildversion -eq "1")
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_LatestSetup.ps1 $targetServer $targetdb 
        }
        else
        {
            .\Invoke-Deploy_LatestSetup.ps1 $targetServer $targetdb $deployEnvironment
        }
    }
    else
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_LatestSetup.ps1 $sourcedb $targetServer $targetdb 
        }
        else
        {
            .\Invoke-Deploy_LatestSetup.ps1 $sourcedb $targetServer $targetdb $deployEnvironment 
        }    
    }
}

function InvokePriorSetup ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [string] $psbuildversion, [string] $deployEnvironment)
{
    if ($psbuildversion -eq "1")
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_PriorSetup.ps1 $targetServer $targetdb 
        }
        else
        {
            .\Invoke-Deploy_PriorSetup.ps1 $targetServer $targetdb $deployEnvironment
        }
    }
    else
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_PriorSetup.ps1 $sourcedb $targetServer $targetdb 
        }
        else
        {
            .\Invoke-Deploy_PriorSetup.ps1 $sourcedb $targetServer $targetdb $deployEnvironment 
        }    
    }
}

function DeployDatabase ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [Xml.XmlElement] $deployStep, [string] $psbuildversion)
{
    Log ("")
    Log ("  Start deployment")
    
    $deployVer = $stepDeploy.Version
    if ($deployVer -eq $null) 
    { 
        $deployVer = "Latest" 
    }	
    elseif ($deployVer -ne "Prior" -and $deployVer -ne "Latest")
    {
        FailTargetDeployment ("  Error: Unknown element - " + $deployVer)
    }
    
    $deployEnvironment = $stepDeploy.Environment
    
    Log ("")
    Log ("  Run Setup - " + $deployVer)

    if ($deployVer -eq "Prior")
    {
        # PS-build scripts drop target database if exists
        InvokePriorSetup $sourcedb $targetServer $targetdb $psbuildversion $deployEnvironment
    }
    else
    {
        # PS-build scripts drop target database if exists
        InvokeLatestSetup $sourcedb $targetServer $targetdb $psbuildversion $deployEnvironment
    }
    
    Log ("")
    
    $runUTest = $stepDeploy.UnitTest
    if ($runUTest -eq "true")
    {   
        RunUnitTest $sourcedb $targetServer $targetdb 
    }
    
    Log ("  Deployment finished")
}

function RestoreDatabase ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [Xml.XmlElement] $restoreStep)
{
    Log ("")
    
    $restoreType = $restoreStep.Type
    if ($restoreType -eq $null -or $restoreType -eq "")
    {
        $restoreType = "sp_restore"
    }

    Log ("  Restore Database " + $sourcedb + " using " + $restoreType)
    
    if ($restoreType -ne "sp_restore")
    {
        FailTargetDeployment("  Error: Unknown restore type - " + $restoreType)
    }

    Log ("")
    Log ("    Files: ")
    
    $i = 0
    foreach ($file in $restoreStep.File)
    {
        Log ("    " + $file)
        $i = $i + 1
    }

    if ($restoreType -eq "sp_restore" -and $i -ne 1)
    {
        Log ("    Too many files specified")
        return
    }
    
    Log ("    Restoring ...")
    
    $sql = "EXEC sp_restore @pDBName='$targetdb', @pRestoreFile='$file' " 
    
    # Integrated auth
    Invoke-SQL $sql "master" $targetServer
}

function InvokeLatestUpgrade ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [string] $psbuildversion, [string] $deployEnvironment)
{
    if ($psbuildversion -eq "1")
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_LatestUpgrade.ps1 $targetServer $targetdb  
        }
        else
        {
            .\Invoke-Deploy_LatestUpgrade.ps1 $targetServer $targetdb $deployEnvironment
        }
    }
    else
    {
        if ($deployEnvironment -eq "")
        {
            .\Invoke-Deploy_LatestUpgrade.ps1 $sourcedb $targetServer $targetdb  
        }
        else
        {
            .\Invoke-Deploy_LatestUpgrade.ps1 $sourcedb $targetServer $targetdb $deployEnvironment  
        }
    }
}

function UpgradeDatabase ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [Xml.XmlElement] $upgradeStep, [string] $psbuildversion)
{
    Log ("")
    Log ("  Start Upgrade")

    $deployEnvironment = $upgradeStep.Environment

    InvokeLatestUpgrade $sourcedb $targetServer $targetdb $psbuildversion $deployEnvironment

    $runUTest = $upgradeStep.UnitTest
    if ($runUTest -eq "true")
    {   
        RunUnitTest $sourcedb $targetServer $targetdb 
    }

    Log ("")
    Log ("  Upgrade finished")
}

function ApplyTestData ([string] $sourcedb, [string] $targetServer, [string] $targetdb, [Xml.XmlElement] $stepTestData)
{
    Log ("")
    Log ("  Apply Test Overrides ")
    Log ("    Files: ")
    
    foreach ($file in $stepTestData.File)
    {
        # for whatever reason it is possible to get $file = $null
        # if there are no File elements within TestData element
        if ($file -eq $null)
        {
            break
        }
        
        Log ("    " + $file)
        Log ("    Applying ...")
        
        if (!(Test-Path $file))
        {
            FailTargetDeployment ("    Error: file '$file' does not exist")
            return
        }
        
        $fileItem = Get-Item $file
        
        if ($fileItem.Extension -eq ".xml")
        {
            Push-Location $fileItem.DirectoryName
            . $runSqlScripts $targetServer $targetdb  $fileItem.FullName
            Pop-Location
        }
        else
        {
            # Integrated auth
            . Invoke-SQLFile $file $targetdb $targetServer
        }
    }
    
    Log ("")
    Log ("  Finished Applying Test Overrides ")
}

function ProcessDatabaseIPU ([Xml.XmlElement] $database)
{
    trap 
    {
        "process trap"
        FailTargetDeployment("Exception: " + $_)
        . LogDeployDatabaseEnd $dbDeployLog_id 0
    }

    $dbName = $database.Name

    foreach ($target in $database.Target)
    {
        Set-Location $startlocation
        
        $targetName = $target.Name
        $targetServer = $target.Server
    
        Log (" Target Server = '" + $targetServer + "'; db = '" + $targetName + "'")
        
        [int] $target_id = 0
        . LogDeployDatabaseTargetAddStart $dbDeployLog_id $targetServer $targetName $target_id

        $ipuInfo = $null
        $stepRestore = $null
        $stepTestData = $null
        
        foreach ($step in $target.ChildNodes)
        {
            switch ($step.Name)
            {
                "IPUInfo" 	{$ipuInfo = $step}
                "Restore" 	{$stepRestore = $step}
                "Upgrade"
                {
                    FailTargetDeployment ("  Error: Upgrade is not supported for IPU databases as a standalone step.")
                    . LogDeployDatabaseTargetAddEnd $target_id 0
                    break
                }
                "TestData"	{$stepTestData = $step}
                default		
                {
                    FailTargetDeployment ("  Error: Unknown element - " + $step.Name)
                    . LogDeployDatabaseTargetAddEnd $target_id 0
                    break
                }
            }
        }

        if ($ipuInfo -ne $null)
        {
            #$ipuBuildType = $ipuInfo.BuildType
            #$ipuRestoreType = $ipuInfo.RestoreType
            #$ipuManifest = $ipuInfo.Manifest
            #$ipuEnvDataScript = $ipuInfo.EnvDataScript
            
            . .\DeployIPU.ps1 $targetServer $dbName $targetName -ipuInfoXml $ipuInfo > $outfile
            Get-Content $outfile
        }
        elseif ($stepRestore -ne $null)
        {
            # Restore step is silently ignored if Deploy step is defined
            
            RestoreDatabase $dbName $targetServer $targetName $stepRestore	
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0
                continue 
            }
        }
            
        if ($stepTestData -ne $null)
        {
            trap
            {
                "TestData step trap"
                FailTargetDeployment ("Exception: " + $_)
                . LogDeployDatabaseTargetAddEnd $target_id 0
                Pop-Location
            }
            
            if ($dbName -eq "Configuration")
            {
                # first make sure environment is set properly
                if ($ipuInfo -eq $null)
                {
                    . .\DeployIPU.ps1 $targetServer $dbName $targetName "Release" "RestoreAlways" "" "" $null $false
                }

                # GPogulsky 7/10/12 - don't push into Configuration tree
                # we'll store Air test overrides for Configuration in our tree
                # under buildsystem\AutoDeploy\Overrides
                #
                #Push-Location "..\..\..\db\databases\CrossFunction\Configuration"
                ApplyTestData $dbName $targetServer $targetName $stepTestData	
            }
            else
            {
                Push-Location "..\..\databases\$dbName"
                ApplyTestData $dbName $targetServer $targetName $stepTestData	
            }

            Pop-Location
            
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0
                continue 
            }
        }
        
        "LogDeployDatabaseTargetAddEnd $target_id 1"
        . LogDeployDatabaseTargetAddEnd $target_id 1
    }
    
    . LogDeployDatabaseEnd $dbDeployLog_id 1
}

function ProcessDatabasePS ([Xml.XmlElement] $database, [string] $psbuildversion)
{
    trap 
    {
        FailTargetDeployment("Exception: " + $_)
        . LogDeployDatabaseEnd $dbDeployLog_id 0
        Pop-Location
    }

    # Assuming start location is depot\agtexpe\buildsystem\autodeploy
    
    if ($psbuildversion -eq "1")
    {
        # go into the database
        $workLocation = "..\..\databases\$dbName"
        $buildLocation = ".\main\BatchJobs\Build"
        $testDataLocation = "."
    }
    elseif ($psbuildversion -eq "2") 
    {
        # go up into BuildSystem
        $workLocation = ".."
        $buildLocation = "."
        $testDataLocation = "..\databases\$dbName\main"
    }
    else
    {
        throw ("  Error: Unknown version element - " + $psbuildversion)
    }
    
    foreach ($target in $database.Target)
    {
        Set-Location $startlocation
        Push-Location $workLocation
        
        $targetDeploymentFailed = $false
        
        $targetName = $target.Name
        $targetServer = $target.Server
        
        Log (" Target Server = '" + $targetServer + "'; db = '" + $targetName + "'")
        
        [int] $target_id = 0
        . LogDeployDatabaseTargetAddStart $dbDeployLog_id $targetServer $targetName $target_id
        
        $ipuInfo = $target.IPUInfo
        
        # if we are here $buildSystem -eq "PS")
        if ($ipuInfo -ne $null)
        {
            FailTargetDeployment ("  Error: Misconfigured Target - targets not marked IPU should not have IPUInfo element.");
            . LogDeployDatabaseTargetAddEnd $target_id 0
            continue
        }
        
        $stepDeploy = $null
        $stepRestore = $null
        $stepUpgrade = $null
        $stepTestData = $null
        $stepDeployInt = 0
        $stepRestoreInt = 0
        $stepUpgradeInt = 0
        $stepTestDataInt = 0
    
        foreach ($step in $target.ChildNodes)
        {
            switch ($step.Name)
            {
                "Deploy" 	{$stepDeploy = $step; $stepDeployInt = 1}
                "Restore" 	{$stepRestore = $step; $stepRestoreInt = 1}
                "Upgrade"	{$stepUpgrade = $step; $stepUpgradeInt = 1}
                "TestData"	{$stepTestData = $step; $stepTestDataInt = 1}
                default		
                {
                    FailTargetDeployment ("  Error: Unknown element - " + $step.Name)
                    . LogDeployDatabaseTargetAddEnd $target_id 0 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
                    break
                }
            }
        }
        
        if ($targetDeploymentFailed)
        {
            continue
        }
        
        if ($stepDeploy -ne $null)
        {
            Push-Location $buildLocation
            DeployDatabase $dbName $targetServer $targetName $stepDeploy $psbuildversion
            Pop-Location
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
                continue 
            }
        }
        elseif ($stepRestore -ne $null)
        {
            # Restore step is silently ignored if Deploy step is defined
            Push-Location 
            RestoreDatabase $dbName $targetServer $targetName $stepRestore	
            Pop-Location
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
                continue 
            }
        }
        
        if ($stepUpgrade -ne $null)
        {
            Push-Location $buildLocation
            UpgradeDatabase $dbName $targetServer $targetName $stepUpgrade $psbuildversion
            Pop-Location
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
                continue 
            }
        }
        
        if ($stepTestData -ne $null)
        {
            Push-Location $testDataLocation
            Get-Location
            ApplyTestData $dbName $targetServer $targetName $stepTestData	
            Pop-Location
            if ($targetDeploymentFailed) 
            { 
                . LogDeployDatabaseTargetAddEnd $target_id 0 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
                continue 
            }
        }
        
        "LogDeployDatabaseTargetAddEnd $target_id 1 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt"
        . LogDeployDatabaseTargetAddEnd $target_id 1 $stepDeployInt $stepRestoreInt $stepUpgradeInt $stepTestDataInt
    }

    Log ("")
    Log (" End of Targets processing ")
    Log ("")

    . LogDeployDatabaseEnd $dbDeployLog_id 1

    Pop-Location
}

function DetectVersion ([string] $dbName)
{
    $v1path = "..\..\databases\$dbName\main\Invoke-Build.ps1"

    if (Test-Path $v1path)
    {
        return "1"
    }
    else
    {	
        return "2"
    }
}

function ProcessDatabase ([Xml.XmlElement] $database)
{
    $dbName = $database.Name
    $path = $database.Path
    $buildSystem = $database.BuildSystem 
    
    if ($buildSystem -eq $null)
    {
        $buildSystem = "PS"
    }
    
    Log ("Database " + $dbName + " " + $path)
    Log (" (BuildSystem " + $buildSystem + ")")
    Log ("")
    Log (" Processing Targets ")
    
    [int] $db_id = 0
    
    if ($buildSystem -eq "PS")
    {
        $psbuildversion = DetectVersion $dbName
        Log (" Using PS build-system v." + $psbuildversion) 

        . LogDeployDatabaseStart $deploy_id $dbName $psbuildversion $db_id $dbDeployLog_id
        ProcessDatabasePS $database $psbuildversion
    }
    elseif ($buildSystem -eq "IPU")
    {
        . LogDeployDatabaseStart $deploy_id $dbName "IPU" $db_id $dbDeployLog_id
        ProcessDatabaseIPU $database
    }
    else
    {
        throw "Error: Unknown build system: " + $buildSystem
    }
}

########################################################################
# Script execution starts here
########################################################################

# Exception Handler
trap 
{
    Log("Exception: " + $_)
    Pop-Location
    Stop-Transcript
    $logfilename = $transcript
    if ($deploy_id > 0) { . LogDeployEnd $deploy_id 0 }
    Finalize "There were errors during deployment." "Deployment SUCCEEDED." $mailto
    break
}


$dt = Get-Date
$transcript = "AutoDeploy_"+$dt.ToString("MMddyyhhmmss")+"_transcript.log"
Start-Transcript -Path $transcript

# Make sure we always start from the script location
""
$invocation = (Get-Item $MyInvocation.InvocationName).DirectoryName
Push-Location $invocation
""
"ParameterSet: " + $PsCmdLet.ParameterSetName
""

# Get the library functions
. ..\FuncLibrary.ps1

$outfilename = "out_" + $dt.ToString("MMddyyhhmmssfff") + ".txt"
$outfile = New-Item -ItemType file "$outfilename" -Force
$outfilename = $outfile.FullName 

$startlocation = Get-Location

$runSqlScripts = (Get-Item "..\RunSqlScripts.ps1").FullName

# Check paramters, and if 'alternative' set is used
# construct config file name from alternative parameters
switch ($PsCmdLet.ParameterSetName)
{
    "main"
    {
        if ($deployUser -eq "") { $deployUser = $env:USERNAME }
        $configFileForLogging = $configFile
        break
    }
    "alternate"
    {
        if (!$deploymentConfig.EndsWith(".xml")) { $deploymentConfig = $deploymentConfig + ".xml" }
        $configFile = $invocation + "\Configuration\" + $deploymentConfig
        $configFileForLogging = "\Configuration\" + $deploymentConfig
        $deployUser = $deploymentUser
        break
    }
}

"Deploy script version " + $autoDeployVersion
"Configuration file: $configFile"
Log ("")
"Invocation path: " + $invocation
""

# DB Logging
. .\LogLibrary.ps1

[int] $finalResult = 1

[int] $deploy_id = 0
. LogDeployStart $deployUser $configFileForLogging $deploy_id

if (!(Test-Path $configFile))
{
    throw "Error: $configFile does not exist!"
}

$configuration =[xml] (Get-Content $configFile )

foreach ($database in $configuration.Deployment.DB)
{
    # Always start in start location
    Set-Location $startlocation
    
    ProcessDatabase $database
    
    Log
    Log
    Log
}

Stop-Transcript

$logfilename = $transcript

. Finalize "There were errors during deployment." "Deployment SUCCEEDED." $mailto
"finalResult = $finalResult"

Pop-Location

. LogDeployEnd $deploy_id $finalResult


