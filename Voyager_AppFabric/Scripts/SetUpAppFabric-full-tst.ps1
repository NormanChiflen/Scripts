#Windows AppFabric set-up script
# 2011-09-13 - Initial Script 
cls 
#Set Variables

#Environment Names
	$global:localComputerName = $env:COMPUTERNAME
	$global:ClusterEnv = $env:_AppFabEnv

#Aliases that can be set ahead of time
	#AppFabric base variables
	$appFabClusterSize = "Medium"
	$appFabClPort


#Path and references
	$global:installFilePathRoot = "\\chelappsbx001\public\AppFabric"
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
	$global:boolPriSrv = $false
		
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
		Write-Host -ForegroundColor Cyan "Checking to see if .Net Framework 4.0 is already installed."
		$arrFrameworks = @()
		$arrFrameworks = (ls $Env:windir\Microsoft.NET\Framework | ? { $_.PSIsContainer -and $_.Name -match '^v\d.[\d\.]+' } | % { $_.Name.TrimStart('v')} | sort )
		$latestFramework = $arrFrameworks[-1]
		ForEach ($fr in $arrFrameworks ) {Write-Host -ForegroundColor Cyan $fr}
		#Start-Sleep 2
		if ($latestFramework -match '^4.[\d\.]+'){
			Write-Host -ForegroundColor Green "Latest version of .Net Framework is already 4.0"
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
		Write-Host -ForegroundColor Cyan "AppFabric is not installed on this system. Installing..."
		return $false
		}
	}

Function IsWindowsUpdateRunning ($computer="."){
	Write-Host -Cyan "Checking to see if Windows Update Service is running."
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
			Write-Host -ForegroundColor Red "Windows Update Service failed to start."
			Write-Host -ForegroundColor Yellow "Trying again...."
			
			while($i=1, $i -lt 4)
			{
				Write-Host -ForegroundColor ("Try number: " + $i)
				
				net start wuauserv
				if ($? = $true)
				{
					Write-Host -ForegroundColor Green "Windows Update Service successfully started"
					return $true
					}
				else
				{
					Write-Host -ForegroundColor Red "Windows Update Service failed to start."
					if ($i -eq 3)
					{
						Write-Host -ForegroundColor Red "Failed 3 attempts."
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
	
	RCopy $RCopySRC $RCopyDST /E /COPY:DAT /R:3 /W:2 /NP
	
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
	netsh advfirewall firewall set rule group="Windows Server AppFabric: AppFabric Caching Service" new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (RPC)" profile=domain new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (RPC-EPMAP)" profile=domain new enable=Yes
	netsh advfirewall firewall set rule name="Remote Service Management (NP-In)" profile=domain new enable=Yes
}

<#--- Setup Tasks for AppFabric ---#>
	
	#Pre-check - Is script being run as an administrator?
	Test-Administrator
	
	#Is execution policy set to restricted?
#	try {set-executionpolicy remotesigned -force}
#	catch { "Unable to set Group Policy"}

#	$a=Get-ExecutionPolicy
#	if ($a -eq "Restricted"){
#		Write-Host  -ForegroundColor Red ("ERROR: ExecutionPolicy is set to " +  $a )
#		Write-Host -ForegroundColor Yellow "Please change remote policy to allow this script to run by executing the following command:"
#		Write-Host -ForegroundColor Cyan "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force"
#		Write-Host -ForegroundColor Yellow "Once ExecutionPolicy has been set, please run this script again."
#		Exit
#		}
	
	#Check for c:\cct_ops folder
	If ((Test-Path $configFile) -eq $true){
			Write-Host -ForegroundColor Cyan  "Getting data for AppFabric Setup..."
			$setupVal = (Import-Csv  $configFile -Delimiter ';' | Where-Object {$_.AppFabEnv -eq $ClusterEnv})
			foreach ($name.AppFabComputerName in $setupVal){
				If ($name.AppFabComputerName -match $env:COMPUTERNAME){
               	    [string]$strOptions = $name.AppFabricSetupOptions
					[string]$hostType = $name.AppFabHostType
					[string]$strProvider = $name.AppFabProvider
					[string]$strConStr = $name.AppFabConnString
					[string]$hostType = $name.AppFabHostType
                    [int]$PriServer = $name.AppFabIsPriSrv
					if ($PriServer -eq 1){
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
						Write-Host -ForegroundColor Red ("ERROR: Unable to find " + $configFile)
						Write-Host -ForegroundColor Yellow "Ending script..."
						Exit
					}	

		#Note to user the values that will be implemented in this setup and cluster configuration.				
			Write-Host ("The following setup and cluster config values will be used for " + $name.AppFabComputerName + ":")
			Write-Host ("Setup Options:  " + $strOptions)
			Write-Host ("Provider:  " + $strProvider)
			Write-Host ("ConnectionString:  " + $strConStr)
			Write-Host ("AppFabAccount: " + $appFabAcct)
			Write-Host ("AllowedCacheClients: " + $arrCacheClients)
			Write-Host ("DataCaches: " + $arrDataCaches)
			Write-Host ("ServerHostType: " + $hostType)
            if($boolIsPriSrv -eq $true){$PriSrvOrNot = "True"}else{$PriSrvOrNot = "False"}
			Write-Host ("IsPrimaryLeadSrv: " + $PriSrvOrNot)
			if ($boolIsPriSrv = $true){
				Write-Host "`n     AllowedCacheClients:`n"
				foreach ($x in $arrCacheClients){ Write-Host ("     " + $x)}
				Write-Host "`n     DataCaches:`n"
				foreach ($y in $arrDataCaches){ Write-Host ("     " + $y)}
				}	
	
	$boolFramework = CheckForFramework4
	#Write-Host ("The value of boolFramework is set to " + $boolFramework)
	 if ($boolFramework -eq $false){
		#Can we reach the share?
		$copySrc4Redist = ($global:installDotNetFrameworkPath + $global:exeDotNetFramework)
		$copyDst4Redist = ($global:localDotNetInstallPath + $global:exeDotNetFramework)
		If ((Test-Path $copySrc4Redist) -eq $true){
			Write-Host -ForegroundColor Cyan ("Copying .Net Framework installer locally to system.")
			Write-Host -ForegroundColor Cyan ("    Source       : " + $copySrc4Redist)
			Write-Host -ForegroundColor Cyan ("    Destination: " + $copyDst4Redist)
			Copy-Item $copySrc4Redist -Destination $copyDst4Redist -ErrorAction Inquire	
			If ((Test-Path $copyDst4Redist) -eq $false){
				Write-Host ("The file " + $copyDst4Redist + "is not present!"
				Exit }
			Set-Alias dot4Install ($global:localDotNetInstallPath +  "\dotNetFx40_Full_x86_x64.exe")
			Start-Process dot4Install -Verb runAs -Wait -ArgumentList ("/passive /norestart /log " + $global:localLogFiles) 
			If ($? -eq $true) { Write-Host -ForegroundColor Green ".Net Framework Installer has completed." } else { Write-Host -ForegroundColor Yellow ".Net Framework has complete. A restart may be required."}
				Write-Host ("Value of return switch is " + $?)
				Write-Host ("Last exitcode sent from .Net 4.0 Installer is " + $LASTEXITCODE)
				}
		Else
		{
			Write-Host -ForegroundColor Red ("ERROR: Unable to access " + $copySrc4Redist)
			Write-Host -ForegroundColor Yellow ("Please ensure you have share permissions to " + $global:installDotNetFrameworkPath + " , and restart the script.")
			Exit
			}
	}
	
	#Check if there are any other reasons for a reboot before continuing
	
	If (Get-PendingReboot -eq $true){
		Write-Host -ForegroundColor Yellow "WARNING: There are pending reboots required for this system."
		Write-Host -ForegroundColor Yellow "The script will continue when you reboot system."
		New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name RunOnce -PropertyType String -Value ("powershell -file " + $global:localScriptPath + "\SetUpAppFabric.ps1")
		Restart-Computer -Force
		}
			
    #Is AppFabric already installed on this system?
	
	If (IsAppFabricAlreadyInstalled -eq $true){
		Write-Host -ForegroundColor Cyan "AppFabric is already installed on this system"
		Write-Host -ForegroundColor Green "Ready to configure."
		#Exit 0
		}
	Else{
		If ((Test-Path $global:installAppFabricFilePath) -eq $true){
		   $srcAppFabInstaller = ($global:installAppFabricFilePath + $global:exeAppFabric)
		   $dstAppFabInstaller = ($global:localAppFabInstallPath + $global:exeAppFabric)
			Write-Host -ForegroundColor Cyan ("Copying AppFabric Installer.")
			Write-Host -ForegroundColor Cyan ("    Source      : "  + $srcAppFabInstaller)
			Write-Host -ForegroundColor Cyan ("    Destination: " + $dstAppFabInstaller)
			
			Copy-Item $srcAppFabInstaller -Destination $dstAppFabInstaller
			}
			#Set Executeable and logfile paths for AppFabric installer.
			$exeAppFabric = ($dstAppFabInstaller)
			$exeAppFabricInstallLog =  ($global:localLogFiles+ "\" + $global:localComputerName + "-AppFabricInstall.log" )
			#Make sure Windows Update is running, per the system requirements of the 
			$boolIsWURunning = IsWindowsUpdateRunning
			If ($boolIsWURunning -eq $true){
				Write-Host -ForegroundColor Magenta $exeAppFabric
				If ((Test-Path $exeAppFabric) -eq $true){
					Set-Alias AppFabInstall $exeAppFabric
				    Start-Process AppFabInstall -Verb runAs -Wait -ArgumentList  ("/i " + $strOptions +  " /logfile:" + $exeAppFabricInstallLog)
					Write-Host $LASTEXITCODE
					}
				Else
				{
					Write-Host ("ERROR: Could not find " + $exeAppFabric)
					}
			}
		Else{
			Write-Host -ForegroundColor Red "Windows Update Server is required for install of AppFabric."
			Write-Host -ForegroundColor Yellow "Please manally start the Windows Update Service and re-run script"
			Exit 1
			}
	}
	
	#Set AppFabric Filrewall Settings
	Write-Host ("Setting Firewall ports for AppFabric")
	Set-AppFabFirewall
	
    #Check again for pending reboots... 

	If (Get-PendingReboot -eq $true){
		Write-Host -ForegroundColor Yellow "WARNING: There are pending reboots required for this system."
		Write-Host -ForegroundColor Yellow "The script will continue when you reboot system."
		New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name RunOnce -PropertyType String -Value ("powershell -file " + $global:localScriptPath + "\SetUpAppFabric.ps1")
		Restart-Computer -Force
		}
		
    #Configure AppFabric CacheCluster
		
		
		Import-Module DistributedCacheAdministration
		Import-Module DistributedCacheConfiguration	
		
		$NewCacheCluster = ($boolIsPriSrv)
		If ($NewCacheCluster -eq $true){
			Write-Host -ForegroundColor Cyan "Creating New Cache Cluster"
		
			New-CacheCluster -Provider $strProvider -ConnectionString $strConStr -Size  

	$Get_CacheClusterInfo_Command = Get-CacheClusterInfo -Provider $provider -ConnectionString $connection_string

# Look for a PowerShell script parameter that specifies this is a new cache cluster

{
   Write-Host "`nNew-CacheCluster -Provider $provider -ConnectionString "`
      "`"$connection_string`" -Size $cluster_size" -ForegroundColor Green
   New-CacheCluster -Provider $provider -ConnectionString $connection_string -Size $cluster_size    
   #
   <#Set-CacheClusterSecurity -SecurityMode Transport -ProtectionLevel None #<--- add to CSV
   
   $appFabSvcAcct
   $appCachePort - 22233
   $appClusterPort - 22234
   $appArbPort - 22235
   $appRepPort - 22236
   
}


		
			
		
		
		
		
			
	