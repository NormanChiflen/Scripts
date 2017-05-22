# Script to deploy EMain on servers

# Getting parameters from calling process
param($path,$ini)

$ScriptPath = $null
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

Function Get-ScriptHelp
{
    write-host "`nDisplaying help...`n"
    write-host "SCRIPT: DeployEMain.ps1"
    write-host "PURPOSE: Deploys EMain bits to a server`n"
    write-host "USAGE:"
    write-host "    .\DeployEMain.ps1 -path `"\\server\share\mtt`" -ini `"C:\folder\inifile.ini`"`n"
    write-host "WHERE:`n"
    write-host " -path    (Required) Path to MTTSetup installation folder."
    write-host " -ini     (Optional) Path to MTTSetup .ini file."
    write-host "           Only file name is required if file exists in MTTSetup folder."
    write-host "           Script will use default T2 file if not specified.`n"
    exit 1
}

# FDS Role
Function Set-FDSTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$Role' tasks..."
      
    # Making sure Set-ServiceState script exists and setting path
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-error "`nERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
        exit 1
    }
       
    # Stopping fds service if exists
    if (get-service fdsservice -erroraction "silentlycontinue")
    {
        & "$ScriptPath\Set-ServiceState.ps1" stop fdsservice
    }
   
    # Removing fds pubs
    # Getting FDSPublications share local path
    if ($FDSPubsPath = get-wmiobject -class win32_share -filter "Name = 'FDSPublications'" | 
        Select-Object -ExpandProperty Path)
    {
        # Removing pubs files if they exist
        while (Test-Path -path "$FDSPubsPath\V30")
        {
            write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs folder '$FDSPubsPath\V30'..."
            remove-item "$FDSPubsPath\V30" -recurse -force
            if (Test-Path -path "$FDSPubsPath\V30")
            {
                write-host "`nPath '$FDSPubsPath\V30' could not be deleted.`nTrying again in 30 seconds..."
                Start-Sleep -s 30
            }
            write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
        }
        
        # Create FDSPublications if it doesn't exist
        if (!(Test-Path -path "$FDSPubsPath"))
        {
            write-host "`n[" (get-date -format HH:mm:ss) "] '$FDSPubsPath' folder defined by FDSPublications share does not exist. Creating..."
            new-item -path $FDSPubsPath -type "directory" | out-null
        }
    }
    else
    {
        # Create share if not exists
        write-host "`n[" (get-date -format HH:mm:ss) "] FDSPublications share does not exist. Creating..."
        
        # Finding fdsroot of local machine from ini file
        $FDSRoot = $null
        $found = $false
        $FileContent = $null
        $FileContent = get-content $iniFile
        $line = $null
        $search = $null
        foreach ($line in $FileContent)
        {
            if ($line -eq "[$ComputerName]")
            {
                $found = $true
            }
            
            if ($found)
            {
                $search = "option fdsroot "
                if ($line.StartsWith($search))
                {
                    $FDSRoot = $line.Remove(0,$search.length)
                    break
                }
            }
        }       
        
        # Creating folder if not exists
        if (!(Test-Path -path "$FDSRoot\FDSPublications"))
        {
            write-host "`n[" (get-date -format HH:mm:ss) "] FDS Publications location '$FDSRoot\FDSPublications' does not exist. Creating..."
            new-item -path $FDSRoot -name "FDSPublications" -type "directory" | out-null
        }
        
        # Creating share
        $FDSPubpath = "$FDSRoot\FDSPublications"
        $name = "FDSPublications"
        $type = 0
        $password = ""
        $description = ""
        $max = $null
        $access = $null
        invoke-wmimethod -class win32_share -name Create -argumentlist $access, $description, $max, $name, $password, $FDSPubpath, $type  | out-null
        
        # Removing pubs files if they exist
        if (Test-Path -path "$FDSPubsPath\V30")
        {
            write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs..."
            remove-item "$FDSPubsPath\V30" -recurse -force
        }     
    }
    
    # Adding ExpediaSys to local system's path environment variable
    if (!($env:path -contains "ExpediaSys"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] Adding C:\ExpediaSys to path environment variable..."
        [Environment]::SetEnvironmentVariable("path", "$env:path;C:\ExpediaSys", "Machine")
    }
    
    # Running MTTSetup
    write-host "`n[" (get-date -format HH:mm:ss) "] Running command '`"$path\setup.exe`" /u /f `"$ini`" /s $ComputerName'..."
    & "$path\setup.exe" /u /f "$ini" /s $ComputerName
    write-host "`n[" (get-date -format HH:mm:ss) "] Command completed."
    
    # Checking MTTSetup log for errors
    write-host "`n[" (get-date -format HH:mm:ss) "] Checking MTTSetup log in C:\Windows\Temp for installation result..."
    $MTTSetupLogFile = $null
    if ($MTTSetupLogFile = get-childitem C:\Windows\Temp\mttsetup*.log | 
        sort-object LastWriteTime -descending | 
        select-object -ExpandProperty Name -first 1)
        {
            $MTTSetupLogFile = "C:\Windows\Temp\$MTTSetupLogFile"
            write-host "MTTSetup log: '$MTTSetupLogFile'"
            $FileContent = $null
            $FileContent = get-content $MTTSetupLogFile
            $line = $null
            $MTTSetupSucceeded = $false
            foreach ($line in $FileContent)
            {
                if ($line -match "Setup succeeded")
                {
                    $MTTSetupSucceeded = $true
                }
            }
            if (!$MTTSetupSucceeded)
            {
                write-host "`n[" (get-date -format HH:mm:ss) "]"
                write-error  "ERROR: MTTSetup did not succeed. Check MTTSetup log: '$MTTSetupLogFile' for details."
                exit 1
            }
            write-host "`n[" (get-date -format HH:mm:ss) "] MTTSetup completed successfully."
        }
    else
    {
        write-host "`n[" (get-date -format HH:mm:ss) "]"
        write-error "ERROR: Could not find MTTSetup log file."
    }
    
    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# TVM Role
Function Set-TVMTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$Role' tasks..."
           
    # Making sure Set-ServiceState script exists
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-error "`nERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
        exit 1
    }
    
    # Stopping mstravob service if exists
    if (get-service mstravob -erroraction "silentlycontinue")
    {
        & "$ScriptPath\Set-ServiceState.ps1" stop mstravob
    }
    
    # Stopping *sp services if exist
    if (get-service *sp -erroraction "silentlycontinue")
    {
        & "$ScriptPath\Set-ServiceState.ps1" stop *sp
    }
    
    # Removing fds pubs if exist
    # Finding fdsroot of local machine from ini file
    $FDSRoot = $null
    $found = $false
    $FileContent = $null
    $FileContent = get-content $iniFile
    $line = $null
    $search = $null
    foreach ($line in $FileContent)
    {
        if ($line -eq "[$ComputerName]")
        {
            $found = $true
        }
        
        if ($found)
        {
            $search = "option fdsroot "
            if ($line.StartsWith($search))
            {
                $FDSRoot = $line.Remove(0,$search.length)
                break
            }
        }
    }
    
    # Creating folder if not exists
    if (!(Test-Path -path "$FDSRoot"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] FDS root location '$FDSRoot' does not exist. Creating..."
        new-item -path $FDSRoot -type "directory" | out-null
    }
    
    # Removing pubs files if they exist
    if (Test-Path -path "$FDSRoot\FDSSubscriptions")
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs..."
        remove-item "$FDSRoot\FDSSubscriptions" -recurse -force
    } 
	
	# Removing pubs files if they exist
    while (Test-Path -path "$FDSRoot\FDSSubscriptions")
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs folder '$FDSRoot\FDSSubscriptions'..."
        remove-item "$FDSRoot\FDSSubscriptions" -recurse -force
        if (Test-Path -path "$FDSRoot\FDSSubscriptions")
        {
            write-host "`nPath '$FDSRoot\FDSSubscriptions' could not be deleted.`nTrying again in 30 seconds..."
            Start-Sleep -s 30
        }
        write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
    }
    
    # Adding ExpediaSys to local system's path environment variable
    if (!($env:path -contains "ExpediaSys"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] Adding C:\ExpediaSys to path environment variable..."
        [Environment]::SetEnvironmentVariable("path", "$env:path;C:\ExpediaSys", "Machine")
    }
    
    # Running MTTSetup
    write-host "`n[" (get-date -format HH:mm:ss) "] Running command '`"$path\setup.exe`" /u /f `"$ini`" /s $ComputerName'..."
    & "$path\setup.exe" /u /f "$ini" /s $ComputerName
    write-host "`n[" (get-date -format HH:mm:ss) "] Command completed."
    
    # Checking MTTSetup log for errors
    write-host "`n[" (get-date -format HH:mm:ss) "] Checking MTTSetup log in C:\Windows\Temp for installation result..."
    $MTTSetupLogFile = $null
    if ($MTTSetupLogFile = get-childitem C:\Windows\Temp\mttsetup*.log | 
        sort-object LastWriteTime -descending | 
        select-object -ExpandProperty Name -first 1)
        {
            $MTTSetupLogFile = "C:\Windows\Temp\$MTTSetupLogFile"
            write-host "MTTSetup log: '$MTTSetupLogFile'"
            $FileContent = $null
            $FileContent = get-content $MTTSetupLogFile
            $line = $null
            $MTTSetupSucceeded = $false
            foreach ($line in $FileContent)
            {
                if ($line -match "Setup succeeded")
                {
                    $MTTSetupSucceeded = $true
                }
            }
            if (!$MTTSetupSucceeded)
            {
                write-host  "`n[" (get-date -format HH:mm:ss) "]"
                write-error "ERROR: MTTSetup did not succeed. Check MTTSetup log: '$MTTSetupLogFile' for details."
                exit 1
            }
            write-host "`n[" (get-date -format HH:mm:ss) "] MTTSetup completed successfully."
        }
    else
    {
        write-host "`n[" (get-date -format HH:mm:ss) "]"
        write-error "ERROR: Could not find MTTSetup log file."
    }
    
    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# WEB Role
Function Set-WebTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$Role' tasks..."
    
    # Running MTTSetup
    write-host "`n[" (get-date -format HH:mm:ss) "] Running command '`"$path\setup.exe`" /u /f `"$ini`" /s $ComputerName'..."
    & "$path\setup.exe" /u /f "$ini" /s $ComputerName
    write-host "`n[" (get-date -format HH:mm:ss) "] Command completed."
    
    # Checking MTTSetup log for errors
    write-host "`n[" (get-date -format HH:mm:ss) "] Checking MTTSetup log in C:\Windows\Temp for installation result..."
    $MTTSetupLogFile = $null
    if ($MTTSetupLogFile = get-childitem C:\Windows\Temp\mttsetup*.log | 
        sort-object LastWriteTime -descending | 
        select-object -ExpandProperty Name -first 1)
        {
            $MTTSetupLogFile = "C:\Windows\Temp\$MTTSetupLogFile"
            write-host "MTTSetup log: '$MTTSetupLogFile'"
            $FileContent = $null
            $FileContent = get-content $MTTSetupLogFile
            $line = $null
            $MTTSetupSucceeded = $false
            foreach ($line in $FileContent)
            {
                if ($line -match "Setup succeeded")
                {
                    $MTTSetupSucceeded = $true
                }
            }
            if (!$MTTSetupSucceeded)
            {
                write-host "`n[" (get-date -format HH:mm:ss) "]"
                write-error "ERROR: MTTSetup did not succeed. Check MTTSetup log: '$MTTSetupLogFile' for details."
                exit 1
            }
            write-host "`n[" (get-date -format HH:mm:ss) "] MTTSetup completed successfully."
        }
    else
    {
        write-host "`n[" (get-date -format HH:mm:ss) "]"
        write-error "ERROR: Could not find MTTSetup log file."
    }
    
    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# Returning help if help argument passed
if ($args -contains "-?" -or $args -contains "-help")
{
    Get-ScriptHelp
}

# Returning help if path argument is missing
if (!$path)
{
    write-host
    write-error "ERROR: -path argument is missing!"
    Get-ScriptHelp
}

# Default INI file if none specified
if (!$ini)
{
    $ini = "T2TLS-CoreInf.ini"
}

# Getting local computer name
$ComputerName = $env:computername
If (!$ComputerName)
{
    write-host
    write-error "ERROR: Computer name not found".
    exit 1
}

# Verifying setup path
if (!(Test-Path -path "$path"))
{
    write-host
    write-error "ERROR: Path '$path' does not exist."
    exit 1
}
if (!(Test-Path -path "$path\setup.exe"))
{
    write-host
    write-error "ERROR: Could not find '$path\setup.exe'."
    exit 1
}

# Verifying ini path
if (!(Test-Path "$ini"))
{
    if (!(Test-Path "$path\$ini"))
    {
        write-host
        write-error "ERROR: INI file '$ini' does not exist."
        exit 1
    }
    else
    {
        $iniFile = "$path\$ini"
    }
}
else
{
	$iniFile = $ini
}

# Finding role of local machine from ini file
$found = $false
$FileContent = $null
$FileContent = get-content $iniFile
$line = $null
$RoleFull = $null
$search = $null
foreach ($line in $FileContent)
{
    if ($line -eq "[$ComputerName]")
    {
        $found = $true
    }
    
    if ($found)
    {
        $search = "role "
        if ($line.StartsWith($search))
        {
            $RoleFull = $line.Remove(0,$search.length)
            break
        }
    }
}

# Determining role short name
$Role = $null
if ($RoleFull -match "FDS")
{
    $Role = "FDS"
}
if ($RoleFull -match "JVA")
{
    $Role = "JVA"
}
if ($RoleFull -match "TVA")
{
    $Role = "TVA"
}
if ($RoleFull -match "TVM" -or $RoleFull -match "Travel-All")
{
    $Role = "TVM"
}
if ($RoleFull -match "UTL")
{
    $Role = "UTL"
}
if ($RoleFull -match "WEB" -or $RoleFull -match "Bot-All")
{
    $Role = "WEB"
}
if (!$Role)
{
    write-host
    write-error "ERROR: The role '$RoleFull' was not recognized as a valid role."
    exit 1
}

# Writing parameters
write-host "`nPath: '$path'"
write-host "INI file: '$ini'"
write-host "Computer name: '$ComputerName'"
write-host "Role full name: '$RoleFull'"
write-host "Role short name: '$Role'`n"

<# Future functionality to copy setup folder to local temp folder
# Creating random temp folder name
$TempFolder = "$env:temp\MTTSetup_"+(get-random)
# Making sure to pick an non-existent folder
while (Test-Path -path $TempFolder)
{
    $TempFolder = "$env:temp\"+(get-random)
}

# Copying path files to local temp location
write-host "`nCopying '$path' to '$TempFolder'..."
copy-item $path -destination $TempFolder -recurse

# Clean up temp folder
# remove-item $TempFolder -recurse -force
#>

switch ($Role)
{
    "FDS"
    {
        Set-FDSTasks
    }
    "TVM"
    {
        Set-TVMTasks
    }
	"WEB"
    {
        Set-WEBTasks
    }
    default
    {
        write-host
        write-error "No tasks defined for role '$Role'."
    }
}

exit 0

