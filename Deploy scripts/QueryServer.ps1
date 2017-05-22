param($action,$bfstravbin,$newtravbin,$user,$pwd,$logfile)

# $action = [install, uninstall, startservices, stopservices, full]
# $bfstravbin = "D:\travbin"
# $newtravbin = "D:\travbin.new"
$bfsservices = "bfsdiagmgr", "bfscfgsvc", "bfslogmgr", "bfsqamd", "multicacheclientsvc", "bfsquerymgrwssvc"
$qservices = "bfsqavs", "bfsqdrt", "bfsqccd", "bfsqccf", "bfsqcst", "bfsqcvr", "bfsqdir", "bfsqdmd", "bfsqfrs", "bfsqhlr", "bfsqint", "bfsqintcst", "bfsqmct", "bfsqmet", "bfsqmpm", "bfsqoag", "bfsqpfc", "bfsqspr", "bfsqsvc", "bfsqtax", "bfsqtpm", "bfsqmpx", "bfsqtkf", "bfsqexptax", "bfsqsbrcvr", "bfsqroe", "bfsquerymgr", "bfsqsac", "bfsqamadeus", "bfsqtpt"
$services = $bfsservices + $qservices
$dotnetservices = "bfsqsbr"
$authservices = $services + $dotnetservices 
$systemservices = "remoteregistry","winmgmt","snmp","cqmghost","splunkd","splunkforwarder"
$systemprocesses = "MonitoringHost","wmiprvse","procexp","procexp64","CcmExec"

$installutilpath = "C:\WINDOWS\microsoft.net\Framework64\v4.0.30319\installutil.exe"
$testexepath = "D:\deploymentVerify\DeploymentVerifications.exe"

Function AddToLogFile
{
	param($file, $content)
	Add-Content $file ("[{0}] {1}" -f (Get-Date).ToString(), $content)
}

Function StartupService
{
	param($computername, $servicename)
	try
	{
		if (get-service -ComputerName $computername -Name $servicename -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Starting $servicename"
			if ((get-service -ComputerName $computername -Name $service).status -ne "Running")
			{
				(get-service -ComputerName $computername -Name $servicename).Start()
			}
		}
		else
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Service '$service' is not installed."
			AddToLogFile $logfile "Service '$service' is not installed."
		}
	}
	catch
	{
		write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Fail to start $servicename."
		AddToLogFile $logfile "Fail to starting $servicename"
	}
}

Function ShutdownService
{
	param($computername, $servicename)
	try
	{
		if (get-service -ComputerName $computername -Name $servicename -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Shutting down $servicename"
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				(get-service -ComputerName $computername -Name $servicename).Stop()
			}
		}
	}
	catch
	{
		AddToLogFile $logfile "Exception to stop $servicename"
	}    
}

Function StartUpServer
{
	param($computername)
	Write-Host (get-content env:computername) "Starting up services on $computername..."
	Foreach ($service in $services)
	{
		if ((get-service -ComputerName $computername -Name $service).status -ne "Running")
		{
			StartupService $computername $service
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if ((get-service -ComputerName $computername -Name $service).status -ne "Running")
		{
			StartupService $computername $service
		}
	}
	Write-Host (get-content env:computername) "Waiting for services to start..."
	start-sleep -s 60
	Foreach ($service in $services)
	{
		if ((get-service -ComputerName $computername -Name $service).status -ne "Running")
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Service '$service' failed to start."
			exit 1
		}
	}
	Foreach ($service in $dotnetservices)
	{
		while ((get-service -ComputerName $computername -Name $service).status -eq "StartPending")
		{
			start-sleep -s 5
		}
		if ((get-service -ComputerName $computername -Name $service).status -ne "Running")
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Service '$service' failed to start."
			exit 1
		}
	}
}

Function ShutdownServer
{
	param($computername)
	Write-Host (get-content env:computername) "Shutting down services on $computername..."
	Foreach ($service in $services)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			ShutdownService $computername $service
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			ShutdownService $computername $service
		}
	}
	start-sleep -s 10
	Foreach ($service in $services)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				ShutdownService $computername $service
				if (get-process $service -erroraction "silentlycontinue")
				{
					wait-process -name $service -timeout 120 -erroraction "silentlycontinue"
				}
			}
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				ShutdownService $computername $service
				if (get-process $service -erroraction "silentlycontinue")
				{
					wait-process -name $service -timeout 120 -erroraction "silentlycontinue"
				}
			}
		}
	}
	if (get-service "bfscfgsvc" -erroraction "silentlycontinue")
	{
		if ((get-service -ComputerName $computername -Name "bfscfgsvc").status -ne "stopped")
		{
			ShutdownService $computername "bfscfgsvc"
			if (get-process "bfscfgsvc" -erroraction "silentlycontinue")
			{
				wait-process -name "bfscfgsvc" -timeout 120 -erroraction "silentlycontinue"
			}
		}
	}
	if (get-service "bfsdiagmgr" -erroraction "silentlycontinue")
	{
		if ((get-service -ComputerName $computername -Name "bfsdiagmgr").status -ne "stopped")
		{
			ShutdownService $computername "bfsdiagmgr"
			if (get-process "bfsdiagmgr" -erroraction "silentlycontinue")
			{
				wait-process -name "bfsdiagmgr" -timeout 120 -erroraction "silentlycontinue"
			}
		}
	}
	Foreach ($service in $services)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Fail to stop $service."
				AddToLogFile $logfile "Fail to stop $service"
				exit 1
			}
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Fail to stop $service."
				AddToLogFile $logfile "Fail to stop $service"
				exit 1
			}
		}
	}
}

Function ShutdownDLServices
{
	param($computername)
	Write-Host (get-content env:computername) "Shutting down services on $computername..."
	Foreach ($service in $qservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			ShutdownService $computername $service
		}
	}
	start-sleep -s 10
	Foreach ($service in $qservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				ShutdownService $computername $service
				if (get-process $service -erroraction "silentlycontinue")
				{
					wait-process -name $service -timeout 120 -erroraction "silentlycontinue"
				}
			}
		}
	}
	Foreach ($service in $qservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			if ((get-service -ComputerName $computername -Name $service).status -ne "stopped")
			{
				write-host -foregroundcolor Red (get-content env:computername) "`ERROR: Fail to stop $service."
				AddToLogFile $logfile "Fail to stop $service"
				exit 1
			}
		}
	}
}

Function RegisterDlls
{
	param($src)
	Write-Host (get-content env:computername) "Registering dlls..."
	AddToLogFile $logfile "Registering $src"
	$dlllist = ls $src\bfs\*.dll -exclude "cdsclnt.dll"
	Foreach ($dll in $dlllist)
	{
		AddToLogFile $logfile "Registering $dll..."
		regsvr32 /s $dll
		start-sleep -m 500
	}
	$dlllist = ls $src\bfsps\*.dll -exclude "cdsclnt.dll"
	Foreach ($dll in $dlllist)
	{
		AddToLogFile $logfile "Registering $dll..."
		regsvr32 /s $dll
		start-sleep -m 500
	}
}

Function InstallServices
{
	param($src)
	Write-Host (get-content env:computername) "Installing services..."
	AddToLogFile $logfile "Installing $src"
	Foreach ($service in $services)
	{
		& "$src\bfs\$service.exe" '-install' 2>$1 | Add-Content $logfile
		if (get-process $service -erroraction "silentlycontinue")
		{
			wait-process -name $service -timeout 120 -erroraction "silentlycontinue"
		}
	}
	Foreach ($service in $dotnetservices)
	{
		& $installutilpath "$src\bfs\$service.exe" 2>&1 | Add-Content $logfile
		if (get-process "installutil" -erroraction "silentlycontinue")
		{
			wait-process -name "installutil" -timeout 120 -erroraction "silentlycontinue"
		}
	}
	Foreach ($service in $services)
	{
		if ((-not (get-service $service -erroraction "silentlycontinue")))
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$service' fails to install."
			exit 1
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if ((-not (get-service $service -erroraction "silentlycontinue")))
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$service' fails to install."
			exit 1
		}
	}
}

Function ChangeLogin
{
	param($username, $password)
	Write-Host (get-content env:computername) "Changing logins on services..."
	Foreach ($service in $authservices)
	{
		if (get-service $service -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Changelogin for $service"
			$name = "name='" + $service + "'"
			(gwmi win32_service -filter $name).change($null,$null,$null,$null,$null,$null,$username,$password,$null,$null,$null) | out-null
		}
		else
		{
			AddToLogFile $logfile "Failed to change login for $service"
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$service' does not exist."
			exit 1
		}
	}
}

Function UnRegisterDlls
{
	param($src)
	Write-Host (get-content env:computername) "Unregistering dlls..."
	AddToLogFile $logfile "Unregistering $src"
	$dlllist = ls $src\bfs\*.dll -exclude "cdsclnt.dll"
	Foreach ($dll in $dlllist)
	{
		AddToLogFile $logfile "Unregistering $dll..."
		regsvr32 /u /s $dll
		start-sleep -m 500
	}
	$dlllist = ls $src\bfsps\*.dll -exclude "cdsclnt.dll"
	Foreach ($dll in $dlllist)
	{
		AddToLogFile $logfile "Unregistering $dll..."
		regsvr32 /u /s $dll
		start-sleep -m 500
	}
}

Function UnInstallServices
{
	param($src)
	Write-Host (get-content env:computername) "Uninstalling services..."
	Foreach ($service in $services)
	{
		AddToLogFile $logfile "Uninstalling $service"
		if (get-service $service -erroraction "silentlycontinue")
		{
			C:\WINDOWS\system32\sc.exe delete $service | Add-Content $logfile
			if (get-process "sc" -erroraction "silentlycontinue")
			{
				wait-process -name "sc" -timeout 120 -erroraction "silentlycontinue"
			}
		}
	}
	Foreach ($service in $dotnetservices)
	{
		AddToLogFile $logfile "Uninstalling $src"
		if (get-service $service -erroraction "silentlycontinue")
		{
			& $installutilpath /u "$src\bfs\$service.exe" 2>&1 | Add-Content $logfile
			if (get-process "installutil" -erroraction "silentlycontinue")
			{
				wait-process -name "installutil" -timeout 120 -erroraction "silentlycontinue"
			}
		}
	}
	Foreach ($service in $services)
	{
		if ((get-service $service -erroraction "silentlycontinue"))
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$service' fails to uninstall."
			AddToLogFile $logfile "Fails to uninstalling $service"
			exit 1
		}
	}
	Foreach ($service in $dotnetservices)
	{
		if ((get-service $service -erroraction "silentlycontinue"))
		{
			write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$service' fails to uninstall."
			AddToLogFile $logfile "Fails to uninstalling $service"
			exit 1
		}
	}
}

Function RenameDirectory
{
	param($travbin,$computername)
	if ((-not (Test-Path "$newtravbin")))
	{
		write-host -foregroundcolor Red (get-content env:computername) "`ERROR: '$src' does not exist."
		exit 1
	}
	
	Write-Host (get-content env:computername) "Shutting down system services and processes..."

	Foreach ($systemservice in $systemservices)
	{
		if (get-service $systemservice -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Shutting down $systemservice..."
			try
			{
				(get-service $systemservice).Stop()
			}
			catch
			{
			}
		}
	}
	Foreach ($systemprocess in $systemprocesses)
	{
		if (get-process $systemprocess -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Shutting down $systemprocess..."
			stop-process -name $systemprocess -force -erroraction "silentlycontinue"
			wait-process -name $systemprocess -timeout 120 -erroraction "silentlycontinue"
		}
	}
	
	if ((Test-Path "$travbin.old"))
	{
		Write-Host (get-content env:computername) "Removing existing $travbin.old folder..."
		try 
		{
			remove-item "$travbin.old" -recurse -force -erroraction "silentlycontinue"
		}
		catch
		{
			Write-Host -foregroundcolor Red (get-content env:computername) "`ERROR: $error[0].Exception.ToString()"
			Write-Host "`nRemoval of $travbin.old failed."
			exit 1
		}
	}
	
	if ((Test-Path "$travbin"))
	{
		Write-Host (get-content env:computername) "Renaming existing $travbin folder to $travbin.old..."
		try 
		{
			Rename-Item -path "$travbin" -newname "$travbin.old"
			if ((Test-Path "$travbin"))
			{
				throw "Faile to remove"
			}
		}
		catch 
		{
			Write-Host -foregroundcolor Red (get-content env:computername) "`ERROR: $error[0].Exception.ToString()"
			Write-Host "`nRenaming of $travbin to $travbin.old failed."
			exit 1
		}
	}
	
	Write-Host (get-content env:computername) "Copying $newtravbin to $travbin..."
	try
	{
		Copy-Item "$newtravbin" -destination "$travbin" -recurse
	}
	catch
	{
		Write-Host -foregroundcolor Red (get-content env:computername) "`nRenaming $newtravbin to $travbin failed."
		exit 1
	}
	
	Write-Host (get-content env:computername) "Starting up system services..."
	Foreach ($systemservice in $systemservices)
	{
		if (get-service $systemservice -erroraction "silentlycontinue")
		{
			AddToLogFile $logfile "Starting $servicename"
			try
			{
				(get-service $systemservice).Start()
			}
			catch
			{
			}
		}
	}
}

Function RunTest
{
	try
	{
		Write-Host (get-content env:computername) "Running Verification Tests..."
		AddToLogFile $logfile "Running Verification Tests..."
		& $testexepath 2>$1 | Add-Content $logfile
		if ($LastExitCode -ne 0)
		{
			Write-Host -foregroundcolor Red (get-content env:computername) "Deployment Verification Test failed."
			exit 1
		}
	}
	catch
	{
		Write-Host -foregroundcolor Red (get-content env:computername) "Fail to execute test."
	}
}

if ($action -eq 'install')
{
	AddToLogFile $logfile "Starting installation"
	RenameDirectory $bfstravbin localhost
	RegisterDlls $bfstravbin
	InstallServices $bfstravbin
	ChangeLogin $user $pwd
}
elseif ($action -eq 'uninstall')
{
	AddToLogFile $logfile "Starting uninstallation"
	ShutdownServer localhost
	UnInstallServices $bfstravbin
	UnRegisterDlls $bfstravbin
}
elseif ($action -eq 'startservices')
{
	StartUpServer localhost
}
elseif ($action -eq 'stopservices')
{
	ShutdownServer localhost
}
elseif ($action -eq 'full')
{
	$starttime = (Get-Date).ToString()
	Write-Host (get-content env:computername) "Starting full installation."
	AddToLogFile $logfile "Starting full installation"
	ShutdownServer localhost
	UnInstallServices $bfstravbin
	UnRegisterDlls $bfstravbin
	RenameDirectory $bfstravbin localhost
	RegisterDlls $bfstravbin
	InstallServices $bfstravbin
	ChangeLogin $user $pwd
	StartUpServer localhost
	RunTest
	$endtime = (Get-Date).ToString()
	Write-Host (get-content env:computername) "Full installation completed."
	AddToLogFile $logfile "Full installation completed. Start at $starttime."
}
elseif ($action -eq 'stopdlmgrs')
{
	Write-Host (get-content env:computername) "Stopping download managers."
	AddToLogFile $logfile "Shutting down download managers."
	ShutdownDLServices localhost
}
elseif ($action -eq 'runtest')
{
	RunTest
}
else
{
	Write-Host Invalid commands.
	exit 1
}