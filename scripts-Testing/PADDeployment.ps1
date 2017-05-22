# Getting parameters from calling process
param($buildpath,$destdir,$iisusername,$iispassword)

# Checking Powershell version
Write-Host "`nChecking Powershell version..."
$powershellversion = $PSVersionTable.PSVersion
Write-Host "Version: $powershellversion"
if ($powershellversion -lt "2.0")
{
	
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Powershell version 2.0 or greater required!"
	exit 1
}

$ScriptPath = $null
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

Function Get-ScriptHelp
{
    write-host "`nDisplaying help...`n"
    write-host "SCRIPT: PADDeployment.ps1"
    write-host "PURPOSE: Deploys PAD services to a server`n"
    write-host "USAGE:"
    write-host "    .\PADDeployment.ps1"
	write-host "      -buildpath '\\server\share\build\deployfiles'"
	write-host "      -destdir 'e:\folder'`n"
	write-host "      -iisusername 'domain\username'"
	write-host "      -iispassword 'password'`n"
	    write-host "WHERE:`n"
    write-host " -buildpath		(Required) Path to PAD deploy files."
	write-host " -destdir		(Required) Path to install PAD files on local machine."
	write-host " -iisusername	(Required) User name for IIS service."
	write-host " -iispassword	(Required) Password for IIS service."
	write-host "EXAMPLES:`n"
	write-host "  .\PADDeployment.ps1 -buildpath '\\chelt2fil01\Air\PAD_Build\PAD_Build_20120926.4\Release\bin\Release\TravelFusionWebSvcIISPublish'`n"
	exit 1
}

# Returning help if help argument passed
if ($args -contains "-?" -or $args -contains "-help")
{
    Get-ScriptHelp
}

# Making sure Set-ServiceState script exists
if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
    exit 1
}

write-host -foregroundcolor Green "`n[" (get-date -format HH:mm:ss) "] INFO: Starting PAD service deployment..."

# Setting installutilpath
$WinDir = $env:windir
$installutilpath = "$WinDir\microsoft.net\Framework64\v2.0.50727\installutil.exe"
if (!(Test-Path -path "$installutilpath"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$installutilpath' does not exist."
    exit 1
}

# Returning help if buildpath argument is missing
if (!$buildpath)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -buildpath argument is missing!"
    Get-ScriptHelp
}

# Verifying buildpath
if (!(Test-Path -path "$buildpath"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$buildpath' does not exist."
    exit 1
}

# Returning help if destdir argument is missing
if (!$destdir)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -destdir argument is missing!"
    Get-ScriptHelp
}

# Returning help if destdir argument is missing
if (!$iisusername)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -iisusername argument is missing!"
    Get-ScriptHelp
}

# Returning help if destdir argument is missing
if (!$iispassword)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -iispassword argument is missing!"
    Get-ScriptHelp
}

# Writing parameters
write-host "`nBuild Path: '$buildpath'"
write-host "`nDestination Path: '$destdir'"
write-host "`nIIS User Name: '$iisusername'"
write-host "`nIIS Password: '$iispassword'"

# Stopping IIS service if exists, fail if it doesn't exist
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Stopping IIS service..."
if (get-service w3svc -erroraction "silentlycontinue")
{
    & "$ScriptPath\Set-ServiceState.ps1" stop w3svc
}
else
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: IIS service (w3svc) does not exist."
    exit 1
}

# Check for previous installation and remove it
if (Test-Path -path "$destdir")
{
    write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Uninstalling existing PAD service..."
	if (!(Test-Path -path "$destdir\TravelFusionWebSvcIIS.dll"))
	{
	    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$destdir' exists but '$destdir\TravelFusionWebSvcIIS.dll' does not."
	    exit 1
	}
	
	#cd /d %_DESTDIR%\bin
	
	remove-item "$destdir\*.installstate" -force
	& $installutilpath /u "$destdir\TravelFusionWebSvcIIS.dll"
	if ($LASTEXITCODE -ne 0)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Installutil returned non-zero exit code."
		exit 1
	}
	<#
	if (get-process "installutil" -erroraction "silentlycontinue")
	{
		wait-process -name "installutil" -timeout 120 -erroraction "silentlycontinue"
	}
	#>
	write-host "`n[" (get-date -format HH:mm:ss) "] Uninstall completed."
	
	# Removing destdir.old folder if it exists
    while (Test-Path -path "$destdir.old")
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Removing '$destdir.old' folder..."
        try 
		{
			remove-item "$destdir.old" -recurse -force
		}
        catch
		{
			if (Test-Path -path "$destdir.old")
	        {
	            write-host "`nPath '$destdir.old' could not be deleted.`n  Trying again in 30 seconds..."
	            Start-Sleep -s 30
	        }
		}
    }
	write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
	
	# Renaming destdir folder to destdir.old
	write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Renaming '$destdir' folder to '$destdir.old'..."
	try 
	{
		Rename-Item -path "$destdir" -newname "$destdir.old"
	}
	catch 
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error[0].Exception.ToString()"
		Write-Host "`nRenaming of '$destdir' folder to '$destdir.old' failed."
		exit 1
	}
	write-host "`n[" (get-date -format HH:mm:ss) "] Folder renamed."
}

# Copying buildpath to destdir
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Copying '$buildpath' folder to '$destdir'..."
try 
{
	copy-item $buildpath -destination $destdir -recurse
}
catch
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error[0].Exception.ToString()"
	Write-Host "`nCopying '$buildpath' folder to '$destdir' failed."
	exit 1
}
write-host "`n[" (get-date -format HH:mm:ss) "] Folder copied."

write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Installing PAD service..."
if (!(Test-Path -path "$destdir\TravelFusionWebSvcIIS.dll"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$destdir\TravelFusionWebSvcIIS.dll' does not exist."
    exit 1
}

#cd /d %_DESTDIR%\bin

remove-item "$destdir\*.installstate" -force
& $installutilpath /iis7.applicationpool.processmodel.UserName=$iisusername /iis7.applicationpool.processmodel.password=$iispassword /IIS7.ApplicationPool.ProcessModel.MaxProcesses=4 /AppCfg.AppLogDir=e:\TravFuseLogs "$destdir\TravelFusionWebSvcIIS.dll"
if ($LASTEXITCODE -ne 0)
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Installutil returned non-zero exit code."
	exit 1
}
<#
if (get-process "installutil" -erroraction "silentlycontinue")
{
	wait-process -name "installutil" -timeout 120 -erroraction "silentlycontinue"
}
#>
write-host "`n[" (get-date -format HH:mm:ss) "] Install completed."

# Starting IIS service if exists, fail if it doesn't exist
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Starting IIS service..."
if (get-service w3svc -erroraction "silentlycontinue")
{
    & "$ScriptPath\Set-ServiceState.ps1" start w3svc
	
}
else
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: IIS service (w3svc) does not exist."
    exit 1
}

write-host -foregroundcolor Green "`n[" (get-date -format HH:mm:ss) "] INFO: PAD service deployment completed successfully."
exit 0

