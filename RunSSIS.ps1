# ---------------------------------------------------------------------------
### <Script>
### <Author>
### Chad Miller 
### </Author>
### <Description>
### Executes a SQL Server Integrations Services package for both server and file system storage types.
### Optionally Resets a Package Configuration connection string named "SSISCONFIG" to new server location.
### Also includes optional processing of external configuration file.
### </Description>
### <Usage>
###  -------------------------- EXAMPLE 1 --------------------------
### ./RunSSIS.ps1 -path Z002_SQL1\sqlpsx -serverName 'Z002\SQL1'
###
### This command will execute package sqlpsx on the server Z002\SQL1
###
###  -------------------------- EXAMPLE 2 --------------------------
### ./RunSSIS.ps1 -path Z002_SQL1\sqlpsx -serverName 'Z002\SQL1' -SSISCONFIG 'Z002\SQL1'
###
### This command will execute as in Example 1 and using SSISCONFIG on Z002\SQL1 regardless of the SSISCONFIG location defined in the package
###
###  -------------------------- EXAMPLE 3 --------------------------
### ./RunSSIS.ps1 -path Z002_SQL1\sqlpsx -serverName Z002\SQL1 -configFile 'C:\SSISConfig\sqlpsx.xml' 
###
### This command will execute the package as in Example 1 and process and configuration file
###
###  -------------------------- EXAMPLE 4 --------------------------
### ./RunSSIS.ps1 -path 'C:\SSIS\sqlpsx.dtsx'
###
### This command will execute the package sqlpsx.dtsx located on the file system
###
###  -------------------------- EXAMPLE 5 --------------------------
### ./RunSSIS.ps1 -path 'C:\SSIS\sqlpsx.dtsx -nolog
###
### This command will execute the package sqlpsx.dtsx located on the file system and skip Windows Event logging
###
### </Usage>
### </Script>
# ---------------------------------------------------------------------------

param($path=$(throw 'path is required.'), $serverName, $configFile, $SSISCONFIG, [switch]$nolog)

# Note: SSIS is NOT backwards compatible. At the beginning of the script you�ll need to comment/uncomment the specific assembly
# to load 2005 or 2008. Default of the script is set to 2005 
[reflection.assembly]::Load("Microsoft.SqlServer.ManagedDTS, Version=9.0.242.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") > $null
#[Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft SQL Server\90\SDK\Assemblies\Microsoft.SQLServer.ManagedDTS.dll") > $null
#[reflection.assembly]::Load("Microsoft.SqlServer.ManagedDTS, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") > $null
#[Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft SQL Server\100\SDK\Assemblies\Microsoft.SQLServer.ManagedDTS.dll") > $null
#[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ManagedDTS") > $null

#######################
function New-ISApplication
{
   new-object ("Microsoft.SqlServer.Dts.Runtime.Application") 

} #New-ISApplication

#######################
function Test-ISPath
{
    param([string]$path=$(throw 'path is required.'), [string]$serverName=$(throw 'serverName is required.'), [string]$pathType='Any')

    #If serverName contains instance i.e. server\instance, convert to just servername:
    $serverName = $serverName -replace "\\.*"

    #Note: Don't specify instance name

    $app = New-ISApplication

    switch ($pathType)
    {
        'Package' { trap { $false; continue } $app.ExistsOnDtsServer($path,$serverName) }
        'Folder'  { trap { $false; continue } $app.FolderExistsOnDtsServer($path,$serverName) }
        'Any'     { $p=Test-ISPath $path $serverName 'Package'; $f=Test-ISPath $path $serverName 'Folder'; [bool]$($p -bor $f)}
        default { throw 'pathType must be Package, Folder, or Any' }
    }

} #Test-ISPath

#######################
function Get-ISPackage
{
    param([string]$path, [string]$serverName)

    #If serverName contains instance i.e. server\instance, convert to just servername:
    $serverName = $serverName -replace "\\.*"

    $app = New-ISApplication

    #SQL Server Store
    if ($path -and $serverName)
    { 
        if (Test-ISPath $path $serverName 'Package')
        { $app.LoadFromDtsServer($path, $serverName, $null) }
        else
        { Write-Error "Package $path does not exist on server $serverName" }
    }
    #File Store
    elseif ($path -and !$serverName)
    { 
        if (Test-Path -literalPath $path)
        { $app.LoadPackage($path, $null) }
        else
        { Write-Error "Package $path does not exist" }
    }
    else
    { throw 'You must specify a file path or package store path and server name' }
    
} #Get-ISPackage

#######################
function Set-ISConnectionString
{
    param($package=$(throw 'package is required.'), $connectionInfo=$(throw 'value is required.'))

    foreach ($i in $connectionInfo.GetEnumerator())
    {
        $name = $($i.Key); $value = $($i.Value);
        Write-Verbose "Set-ISConnectionString name:$name value:$value "
        $connectionManager = $package.connections | where {$_.Name -eq "$name"}
        Write-Verbose "Set-ISConnectionString connString1:$($connectionManager.ConnectionString)"
        if ($connectionManager)
        {
            $connString = $connectionManager.ConnectionString
            Write-Verbose "Set-ISConnectionString connString:$connString"
            $connString -match "^Data Source=(?<server>[^;]+);" > $null
            $newConnString = $connString -replace $($matches.server -replace "\\","\\"),$value
            Write-Verbose "Set-ISConnectionString newConnString:$newConnString"
            if ($newConnString)
            { $connectionManager.ConnectionString = $newConnString }
        }
    }

} #Set-ISConnectionString

#######################
#MAIN

Write-Verbose "$MyInvocation.ScriptName path:$path serverName:$serverName configFile:$configFile SSISCONFIG:$SSISCONFIG nolog:$nolog.IsPresent"

if (!($nolog.IsPresent))
{ 
    $log = Get-EventLog -List | Where-Object { $_.Log -eq "Application" }
    $log.Source = $MyInvocation.ScriptName 
    $log.WriteEntry("Starting:$path",'Information') 
}


$package = Get-ISPackage $path $serverName

if ($package)
{
    if ($SSISCONFIG)
    { Set-ISConnectionString $package @{SSISCONFIG=$SSISCONFIG} }

    if ($configFile)
    { $package.ImportConfigurationFile("$configFile") }

    #$connectionManager = $package.connections | where {$_.Name -eq "SSISCONFIG"}
    #$connString = $connectionManager.ConnectionString
    #Write-Verbose "***connString:$connString"

    $package.Execute()

    if ($?)
    { 
        if (!($nolog.IsPresent)) { $log.WriteEntry("Completed:$path",'Information') }
    }
    else
    {
        if (!($nolog.IsPresent)) { $log.WriteEntry("Abend:$path:$Error[0]",'Error') }
    }
}
else
{
    if (!($nolog.IsPresent)) { $log.WriteEntry("Abort:$path:$Error[0]",'Error') }
    throw ('CannotLoadPackage')
}
#MAIN
#######################