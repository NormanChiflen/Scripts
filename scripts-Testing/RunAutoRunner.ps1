# Script to check TVA functioning using autorunner.exe

# Getting parameters from calling process
param($path,$dll,$logpath,$servers)

$defaultautorunnerpath = "\\chelt2fil01\Products\Tools\AutoRunner"
$autorunnerexe = "AutoRunner.exe"
$defaultdllname = "Search.dll"

# Full command example
# \\chelt2fil01\Products\Tools\AutoRunner\autorunner.exe -s CHELAIRTVAPM01,CHELAIRTVAPM02 -t Search.DLL  -r \\chelt2fil01\Products\Tools\AutoRunner

Function Get-ScriptHelp
{
    write-host "`nDisplaying help...`n"
    write-host "SCRIPT: RunAutoRunner.ps1"
    write-host "PURPOSE: Deploys MTTSetup bits to a server`n"
    write-host "USAGE:"
    write-host "    .\RunAutoRunner.ps1"
	write-host "      -path `"\\server\share\mtt`""
	write-host "      -ini `"C:\folder\inifile.ini`""
	write-host "      -role `"ROLE`"`n"
    write-host "WHERE:`n"
    write-host " -path    (Required) Path to MTTSetup installation folder."
    write-host " -ini     (Required) Path to MTTSetup .ini file."
    write-host "           Only the file name is required if file exists in MTTSetup folder.`n"
	write-host " -role    (Optional) Role to install as it appears in .ini file."
	write-host "            Ex.: COMPUTERNAME, `"DEPLOY TVA-ALL FarmF`", etc."
	write-host "            Do not include brackets [] when specifying role.`n"
    write-host "            If no role is specified the script will use the computer name.`n"
	write-host "            NOTE: The role or computer name must contain FDS,TVM,TVA,etc."
	write-host "              as part of the name.`n"
    exit 1
}

# Returning help if help argument passed
if ($args -contains "-?" -or $args -contains "-help")
{
    Get-ScriptHelp
}

# Returning help if servers argument is missing
if (!$servers)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -servers argument is missing!"
    Get-ScriptHelp
}

# Verifying executable path

# If no path specified use default
if (!$path)
{
	$path = "$defaultautorunnerpath"
}

# Allowing for relative path 
$path = [io.path]::GetFullPath($path)

# Extracting directory from path if necessary
if ($path.ToLower().EndsWith($autorunnerexe.ToLower()))
{
	$path = [io.path]::GetDirectoryName($path)
}

# Trimming trailing \ if exists
$path = $path.TrimEnd('\')

# Verifying executable exists
$filename = $null
$filename = get-childitem $path -erroraction "silentlycontinue" | where {$_.Name -match "$autorunnerexe"}
if (!$filename)
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: '$path\$autorunnerexe' does not exist."
	exit 1
}

# Verifying dll path

# If no path specified use default
if (!$dll)
{
	$dll = "$path\$defaultdllname"
}

# Verifying dll exists
if (!(Test-Path "$dll"))
{
    if (!(Test-Path "$path\$dll"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: DLL file '$dll' does not exist."
        exit 1
    }
    else
    {
        $dll = "$path\$dll"
    }
}
else
{
	# Allowing for relative path 
	$dll = [io.path]::GetFullPath($dll)
}

# Verifying log path

# If no path specified use default
if (!$logpath)
{
	$logpath = Get-Location | select-object $_.Path
}
# ****Verify if writeable
# Verifying log file path
if (!(Test-Path -path "$logpath"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Log file path '$logpath' does not exist."
    exit 1
}

# Writing parameters
write-host "`nAutoRunner path: '$path'"
write-host "DLL file: '$dll'"
write-host "Servers: '$servers'"
write-host "Log file path: '$logpath'`n"
