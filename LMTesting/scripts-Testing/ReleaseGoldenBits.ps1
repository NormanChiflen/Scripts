# Script to copy Golden Bits to servers

# Getting parameters from calling process
param($rcpath,$goldpath,[switch]$move)

$ScriptPath = $null
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

Function Get-ScriptHelp
{
    write-host "`nDisplaying help...`n"
    write-host "SCRIPT: ReleaseGoldenBits.ps1"
    write-host "PURPOSE: Copies Golden Bits to servers`n"
    write-host "USAGE:"
    write-host "    .\ReleaseGoldenBits.ps1"
	write-host "      -rcpath '\\server\share\releasecandidatebuild'"
	write-host "      -goldpath '\\server\share\releasebuild'"
	write-host "      -move`n"
    write-host "WHERE:`n"
    write-host " -rcpath      (Required) Path to source (release candidate) build to be copied."
    write-host " -goldpath    (Required) Path to destination (golden/release) folder."
	write-host " 			    NOTE: Specify the top-level folder. "
	write-host " -move        (Optional) Delete source folder after copying to destination folder.`n"
    exit 1
}

# Returning help if rcpath argument is missing
if (!$rcpath)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -rcpath argument is missing!"
    Get-ScriptHelp
}

# Returning help if goldpath argument is missing
if (!$goldpath)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -goldpath argument is missing!"
    Get-ScriptHelp
}

# Writing parameters
write-host "`nParameters:"
write-host "RC (source) path: '$rcpath'"
write-host "Golden (destination) path: '$goldpath'"
write-host "Move: '$move'"

# Verifying RC path
if (!(Test-Path -path "$rcpath"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: RC path '$rcpath' does not exist."
    exit 1
}

# Creating Golden path folder or failing if it already exists
if (!(Test-Path -path "$goldpath"))
{
    Write-Host "`n[" (get-date -format HH:mm:ss) "] Golden path '$goldpath' does not exist, creating..."
	new-item -type directory -path $goldpath -erroraction "silentlycontinue" | out-null
	trap { $error[0].Exception.ToString() }
	if ($error)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error"
		Write-Host -foregroundcolor Red "Failed to create Golden path '$goldpath'."
		exit 1
	}
	Write-Host "`n[" (get-date -format HH:mm:ss) "] Golden path created."
}
else
{
	# Fail if golden folder path exists
	Write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Golden path '$goldpath' already exists."
	Write-Host -foregroundcolor Red "Cannot copy files to existing Golden path folder."
	exit 1
}

# Copying files
write-host "`n[" (get-date -format HH:mm:ss) "] Copying '$rcpath' to '$goldpath'..."
Write-Host "`n[" (get-date -format HH:mm:ss) "] Running command: 'robocopy /e $rcpath $goldpath'."
robocopy /e $rcpath $goldpath
Write-Host $LASTEXITCODE
if ($LASTEXITCODE -eq 8 -or $LASTEXITCODE -eq 9 -or $LASTEXITCODE -eq 16)
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Copy failed."
	exit 1
}
Write-Host "`n[" (get-date -format HH:mm:ss) "] Copy complete."

# Removing RC folder if -move switch was specified
if ($move)
{
	Write-Host "`n[" (get-date -format HH:mm:ss) "] The '-move' switch was specified. Removing RC folder path '$rcpath'..."
	remove-item -recurse -path $rcpath -force -erroraction "silentlycontinue"
	trap { $error[0].Exception.ToString() }
	if ($error)
	{
		write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: $error"
		Write-Host "`n[" (get-date -format HH:mm:ss) "] Removal of RC folder 'rcpath' failed. Please resolve the issue and manually remove it."
	}
	else
	{
		Write-Host "`n[" (get-date -format HH:mm:ss) "] Removal of RC folder path complete."
	}
}

Write-Host "`n[" (get-date -format HH:mm:ss) "] Release complete."