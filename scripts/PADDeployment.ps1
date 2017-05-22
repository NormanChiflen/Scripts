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
    write-host "  .\PADDeployment.ps1"
	write-host "    -buildpath '\\server\share\build\deployfiles'"
	write-host "    -destdir 'e:\folder'`n"
	write-host "    -iisusername 'domain\username'"
	write-host "    -iispassword 'password'`n"
	    write-host "WHERE:`n"
    write-host "  -buildpath     (Required) Path to PAD deploy files."
	write-host "  -destdir       (Required) Path to install PAD files on local machine."
	write-host "  -iisusername   (Required) User name for IIS service."
	write-host "  -iispassword   (Required) Password for IIS service.`n"
	write-host "EXAMPLES:`n"
	write-host "  .\PADDeployment.ps1 -buildpath '\\server\share\build\TravelFusionWebSvcIISPublish' -destdir 'E:\TravelFusionWebSvcIISPublish' -iisusername 'karmalab\_travfusesvc' -iispassword 'password'"
	exit 1
}

# Returning help if help argument passed
if ($args -contains "-?" -or $args -contains "-help")
{
    Get-ScriptHelp
}

write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Starting PAD service deployment..."

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
write-host "Destination Path: '$destdir'"
write-host "IIS User Name: '$iisusername'"
write-host "IIS Password: '$iispassword'"

# Stopping W3SVC service if exists, fail if it doesn't exist
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Stopping W3SVC service..."
if (get-service W3SVC -erroraction "silentlycontinue")
{
	if ((get-service W3SVC).status -eq "Stopped")
	{
		write-host "`n[" (get-date -format HH:mm:ss) "] W3SVC service already stopped."
	}
	else
	{
		try 
		{
			Stop-Service W3SVC -force -erroraction "stop"
		}
		catch
		{
			write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error"
			write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Stopping W3SVC service failed."
			exit 1
		}
		while ((get-service W3SVC).status -ne "Stopped")
		{
			write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: W3SVC not stopped yet."
			write-host "Waiting 30 seconds..."
            Start-Sleep -s 30
		}
		write-host "`n[" (get-date -format HH:mm:ss) "] INFO: W3SVC service stopped."
	}
}
else
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: W3SVC service does not exist."
    exit 1
}

# Check for previous installation and remove it
if (Test-Path -path "$destdir")
{
    write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Uninstalling existing PAD service..."
	if (!(Test-Path -path "$destdir\bin\TravelFusionWebSvcIIS.dll"))
	{
	    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$destdir' exists but '$destdir\bin\TravelFusionWebSvcIIS.dll' does not."
	    exit 1
	}
	
	#cd /d %_DESTDIR%\bin
	
	remove-item "$destdir\bin\*.installstate" -force -erroraction "silentlycontinue"
	& $installutilpath /u "$destdir\bin\TravelFusionWebSvcIIS.dll"
	if ($LASTEXITCODE -ne 0)
	{
		# Only issuing a warning for a failed uninstall because this may not be a critical failure.
		write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: Installutil returned non-zero exit code. `n This is ignorable if the service was previously uninstalled.`n Check the results for more information."
	}
	write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Uninstall completed."
	
	# Removing destdir.old folder if it exists
	if (Test-Path -path "$destdir.old")
	{
    	write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Removing '$destdir.old' folder..."
		while (Test-Path -path "$destdir.old")
	    {
			remove-item "$destdir.old" -recurse -force -erroraction "silentlycontinue"
			if ($Error)
			{
	            write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: $Error"
				write-host "Path '$destdir.old' could not be deleted.`n  Trying again in 30 seconds..."
	            Start-Sleep -s 30
			}
		}
		write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Folder removed."
	}
	
	# Renaming destdir folder to destdir.old
	write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Renaming '$destdir' folder to '$destdir.old'..."
	try 
	{
		Rename-Item -path "$destdir" -newname "$destdir.old" -erroraction "stop"
	}
	catch 
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error"
		write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Renaming of '$destdir' folder to '$destdir.old' failed."
		exit 1
	}
	write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Folder renamed."
}

# Copying buildpath to destdir
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Copying '$buildpath' folder to '$destdir'..."
try 
{
	copy-item $buildpath -destination $destdir -recurse -erroraction "stop"
}
catch
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error"
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Copying '$buildpath' folder to '$destdir' failed."
	exit 1
}
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Folder copied."

write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Installing PAD service..."
if (!(Test-Path -path "$destdir\bin\TravelFusionWebSvcIIS.dll"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$destdir\bin\TravelFusionWebSvcIIS.dll' does not exist."
    exit 1
}

#cd /d %_DESTDIR%\bin

remove-item "$destdir\bin\*.installstate" -force
& $installutilpath /i /iis7.applicationpool.processmodel.UserName=$iisusername /iis7.applicationpool.processmodel.password=$iispassword /IIS7.ApplicationPool.ProcessModel.MaxProcesses=4 /AppCfg.AppLogDir=e:\TravFuseLogs "$destdir\bin\TravelFusionWebSvcIIS.dll"
if ($LASTEXITCODE -ne 0)
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Installutil returned non-zero exit code."
	exit 1
}
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Install completed."

# Starting W3SVC service if exists, fail if it doesn't exist
write-host "`n[" (get-date -format HH:mm:ss) "] INFO: Starting W3SVC service..."
if (get-service W3SVC -erroraction "silentlycontinue")
{
	if ((get-service W3SVC).status -eq "Running")
	{
		write-host "`n[" (get-date -format HH:mm:ss) "] W3SVC service already running."
	}
	else
	{
		try 
		{
			Start-Service W3SVC -erroraction "stop"
		}
		catch
		{
			write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: $error"
			write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Starting W3SVC service failed."
			exit 1
		}
		while ((get-service W3SVC).status -ne "Running")
		{
			write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: W3SVC not started yet."
			write-host "Waiting 30 seconds..."
            Start-Sleep -s 30
		}
		write-host "`n[" (get-date -format HH:mm:ss) "] INFO: W3SVC service started."
	}
}
else
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: W3SVC service does not exist."
    exit 1
}

write-host -foregroundcolor Green "`n[" (get-date -format HH:mm:ss) "] INFO: PAD service deployment completed successfully."
exit 0



