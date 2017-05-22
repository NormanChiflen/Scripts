#C:\Windows\System32\WindowsPowerShell\v1.0\Modules\ Functions 
#	import-module .\CustomerInteractionDataService_Functions.psm1
#	Import-Module C:\source\depot_1986\sait\DeploymentAutomation_selfDeployApp\lib\CustomerInteractionDataService_Functions.psm1

######################################
#       Module Scope Variables       #
######################################

function CreateSiteVdir($WebRoot, $WebSiteName,$WebAppName, $WebVDirName, $appPoolUser, $appPoolPassword){
	#In Use by:
	#	CustomerInteractionDataService_webservice_install.ps1
	
	#Assumes IIS:\Sites\$WebSiteName\$WebAppName exists, along with physical path
	#Create a VDir under $WebSiteName\$WebAppName
	#Create AppPool with name pattern $WebAppName_$WebVDirName
	#Create physical path using $WebSiteName\$WebAppName\$WebVDirName as well
	

	$poolName = "$WebAppName" + "_" + "$WebVDirName"
	
	if (!(Test-Path IIS:\Sites\$WebSiteName\$WebAppName)) { throw "Specified siteName does not exist. Make sure you have run the ServerPrep script."}
	
	#Set up virtual directory
		"Stopping $WebAppName appPool if it exists"
		if ((Test-Path IIS:\AppPools\$poolName)) { 
			if ((gi "IIS:\AppPools\$poolName").State -eq "Started") { (gi "IIS:\AppPools\$poolName").Stop() }; "$WebAppName is " + (gi "IIS:\AppPools\$poolName").State
		}
			
		# Remove VDir apps if it exists?
		if ((Test-Path "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName")) { Remove-Item -force -recurse "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName"};
		
		# Remove AppPool
		if ((Test-Path "IIS:\AppPools\$poolName")) { Remove-Item -force -recurse "IIS:\AppPools\$poolName" };
		
		# remove and recreate folder
		if (Test-Path "$WebRoot\$WebAppName\$WebVDirName") { ri -force -recurse "$WebRoot\$WebAppName\$WebVDirName"};
		new-item "$WebRoot\$WebAppName\$WebVDirName" -Force -Type Directory 
		
		# STEP 9.1 - Remove and Create App Pools
		 New-Item "IIS:\AppPools\$poolName"
		 
		# STEP 9.1.1 - Set .net version number
		Set-ItemProperty "IIS:\AppPools\$poolName" managedRuntimeVersion v4.0

		# STEP 9.2 - Create VDIRS
		IF (!(TEST-PATH "$WebRoot\$WebAppName\$WebVDirName")){MD "$webroot\$WebAppName\$WebVDirName"}
		New-Item "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName" -physicalPath "$WebRoot\$WebAppName\$WebVDirName" -type Application -force

		# STEP 9.3 - Assign App Pools to sites/vdirs
		set-ItemProperty "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName" -name applicationPool -value "$poolName"

		# STEP 9.4 - Set app pool identity
		$pool = Get-Item "IIS:\AppPools\$poolName"
		$pool.processModel.username = [string]("$appPoolUser")
		$pool.processModel.password = [string]("$appPoolPassword")
		$pool.processModel.identityType = "SpecificUser"
		$pool | Set-Item

		# STEP 9.4 - Start AppPool if not started
		if ((gi "IIS:\AppPools\$poolName").State -ne "Started") { (gi "IIS:\AppPools\$poolName").Start() }
		
}


