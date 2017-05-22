# Script to deploy using MTTSetup on servers

# Getting parameters from calling process
param($path,$ini,$role)

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
    write-host "SCRIPT: DeployAll.ps1"
    write-host "PURPOSE: Deploys MTTSetup bits to a server`n"
    write-host "USAGE:"
    write-host "    .\DeployAll.ps1"
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
	write-host "EXAMPLES:`n"
	write-host "  EMain:`n"
	write-host "    .\DeployAll.ps1 -path '\\karmalab.net\builds\ECP\LIVE\175_0\mtt' -ini 'T2TLS-CoreInf.ini'`n"
	write-host "  Air:`n"
	write-host "    .\DeployAll.ps1 -path '\\chelt2fil01\DirectedBuilds\depot\agtexpe\products\air\v3.22.0.52\deliverables\depot.agtexpe.products.air\V3.22.0.52\prop' -ini 'AGTDeploy.ini' -role 'Deploy FDS FarmF'"
	write-host "    .\DeployAll.ps1 -path '\\chelt2fil01\DirectedBuilds\depot\agtexpe\products\air\v3.22.0.52\deliverables\depot.agtexpe.products.air\V3.22.0.52\prop' -ini 'AGTDeploy.ini' -role 'DEPLOY TVA-ALL FarmF'`n"
	write-host "  DSAPI:`n"
	write-host "    .\DeployAll.ps1 -path '\\karmalab.net\builds\ECP\LIVE\169_0\mtt' -ini 'ini\t2\dsapi.lab.ini'`n"
    exit 1
}

Function Set-ExpediaSysRegKey
{
    # Adding ExpediaSys to local system's path environment variable
    if (!($env:path -contains "ExpediaSys"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] Adding C:\ExpediaSys to path environment variable..."
        [Environment]::SetEnvironmentVariable("path", "$env:path;C:\ExpediaSys", "Machine")
    }
}

Function Set-RunMTTSetup
{
	# Running MTTSetup
    write-host "`n[" (get-date -format HH:mm:ss) "] Running command '`"$path\setup.exe`" /u /f `"$ini`" /s $role'..."
	& "$path\setup.exe" /u /f "$ini" /s $role
	$MTTSetupReturn = $LASTEXITCODE
    write-host "`n[" (get-date -format HH:mm:ss) "] Command completed."
	
	$MTTSetupSucceeded = $false
	
	# Handling exit return	
	if ($MTTSetupReturn -ne 0)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: MTTSetup returned non-zero exit code."
		$MTTSetupSucceeded = $false
	}
	else
	{
		$MTTSetupSucceeded = $true
	}
  
    # Checking MTTSetup log for errors
    write-host "`n[" (get-date -format HH:mm:ss) "] Getting MTTSetup log in C:\Windows\Temp..."
	$MTTSetupLogFile = $null
	if ($MTTSetupLogFile = get-childitem C:\Windows\Temp\mttsetup*.log | 
        sort-object LastWriteTime -descending | 
        select-object -ExpandProperty Name -first 1)
        {
            $MTTSetupLogFile = "C:\Windows\Temp\$MTTSetupLogFile"
            write-host "Latest MTTSetup log: '$MTTSetupLogFile'"
            $FileContent = $null
            $FileContent = get-content $MTTSetupLogFile
            $line = $null
            foreach ($line in $FileContent)
            {
                if ($MTTSetupReturn -eq 0)
				{
					if ($line -match "Setup succeeded")
	                {
	                    $MTTSetupSucceeded = $true
	                }
				}
            }
            if (!$MTTSetupSucceeded)
            {
				write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: MTTSetup failed. Latest MTTSetup log: '$MTTSetupLogFile'."
            }
            write-host "`n[" (get-date -format HH:mm:ss) "] MTTSetup completed successfully."
        }
    else
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Could not find MTTSetup log file."
    }
    
	if (!$MTTSetupSucceeded)
    {
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Deployment failed. Exiting..."
		exit 1
	}
}

Function Set-ValidateFDS
{
	write-host "`n[" (get-date -format HH:mm:ss) "] Verifying FDS pubs are built..."
	# Getting travbin path from registry
	$TravBinPath=(Get-ItemProperty hklm:\software\wow6432node\expedia).TravBinPath
	$failed = $true
	while ($failed)
	{
		write-host "`n[" (get-date -format HH:mm:ss) "] Running command '`"$TravBinPath\server\fdsservice`" -debug -dump -versiondir'...`n"
		$failed = (&"$TravBinPath\server\fdsservice" -debug -dump -versiondir | select-string -pattern "Failed to find publicationId")
		if (!$failed) { break }
		$line = $null
		foreach ($line in $failed)
		{
			write-host $line -ForegroundColor Yellow
		}
		write-host "`n[" (get-date -format HH:mm:ss) "] FDS pubs are not finished building.`n  Checking again in 2 minutes..."
        Start-Sleep -s 120
	}
	write-host "`n[" (get-date -format HH:mm:ss) "] FDS pubs are built."
}

# FDS Role
Function Set-FDSTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
      
    # Making sure Set-ServiceState script exists and setting path
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
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
                write-host "`nPath '$FDSPubsPath\V30' could not be deleted.`n  Trying again in 30 seconds..."
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
        
		# Finding fdsroot from ini file
	    $FDSRoot = $null
	    $found = $false
	    $FileContent = $null
	    $FileContent = get-content $ini
	    $line = $null
	    $search = $null
	    foreach ($line in $FileContent)
	    {
	        if ($line -eq "[$role]")
	        {
	            $found = $true
				continue
	        }
	        
	        if ($found)
	        {
	            $search = "option fdsroot "
	            if ($line.ToLower().StartsWith($search.ToLower()))
	            {
	                $FDSRoot = $line.Remove(0,$search.length)
	                break
	            }
				# Keeping from searching in next role
				if ($line.StartsWith("["))
	            {
	                break
	            }
	        }
	    }
		# Looking again if [FDSALL] is used if no fdsroot found
		If (!$FDSRoot)
		{
			$found = $false
			$line = $null
			$search = $null
			foreach ($line in $FileContent)
		    {
		        if ($line -eq "[FDSALL]")
		        {
		            $found = $true
					continue
		        }
		        
		        if ($found)
		        {
		            $search = "option fdsroot "
		            if ($line.ToLower().StartsWith($search.ToLower()))
		            {
		                $FDSRoot = $line.Remove(0,$search.length)
		                break
		            }
					# Keeping from searching in next role
					if ($line.StartsWith("["))
		            {
		                break
		            }
		        }
		    }
		}
		# Looking again if [CORE] is used if no fdsroot found
		If (!$FDSRoot)
		{
			$found = $false
			$line = $null
			$search = $null
			foreach ($line in $FileContent)
		    {
		        if ($line -eq "[CORE]")
		        {
		            $found = $true
					continue
		        }
		        
		        if ($found)
		        {
		            $search = "option fdsroot "
		            if ($line.ToLower().StartsWith($search.ToLower()))
		            {
		                $FDSRoot = $line.Remove(0,$search.length)
		                break
		            }
					# Keeping from searching in next role
					if ($line.StartsWith("["))
		            {
		                break
		            }
		        }
		    }
		}
		If (!$FDSRoot)
		{
			write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: 'FDSPublications' share does not exist and no 'option fdsroot' defined in '$ini' to create it."
	    	exit 1
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
	Set-ExpediaSysRegKey
	
	# Running MTTSetup
	Set-RunMTTSetup
	
	# Making sure FDS pubs are built before continuing
	Set-ValidateFDS

    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# JVA Role
Function Set-JVATasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
    
	write-host "`n[" (get-date -format HH:mm:ss) "] No '$role' tasks defined."
}

# TVA Role
Function Set-TVATasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
           
    # Making sure Set-ServiceState script exists
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
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
	
	# Stopping airinterfacesvc services if exist
    if (get-service airinterfacesvc -erroraction "silentlycontinue")
    {
        & "$ScriptPath\Set-ServiceState.ps1" stop airinterfacesvc
    }
    
    # Removing fds pubs if exist

	# Finding fdsroot from ini file
    $FDSRoot = $null
    $found = $false
    $FileContent = $null
    $FileContent = get-content $ini
    $line = $null
    $search = $null
    foreach ($line in $FileContent)
    {
        if ($line -eq "[$role]")
        {
            $found = $true
			continue
        }
        
        if ($found)
        {
            $search = "option fdsroot "
            if ($line.ToLower().StartsWith($search.ToLower()))
            {
                $FDSRoot = $line.Remove(0,$search.length)
                break
            }
			# Keeping from searching in next role
			if ($line.StartsWith("["))
            {
                break
            }
        }
    }
	# Looking again if [CORE] is used if no fdsroot found
	If (!$FDSRoot)
	{
		$found = $false
		$line = $null
		$search = $null
		foreach ($line in $FileContent)
	    {
	        if ($line -eq "[CORE]")
	        {
	            $found = $true
				continue
	        }
	        
	        if ($found)
	        {
	            $search = "option fdsroot "
	            if ($line.ToLower().StartsWith($search.ToLower()))
	            {
	                $FDSRoot = $line.Remove(0,$search.length)
	                break
	            }
				# Keeping from searching in next role
				if ($line.StartsWith("["))
	            {
	                break
	            }
	        }
	    }
	}	
	If (!$FDSRoot)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: No 'option fdsroot' defined in '$ini' file for '$role' or '[CORE]'."
    	exit 1
	}
    
    # Creating folder if not exists
    if (!(Test-Path -path "$FDSRoot"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] FDS root location '$FDSRoot' does not exist. Creating..."
        new-item -path $FDSRoot -type "directory" | out-null
    }
	else
	{	
		# Removing pubs files if they exist
	    while (Test-Path -path "$FDSRoot\FDSSubscriptions")
	    {
	        write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs folder '$FDSRoot\FDSSubscriptions'..."
	        remove-item "$FDSRoot\FDSSubscriptions" -recurse -force
	        if (Test-Path -path "$FDSRoot\FDSSubscriptions")
	        {
	            write-host "`nPath '$FDSRoot\FDSSubscriptions' could not be deleted.`n  Trying again in 30 seconds..."
	            Start-Sleep -s 30
	        }
	        write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
	    }
	}
    
    # Adding ExpediaSys to local system's path environment variable
	Set-ExpediaSysRegKey
	
	# Running MTTSetup
	Set-RunMTTSetup
	
	# Making sure FDS pubs are built before continuing
	Set-ValidateFDS

    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    #restart-computer -force
}

# TVD Role
Function Set-TVDTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
           
    # Making sure Set-ServiceState script exists
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
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
	
    # Finding fdsroot from ini file
    $FDSRoot = $null
    $found = $false
    $FileContent = $null
    $FileContent = get-content $ini
    $line = $null
    $search = $null
    foreach ($line in $FileContent)
    {
        if ($line -eq "[$role]")
        {
            $found = $true
			continue
        }
        
        if ($found)
        {
            $search = "option fdsroot "
            if ($line.ToLower().StartsWith($search.ToLower()))
            {
                $FDSRoot = $line.Remove(0,$search.length)
                break
            }
			# Keeping from searching in next role
			if ($line.StartsWith("["))
            {
                break
            }
        }
    }
	If (!$FDSRoot)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: No 'option fdsroot' defined in '$ini' file for '$role'."
    	exit 1
	}
    
    # Creating folder if not exists
    if (!(Test-Path -path "$FDSRoot"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] FDS root location '$FDSRoot' does not exist. Creating..."
        new-item -path $FDSRoot -type "directory" | out-null
    }
	else
	{    
		# Removing pubs files if they exist
	    while (Test-Path -path "$FDSRoot\FDSSubscriptions")
	    {
	        write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs folder '$FDSRoot\FDSSubscriptions'..."
	        remove-item "$FDSRoot\FDSSubscriptions" -recurse -force
	        if (Test-Path -path "$FDSRoot\FDSSubscriptions")
	        {
	            write-host "`nPath '$FDSRoot\FDSSubscriptions' could not be deleted.`n  Trying again in 30 seconds..."
	            Start-Sleep -s 30
	        }
	        write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
	    }
	}
    
    # Adding ExpediaSys to local system's path environment variable
	Set-ExpediaSysRegKey
	
	# Running MTTSetup
	Set-RunMTTSetup
	
	# Making sure FDS pubs are built before continuing
	Set-ValidateFDS

    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# TVM Role
Function Set-TVMTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
           
    # Making sure Set-ServiceState script exists
    if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
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
	
    # Finding fdsroot from ini file
    $FDSRoot = $null
    $found = $false
    $FileContent = $null
    $FileContent = get-content $ini
    $line = $null
    $search = $null
    foreach ($line in $FileContent)
    {
        if ($line -eq "[$role]")
        {
            $found = $true
			continue
        }
        
        if ($found)
        {
            $search = "option fdsroot "
            if ($line.ToLower().StartsWith($search.ToLower()))
            {
                $FDSRoot = $line.Remove(0,$search.length)
                break
            }
			# Keeping from searching in next role
			if ($line.StartsWith("["))
            {
                break
            }
        }
    }
	# Looking again if [TVMALL] is used if no fdsroot found
	If (!$FDSRoot)
	{
		$found = $false
		$line = $null
		$search = $null
		foreach ($line in $FileContent)
	    {
	        if ($line -eq "[TVMALL]")
	        {
	            $found = $true
				continue
	        }
	        
	        if ($found)
	        {
	            $search = "option fdsroot "
	            if ($line.ToLower().StartsWith($search.ToLower()))
	            {
	                $FDSRoot = $line.Remove(0,$search.length)
	                break
	            }
				# Keeping from searching in next role
				if ($line.StartsWith("["))
	            {
	                break
	            }
	        }
	    }
	}
	If (!$FDSRoot)
	{
		write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: No 'option fdsroot' defined in '$ini' file for '$role'."
    	exit 1
	}
    
    # Creating folder if not exists
    if (!(Test-Path -path "$FDSRoot"))
    {
        write-host "`n[" (get-date -format HH:mm:ss) "] FDS root location '$FDSRoot' does not exist. Creating..."
        new-item -path $FDSRoot -type "directory" | out-null
    }
	else
	{    
		# Removing pubs files if they exist
	    while (Test-Path -path "$FDSRoot\FDSSubscriptions")
	    {
	        write-host "`n[" (get-date -format HH:mm:ss) "] Removing existing FDS pubs folder '$FDSRoot\FDSSubscriptions'..."
	        remove-item "$FDSRoot\FDSSubscriptions" -recurse -force
	        if (Test-Path -path "$FDSRoot\FDSSubscriptions")
	        {
	            write-host "`nPath '$FDSRoot\FDSSubscriptions' could not be deleted.`n  Trying again in 30 seconds..."
	            Start-Sleep -s 30
	        }
	        write-host "`n[" (get-date -format HH:mm:ss) "] Folder removed."
	    }
	}
    
    # Adding ExpediaSys to local system's path environment variable
	Set-ExpediaSysRegKey
	
	# Running MTTSetup
	Set-RunMTTSetup
	
	# Making sure FDS pubs are built before continuing
	Set-ValidateFDS

    # Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# UTL Role
Function Set-UTLTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
    
	write-host "`n[" (get-date -format HH:mm:ss) "] No '$role' tasks defined."
}

# WBO Role
Function Set-WBOTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
    
	# Running MTTSetup
	Set-RunMTTSetup
	
	# Restarting computer
    write-host "`n[" (get-date -format HH:mm:ss) "] Restarting computer..."
    restart-computer -force
}

# WEB Role
Function Set-WebTasks
{    
    write-host "`n[" (get-date -format HH:mm:ss) "] Performing '$role' tasks..."
    
	# Running MTTSetup
	Set-RunMTTSetup
	
	<#
	# Running sync of daily files
	$dailyfilesynccommand = "\\chelfilrtt01\Build\DailyFileSyncAll.cmd"
	write-host "`n[" (get-date -format HH:mm:ss) "] Syncing daily files..."
	if (Test-Path -path "$dailyfilesynccommand")
	{
		# Need to add wait for process to finish
		& "$dailyfilesynccommand"
	}
	else
	{
		write-host -foregroundcolor Yellow "`n[" (get-date -format HH:mm:ss) "] WARNING: '$dailyfilesynccommand' not found!"
	}
	#>
	
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
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -path argument is missing!"
    Get-ScriptHelp
}

# Returning help if ini argument is missing
if (!$ini)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -ini argument is missing!"
    Get-ScriptHelp
}

# If no role defined, determining computer name
$ComputerName = $null
if (!$role)
{
	# Getting local computer name
	$ComputerName = $env:computername
	If (!$ComputerName)
	{
	    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: No role argument passed and computer name not found."
	    exit 1
	}
	$role = $ComputerName
}

# Verifying setup path
if (!(Test-Path -path "$path"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Path '$path' does not exist."
    exit 1
}
if (!(Test-Path -path "$path\setup.exe"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Could not find '$path\setup.exe'."
    exit 1
}

# Verifying ini path
if (!(Test-Path "$path\$ini"))
{
	if (!(Test-Path "$ini"))
    {
        write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: INI file '$ini' does not exist."
        exit 1
    }
}
else
{
    $ini = "$path\$ini"
}

# Verifying role or computer name exists in ini file
$found = $false
$FileContent = $null
$FileContent = get-content $ini
$line = $null
foreach ($line in $FileContent)
{
	if ($line -eq "[$role]")
    {
        $found = $true
		break
    }
}

if (!$found)
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Could not find '$role' in '$ini'."
    exit 1
}

# Writing parameters
write-host "`nPath: '$path'"
write-host "INI file: '$ini'"
write-host "Role: '$role'`n"

# Running function based on role
if ($role -match "FDS")
{
    Set-FDSTasks
}
if ($role -match "JVA")
{
    Set-JVATasks
}
if ($role -match "TVA")
{
    Set-TVATasks
}
if ($role -match "TVD")
{
    Set-TVDTasks
}
if ($role -match "TVM")
{
    Set-TVMTasks
}
if ($role -match "UTL")
{
    Set-UTLTasks
}
if ($role -match "WBO")
{
    Set-WBOTasks
}
if ($role -match "WEB")
{
    Set-WebTasks
}

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

exit 0

