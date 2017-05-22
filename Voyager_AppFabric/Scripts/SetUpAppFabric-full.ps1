<# 2011-09-13 - Initial Script 
# 2011-09-23 - Bug Fixes found with Reggie
# 2011-09-28 - Add-Host command added in lead host.  
                        Being the lead host does not Add-Host by default #>
cls 

#Set Variables
		If (($args.count) -lt 1)
		{
			Write-Host ""
			Write-Host -ForegroundColor Red "ERROR: No arguments have been passed to the script."
			Write-Host -ForegroundColor Yellow "USAGE:"
			Write-Host -ForegroundColor Yellow "SetUpConfigAppFabric.ps1 <ENV>"
			Write-Host -ForegroundColor Yellow "    Switches currently supported:"
			Write-Host -ForegroundColor Yellow "      PROD - Production Environment"
			Write-Host -ForegroundColor Yellow "      LAB  - KARMALAB Environment"
			Exit 1001
			}
		ElseIf (($args.count) -gt 1)
		{
			Write-Host ""
			Write-Host -ForegroundColor Red "ERROR: Too many arguments passed"
			Write-Host -ForegroundColor Yellow "USAGE:"
			Write-Host -ForegroundColor Yellow "SetUpConfigAppFabric.ps1 <ENV>"
			Write-Host -ForegroundColor Yellow "    Switches currently supported:"
			Write-Host -ForegroundColor Yellow "      PROD - Production Environment"
			Write-Host -ForegroundColor Yellow "      LAB  - KARMALAB Environment"
			Exit 1001
			}
		



#Environment Names
	$global:pathChoice = $args[0]
	$global:localComputerName = $env:COMPUTERNAME
	$global:ClusterEnv = $env:_AppFabEnv
	

#Aliases that can be set ahead of time
	

#Path and references
	IF($Global:pathChoice.ToUpper() -match "PROD"){
			$global:installFilePathRoot = "\\chc-filidx\cctss\voyager\AppFabric"
			}
	ELSEIF($Global:pathChoice.ToUpper() -match "LAB"){
			$global:installFilePathRoot = "\\chelappsbx001\public\AppFabric"
			}
	ELSE{
		Write-Host -ForegroundColor Red "ERROR: You must enter PROD or LAB!"
		Write-Host -ForegroundColor Red "No other variables are currently supported."
		Exit 1001
		}
#	$global:installFilePathRoot = "\\chelappsbx001\public\AppFabric"
	$global:scriptPath = ($global:installFilePathRoot + "\Scripts")
	$global:installSetupFilePath = ($global:installFilePathRoot + "\SetupFiles")
	$global:installDotNetFrameworkPath = ($global:installSetupFilePath + "\dotNet4.0Redist")
	$global:installAppFabricFilePath=($global:installSetupFilePath + "\WindowsServerAppFabric")
	$global:exeDotNetFramework = "\dotNetFx40_Full_x86_x64.exe"
	$global:exeAppFabric = "\WindowsServerAppFabricSetup_x64_6.1.exe"
	$global:localFileStore ="c:\cct_ops"
	$global:localLogFiles = ($global:localFileStore + "\Logs")
	$global:localAppFabStore = ($global:localFileStore + "\AppFabric")
	$global:localScriptPath = ($global:localAppFabStore + "\Scripts")
	$global:localSetupInstallPath = ($global:localAppFabStore + "\SetupFiles")
	$global:localDotNetInstallPath = ($global:localSetupInstallPath + "\dotNet4.0Redist")
	$global:localAppFabInstallPath = ($global:localSetupInstallPath + "\WindowsServerAppFabric")
	
	
	
#Default boolean values
	$global:boolSystemReadyToInstallAppFabric = $false
	$global:boolAppFabricInstalled = $false
	$global:boolWUIsRunning = $false
	$global:boolIsPriSrv = $false
		
#Pre-Defined Arrays
	

# Functions

Function Test-Administrator{
$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ 
	Write-host -ForegroundColor Red "ERROR: Script not run as system administator!"
	Write-Host -ForegroundColor Yellow "Please re-run this script with administrative privileges in an elevated session of PowerShell."
	Exit}

Function CheckForFramework4{
		#Confirm .Net Framework 4.0 is installed
		Write-Host -ForegroundColor Cyan "`nChecking to see if .Net Framework 4.0 is already installed."
		$arrFrameworks = @()
		$arrFrameworks = (ls $Env:windir\Microsoft.NET\Framework | ? { $_.PSIsContainer -and $_.Name -match '^v\d.[\d\.]+' } | % { $_.Name.TrimStart('v')} | sort )
		$latestFramework = $arrFrameworks[-1]
		ForEach ($fr in $arrFrameworks ) {Write-Host -ForegroundColor Cyan $fr}
		#Start-Sleep 2
		if ($latestFramework -match '^4.[\d\.]+'){
			Write-Host -ForegroundColor Green "`nLatest version of .Net Framework is already 4.0"
			Write-Host -ForegroundColor Green $latestFramework
			return  $true
			}
		else
		{
			Write-Host -ForegroundColor Yellow ".Net 4.0 Framework requires installation"
			return $false
			}
		
	}

Function Get-InstalledPrograms($computer = '.') {
		$programs_installed = @{};
		$win32_product = @(get-wmiobject -class 'Win32_Product' -computer $computer);
		foreach ($product in $win32_product) {
			$name = $product.Name;
			$version = $product.Version;
			if ($name -ne $null) {
				$programs_installed.$name = $version;
			}
		}
		return $programs_installed;
	}

Function IsAppFabricAlreadyInstalled () {
	try {Get-Hotfix -ID KB970622 -ErrorAction SilentlyContinue}
	catch {"This command cannot find hot-fix on the machine"}
	if ($? -eq $true){
		Write-Host -ForegroundColor Yellow "AppFabric Client is already installed on this system."
		return $true
		}
	else{
		Write-Host -ForegroundColor Cyan "AppFabric is not installed on this system."
		return $false
		}
	}

Function IsWindowsUpdateRunning ($computer="."){
	Write-Host -ForegroundColor Cyan "`nChecking to see if Windows Update Service is running."
	$IsWuRunning = Get-Service -Name wuauserv
	If ($IsWuRunning.Status -eq "Running")
	{
		Write-Host -ForegroundColor Green "Windows Update Service is already running"
		return $global:boolWUIsRunning = $true
		}
	Else
	{
		Write-Host -ForegroundColor Yellow "Windows Update Service is now running."
		Write-Host -ForegroundColor Yellow "Starting Windows Update Service for AppFabric installation."
		Start-Service -Name wuauserv
		if ($? -eq $true)
		{
			Write-Host -ForegroundColor Green "Windows Update Service is now running."
			return $true
			}
		else
		{
			Write-Host -ForegroundColor Red "ERROR: Windows Update Service failed to start."
			Write-Host -ForegroundColor Yellow "Trying again...."
			
			while($i=1, $i -lt 4)
			{
				Write-Host -ForegroundColor ("Try number: " + $i)
				
				net start wuauserv
				if ($? = $true)
				{
					Write-Host -ForegroundColor Green "SUCCESS: Windows Update Service successfully started"
					return $true
					}
				else
				{
					Write-Host -ForegroundColor Red "ERROR: Windows Update Service failed to start."
					if ($i -eq 3)
					{
						Write-Host -ForegroundColor Red "ERROR: Failed 3 attempts."
						Write-Host -ForegroundColor Yellow "Please manually start Windows Update Service and start script again to complete AppFabric setup."
						Write-Host -ForegroundColor Red "Script Ending"
						return $false
						}
					else
					{
						$i++
						}
				}
			}
		}
	}
}
				
Function Get-PendingReboot ($computer = '.') {
		$hkey		= 'LocalMachine';
		$path_server	= 'SOFTWARE\Microsoft\ServerManager';
		$path_control	= 'SYSTEM\CurrentControlSet\Control';
		$path_session	= join-path $path_control 'Session Manager';
		$path_name	= join-path $path_control 'ComputerName';
		$path_name_old	= join-path $path_name 'ActiveComputerName';
		$path_name_new	= join-path $path_name 'ComputerName';

		$pending_rename	= 'PendingFileRenameOperations';
		$pending_rename_2	= 'PendingFileRenameOperations2';
		$attempts	= 'CurrentRebootAttempts';
		$computer_name	= 'ComputerName';

		$num_attempts	= 0;
		$name_old	= $null;
		$name_new	= $null;

		$reg= [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hkey, $computer);

		$key_session	= $reg.OpenSubKey($path_session);
		if ($key_session -ne $null) {
			$session_values	= @($key_session.GetValueNames());
			$key_session.Close() | out-null;
		}

		$key_server	= $reg.OpenSubKey($path_server);
		if ($key_server -ne $null) {
			$num_attempts = $key_server.GetValue($attempts);
			$key_server.Close() | out-null;
		}

		$key_name_old	= $reg.OpenSubKey($path_name_old);
		if ($key_name_old -ne $null) {
			$name_old = $key_name_old.GetValue($computer_name);
			$key_name_old.Close() | out-null;

			$key_name_new	= $reg.OpenSubKey($path_name_new);
			if ($key_name_new -ne $null) {
				$name_new = $key_name_new.GetValue($computer_name);
				$key_name_new.Close() | out-null;
			}
		}

		$reg.Close() | out-null;

		if ((($session_values -contains $pending_rename) `
		-or ($session_values -contains $pending_rename_2)) `
		-or (($num_attempts -gt 0) -or ($name_old -ne $name_new))) {
			return $true;
		}
		else {
			return $false;
		}
	}
	
Function PS-Robocopy ($src,$dst){
	[string]$RCopySRC = $src
	[string]$RCopyDST = $dst
	
	Set-Alias RCopy "C:\Windows\System32\Robocopy.exe"
	Write-Host -ForegroundColor Cyan "Copying files via Robocopy..."
	Write-Host -ForegroundColor White ("     Source: " + $RCopySRC)
	Write-Host -ForegroundColor White ("     Destination: " + $RCopyDST)
	
	
	RCopy $RCopySRC $RCopyDST /E /COPY:DAT /R:3 /W:2 /NP | Out-Null
	
			If($LASTEXITCODE -eq 0)	{
				Write-Host "No files were copied. No failure was encountered. No files were mismatched. The files already exist in the destination directory; therefore, the copy operation was skipped."
				$global:arrFailedSrv += ($srv + " - robocopy new files - Exit Code: " + $LASTEXITCODE + ". No files were copied.")
				return $false
				}
			ElseIf($LASTEXITCODE -eq 1) {
				Write-Host "All files were copied successfully."
				return $true
				}
			ElseIf($LASTEXITCODE -eq 3) {
				Write-Host "Some files were copied. Additional files were present. No failure was encountered."
				return $true
				}
			ElseIf($LASTEXITCODE -eq 5) {
				Write-Host "Some files were copied. Some files were mismatched. No failure was encountered."
				return $true
				}
			ElseIf($LASTEXITCODE -eq 6) {
				Write-Host "Additional files and mismatched files exist. No files were copied and no failures were encountered"
				return $true
				}
			Else
			{
				Write-Host -ForegroundColor Red "ERROR: Unexpected exit code from robocopy"
				Write-Host -ForegroundColor Red ("Exit code was " + $LASTEXITCODE)
				return $false
				}
}

Function Set-AppFabFirewall{
	Write-Host -Cyan "Configuring Firewall for AppFabric Cache Cluster..."
	netsh advfirewall firewall set rule group="Windows Server AppFabric: AppFabric Caching Service" new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (RPC)" profile=domain new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (RPC-EPMAP)" profile=domain new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (NP-In)" profile=domain new enable=Yes
}

Function SetAllowedCacheClients ([array]$Clients,[string]$Pv,[string]$ConStr){
	Write-Host -ForegroundColor Cyan "`nGranting Clients access to Cache Cluster..."
	Write-Host -ForegroundColor White ("Running - Use-CacheCluster -Provider " + $Pv + " -ConnectionString " + $ConStr)
	Use-CacheCluster -Provider $Pv -ConnectionString $ConStr 
	
	ForEach($grant in $Clients)
	{
		Write-Host -ForegroundColor Cyan ("Running - Grant-CacheAllowedClientAccount -Account " + $grant + " -Force")
		Grant-CacheAllowedClientAccount -Account $grant -Force
		}
	}
	
Function NewDataCache ([array]$caches,[string]$Pv,[string]$ConStr){
	Write-Host -ForegroundColor Cyan "`nAdding Data Caches to the Cache Cluster..."
	Write-Host -ForegroundColor White ("Running - Use-CacheCluster -Provider " + $Pv + " -ConnectionString " + $ConStr)
	Use-CacheCluster  -Provider $Pv -ConnectionString $ConStr
	
	ForEach ($cache in $caches){
		Write-Host -ForegroundColor White ("Running - New-Cache -CacheName " + $cache + "-NotificationsEnabled True -Secondaries 1 -TimeToLive 120 -Force")
		New-Cache -CacheName $cache -NotificationsEnabled True -Secondaries 1 -TimeToLive 120 -Force
		}
	}

<#--- Setup Tasks for AppFabric ---#>
	
	#Pre-check - Is script being run as an administrator?
	Test-Administrator
	
	#Check for c:\cct_ops folder
	If ((Test-Path $global:localFileStore) -ne $true){
		Write-Host -ForegroundColor Yellow ("INFO: The path " + $global:localFileStore + " does not exist. Creating path.")
		New-Item $global:localFileStore -ItemType Directory
		}
		Write-Host -ForegroundColor Yellow ("`nConfirming the rest of the directory structure is in place...")
		If ((Test-Path  $global:localLogFiles) -ne $true) {New-Item $global:localLogFiles -ItemType Directory}
		If ((Test-Path $global:localAppFabStore) -ne $true){New-Item $global:localAppFabStore -ItemType Directory}
		If ((Test-Path $global:localScriptPath) -ne $true){New-Item $global:localScriptPath -ItemType Directory}
		If ((Test-Path $global:localSetupInstallPath) -ne $true){New-Item $global:localSetupInstallPath -ItemType Directory}
		If ((Test-Path $global:localDotNetInstallPath) -ne $true){New-Item $global:localDotNetInstallPath -ItemType Directory}
		If ((Test-Path $global:localAppFabInstallPath) -ne $true){New-Item $global:localAppFabInstallPath -ItemType Directory}
	
	#Copy Scripts to Local Machine
	PS-Robocopy $global:scriptPath $global:localScriptPath #| Out-Null
	
	
    #Parse the Config File.
	$configFile = ($localScriptPath + "\AppFabEnv.csv")
	Write-Host -ForegroundColor Cyan ("`nReading file for configuration settings:")
	Write-Host -ForegroundColor White ("Source File: " + $configFile)
	If ((Test-Path $configFile) -eq $true){
		$setupVal = (Import-Csv  $configFile -Delimiter ';' | Where-Object {$_.AppFabEnv -eq $ClusterEnv})
		foreach ($name.AppFabComputerName in $setupVal){
			If ($env:_AppFabEnv -ne $ClusterEnv){
				Write-Host -ForegroundColor Red ("`nERROR: Could not find _AppFabEnv variable to match " + $env:COMPUTERNAME)
				Write-Host -ForegroundColor Yellow ("Please make sure to run the following shell command and run the script again:")
				Write-Host -ForegroundColor Yellow ("SETX _AppFabEnv <EnvironementName> -m")
				Write-Host -ForegroundColor Yellow ("EXAMPLE: SETX _AppFabEnv PROD -m")
				Exit
				}
			If ($name.AppFabComputerName -match $env:COMPUTERNAME){
           	    [string]$strOptions = $name.AppFabricSetupOptions
				[string]$hostType = $name.AppFabHostType
				[string]$strProvider = $name.AppFabProvider
				[string]$strConStr = $name.AppFabConnString
				[string]$hostType = $name.AppFabHostType
				[string]$appFabSvcAcct = $name.AppFabAccount
				[string]$appCachePort = $name.AppCachePort
				[string]$appClusterPort = $name.AppClusterPort
				[string]$appArbPort = $name.AppArbitrationPort
				[string]$appReplPort = $name.AppReplicationPort
				[string]$appFabHostName = $name.AppFabHostName
                [int]$PriServer = $name.AppFabIsPriSrv					
				if ($PriServer -eq 1){
					$appFabSize = $name.AppFabSize
					[array]$arrCacheClients = @(($name.AllowedCacheClients).split(","))
					[array]$arrDataCaches = @(($name.DataCaches).split(","))
					[bool]$boolIsPriSrv = $true
					}
                break
				}
			}
		}
		Else
		{
			Write-Host -ForegroundColor Red ("`nERROR: Unable to find " + $configFile)
			Write-Host -ForegroundColor Yellow "Ending script..."
			Exit
			}	

	#Note to user the values that will be implemented in this setup and cluster configuration.				
		Write-Host ("The following setup and cluster config values will be used for " + $name.AppFabComputerName + ":")
		Write-Host ("   Setup Options:  " + $strOptions)
		Write-Host ("   Provider:  " + $strProvider)
		Write-Host ("   ConnectionString:  " + $strConStr)
		Write-Host ("   ServerHostType: " + $hostType)
        if($boolIsPriSrv -eq $true){$PriSrvOrNot = "True"}else{$PriSrvOrNot = "False"}
		Write-Host ("   IsPrimaryLeadSrv: " + $PriSrvOrNot)
		Write-Host ("   AppFabric Server Host Account: " + $appFabSvcAcct)
		Write-Host ("   AppFabric Cache Ports:")
		Write-Host ("     Cache Port: " + $appCachePort)
		Write-Host ("     Cluster Port: " + $appClusterPort)
		Write-Host ("     Arbitration Port: " + $appArbPort)
		Write-Host ("     Replication Port: " + $appReplPort)
		Write-Host ("`nAppFabric Host Name: " + $env:COMPUTERNAME)
		if ($boolIsPriSrv -eq $true){
	    	Write-Host ("      AllowedCacheClients: " + $arrCacheClients)
		    Write-Host ("      AppFabric Cluster Size: " + $appFabSize)
			Write-Host "`n       AllowedCacheClients:`n"
			foreach ($x in $arrCacheClients){
				Write-Host ("     " + $x)
				}
			Write-Host "`n       DataCaches:`n"
			foreach ($y in $arrDataCaches){
				Write-Host ("     " + $y)}
				}	
	
	$boolFramework = CheckForFramework4
	#Write-Host ("The value of boolFramework is set to " + $boolFramework)
	if ($boolFramework -eq $false){
		#Can we reach the share?
		$copySrc4Redist = ($global:installDotNetFrameworkPath + $global:exeDotNetFramework)
		$copyDst4Redist = ($global:localDotNetInstallPath + $global:exeDotNetFramework)
		If ((Test-Path $copySrc4Redist) -eq $true){
			Write-Host -ForegroundColor Cyan ("`nCopying .Net Framework installer locally to system.")
			Write-Host -ForegroundColor White ("    Source       : " + $copySrc4Redist)
			Write-Host -ForegroundColor White ("    Destination: " + $copyDst4Redist)
			Copy-Item $copySrc4Redist -Destination $copyDst4Redist -ErrorAction Inquire	
			If ((Test-Path $copyDst4Redist) -eq $false){
				Write-Host -ForegroundColor Red ("ERROR: The file " + $copyDst4Redist + "is not present!")
				Exit 
				}
			Write-Host -ForegroundColor Yellow "`nInstalling .Net Framework 4.0:"
			Set-Alias dot4Install ($global:localDotNetInstallPath +  "\dotNetFx40_Full_x86_x64.exe")
			Start-Process dot4Install -Verb runAs -Wait -ArgumentList ("/passive /norestart /log " + $global:localLogFiles) 
			If ($? -eq $true) { Write-Host -ForegroundColor Green "`n.Net Framework Installer has completed." } else { Write-Host -ForegroundColor Yellow ".Net Framework has complete. A restart may be required."}
				Write-Host -ForegroundColor Magenta ("DEBUG: Value of return switch is " + $?)
				Write-Host -ForegroundColor Magenta ("DEBUG: Last exitcode sent from .Net 4.0 Installer is " + $LASTEXITCODE)
				$boolReboot = $true
				}
		Else
		{
			Write-Host -ForegroundColor Red ("`nERROR: Unable to access " + $copySrc4Redist)
			Write-Host -ForegroundColor Yellow ("Please ensure you have share permissions to " + $global:installDotNetFrameworkPath + " , and restart the script.")
			Exit
			}
	}
	
	#Check if there are any other reasons for a reboot before continuing
	
	Write-Host -ForegroundColor Magenta ("`nDEBUG: Value of boolReboot is " + [string]$boolReboot)
	Start-Sleep -Seconds 3
	If (Get-PendingReboot -eq $true -or $boolReboot -eq $true){
		Write-Host -ForegroundColor Yellow "`nWARNING: There are pending reboots required for this system."
		Write-Host -ForegroundColor Yellow "The script will continue when you reboot system."
        Start-Process  SetAppFabricConfigRestart.cmd -WorkingDirectory $localScriptPath -Wait -Verb runAs -ArgumentList $Global:pathChoice.ToUpper()
		Write-Host -ForegroundColor Magenta "`nRebooting in 5 seconds..."
		Start-Sleep -Seconds 5 | Restart-Computer -Force
		}
			
    #Is AppFabric already installed on this system?
	
	If (IsAppFabricAlreadyInstalled -eq $true){
		Write-Host -ForegroundColor Cyan "`nAppFabric is already installed on this system"
		Write-Host -ForegroundColor Green "Ready to configure."
		#Exit 0
		}
	Else{
		If ((Test-Path $global:installAppFabricFilePath) -eq $true){
		   $srcAppFabInstaller = ($global:installAppFabricFilePath + $global:exeAppFabric)
		   $dstAppFabInstaller = ($global:localAppFabInstallPath + $global:exeAppFabric)
			Write-Host -ForegroundColor Cyan ("`nCopying AppFabric Installer.")
			Write-Host -ForegroundColor White ("    Source      : "  + $srcAppFabInstaller)
			Write-Host -ForegroundColor White ("    Destination: " + $dstAppFabInstaller)
			Copy-Item $srcAppFabInstaller -Destination $dstAppFabInstaller
			}
		#Set Executeable and logfile paths for AppFabric installer.
		$exeAppFabric = ($dstAppFabInstaller)
		$exeAppFabricInstallLog =  ($global:localLogFiles+ "\" + $global:localComputerName + "-AppFabricInstall.log" )
		#Make sure Windows Update is running, per the system requirements of the 
		$boolIsWURunning = IsWindowsUpdateRunning
		If ($boolIsWURunning -eq $true){
			If ((Test-Path $exeAppFabric) -eq $true){
				Set-Alias AppFabInstall $exeAppFabric
			    Write-Host -ForegroundColor Cyan "`nInstalling AppFabric..."
				Write-Host -ForegroundColor White ("Logging to " + $exeAppFabricInstallLog)
				Start-Process AppFabInstall -Verb runAs -Wait -ArgumentList  ("/i " + $strOptions +  " /logfile:" + $exeAppFabricInstallLog)
				Write-Host -ForegroundColor Magenta ("`nDEBUG: AppFabric installer shows the current exit code: " + $LASTEXITCODE)
				If (IsWindowsUpdateRunning -eq $true){
					Write-Host -Foregroundcolor Green "`nSUCCESS: AppFabric Setup complete."
					Write-Host -ForegroundColor Yellow "Stopping Windows Upate Service..."
					net stop wuauserv
					}
				}
				Else
				{
					Write-Host -ForegroundColor Red ("`nERROR: Could not find " + $exeAppFabric)
					}
			}
		Else{
			Write-Host -ForegroundColor Red "`nERROR: Windows Update Server is required for install of AppFabric."
			Write-Host -ForegroundColor Yellow "Please manally start the Windows Update Service and re-run script"
			Exit 1
				}
	}
	
	#Set AppFabric Filrewall Settings
	Set-AppFabFirewall
	
    #Check again for pending reboots... 
	If (Get-PendingReboot -eq $true){
		Write-Host -ForegroundColor Yellow "`nWARNING: There are pending reboots required for this system."
		Write-Host -ForegroundColor Yellow "The script will continue when you reboot system."
        Start-Process  SetAppFabicConfigRestart.cmd -WorkingDirectory $localScriptPath -Wait -Verb runAs -ArgumentList $Global:pathChoice.ToUpper()
		Write-Host -ForegroundColor Magenta "Restarting in 5 seconds..."
		Start-Sleep -Seconds 5 | Restart-Computer -Force
		}
		
    #Configure AppFabric CacheCluster
			
	If ($hostType -eq "Lead"){Import-Module DistributedCacheAdministration}
	Import-Module DistributedCacheConfiguration	
		
#		Set-CacheLogging -LogLevel WARNING -File $localLogFiles\AppFabWarnings.log
#		Set-CacheLogging -LogLevel ERROR -File $localLogFiles\AppFabErrors.log
		
	$NewCacheCluster = ($boolIsPriSrv)
	If ($NewCacheCluster -eq $true){
		Write-Host -ForegroundColor Cyan "`nCreating New Cache Cluster"
		#Creating New Cache Cluster
		Write-Host -ForegroundColor White ("Running - New-CacheCluster -Provider " + $strProvider + " -ConnectionString " + $strConStr + " -Size " + $appFabSize)
		New-CacheCluster -Provider $strProvider -ConnectionString $strConStr -Size $appFabSize
		#Adding Cache Client Service to new Cache Cluster
		Write-Host -ForegroundColor Cyan ("`nJoining existing Cache Cluster")
		Write-Host -ForegroundColor White ("Running - Add-CacheHost -Provider " + $strProvider +  " -ConnectionString " + $strConStr + "  -Account " + $appFabSvcAcct)
		Add-CacheHost -Provider $strProvider -ConnectionString $strConStr  -Account $appFabSvcAcct
	    #Registering Cache Client Service to the Cache Host
		Write-Host -ForegroundColor Cyan "`nRegistering system to Cache Cluster"
		Write-Host -ForegroundColor White ("Running - Register-CacheHost -Provider " + $strProvider + " -ConnectionString " + $strConStr + " -Account" + $appFabSvcAcct+ " -CachePort " + $appCachePort + " -ClusterPort " + $appClusterPort + " -ArbitrationPort" + $appArbPort + " -ReplicationPort " + $appReplPort+ " -HostName " + $env:COMPUTERNAME)
		Register-CacheHost -Provider $strProvider -ConnectionString $strConStr  -Account $appFabSvcAcct -CachePort $appCachePort -ClusterPort $appClusterPort  -ArbitrationPort $appArbPort -ReplicationPort $appReplPort -HostName $env:COMPUTERNAME
		#Setting Cache Cluster Security Levels
		SetAllowedCacheClients $arrCacheClients $strProvider $strConStr
		Set-CacheClusterSecurity -SecurityMode None -ProtectionLevel None
		NewDataCache $arrDataCaches $strProvider $strConStr
		}
	Else
	{
		#Adding Cache Client Service to new Cache Cluster
		Write-Host -ForegroundColor Cyan ("`nJoining existing Cache Cluster")
		Write-Host -ForegroundColor White ("Running - Add-CacheHost -Provider " + $strProvider +  " -ConnectionString " + $strConStr + "  -Account " + $appFabSvcAcct)
		Add-CacheHost -Provider $strProvider -ConnectionString $strConStr  -Account $appFabSvcAcct
		#Registering Cache Client Service to the Cache Host
		Write-Host -ForegroundColor White ("Running - Register-CacheHost -Provider " + $strProvider + " -ConnectionString " + $strConStr + " -Account " + $appFabSvcAcct + " -CachePort " + $appCachePort + " -ClusterPort " + $appClusterPort + " -ArbitrationPort " + $appArbPort + " -ReplicationPort " + $appReplPort + " -HostName " + $env:COMPUTERNAME)
		Register-CacheHost -Provider $strProvider -ConnectionString $strConStr  -Account $appFabSvcAcct -CachePort $appCachePort -ClusterPort $appClusterPort  -ArbitrationPort $appArbPort -ReplicationPort $appReplPort -HostName  $env:COMPUTERNAME
		}
			
	<#  ------------------------
		To add later:
		
		Parse AppFabric install file for errors and warnings.
		Figure out where we can implement a logging solution on the AppFabric CMDLets
		Create a logging mechanism that makes issues easier to track.
		Finish documentation.
		
		------------------------	#>
		
			




		
			
		
		
		
		
			
	