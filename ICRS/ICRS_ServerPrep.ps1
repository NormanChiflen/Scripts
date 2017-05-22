#################################################################################################################################################
#                  Script for setting up blank CustomerInteractionDataService IIS server                                    					#
#                                                                                                   											#
#                     v1.0 Copied and heavily modified by Michael Craig                             											#
#							-- Using Voyager_prep_step1-server.ps1 as source                        											#
#  Scripts available here: p1986\sait\DeploymentAutomation_selfDeployApp\ICRS\ICRS_ServerPrep.ps1										     	#
#################################################################################################################################################
#
# Script is designed to be exectuted Locally on the server, running Powershell as Administrator.
#
# The $environment parameter is the only required param. Must match what is available in icrs_environments.csv
# The $webroot can be specified on the command line. Default is d:\webroot
# The $logroot is defaulted at e:\logroot
# The $binroot is defaulted at e:\binroot
#
#
# The "default web site" will be Stopped and it's physical path set to $webroot
#	A new Website will be created for each 'farm'
#		Each 'farm' will have a physical path of $webroot\$farm
#		Each 'farm' will have a virtual directory for each $WebAppNames member a $webroot\$WebSiteName\$WebAppName
#		Each 'farm' will be hosted on a custom HTTP and HTTP port
# 		Each 'farm' and virtual directory will have distinct ApplicationPools (named $Farm_$WebSiteName)
# 
#

param([string]$environment="", [string]$webroot="d:\webroot")

#$SHUNTurl="shuntFarm";$SHUNT_HTTPport="80";$SHUNT_HTTPSport="443";

$farm1=@("farm1","81","1443")
$farm2=@("farm2","82","2443")
$farm3=@("farm3","83","3443")

$WebAppNames=("CTIWebService", "IVRWebService", "POSService")

ImportSystemModules
Import-Module ..\lib\Functions_common.psm1 -verbose -Force

$defaultconfig ="icrs_environments.csv"
$DefaultCSV=Import-Csv .\$defaultconfig

# Test $Environment param specified and correct?
if ((getEnvironments($DefaultCSV)) -notcontains "$environment") {write-error "`$environment must be specified";"Select From: ";getEnvironments($DefaultCSV);break;}

# logroot defaulting to e:\logroot
$logroot = "e:\logroot"
$webroot_archive = $webroot + "_archive"

# STEP 1 - Environment setup.
Test-Administrator

# Time executiong of the script started - for unique logging per script execution
if($StartTime){ setStartTime $StartTime }

#Create CCT Ops share for centralized file storage and such
$cctshare="c:\cct_ops"
IF (!(TEST-PATH $cctshare)){MD $cctshare}

#Check if logroot is created and shared
CreateLogrootShare $logroot

#If current share for webroot exists, get the physical path and use for $webroot
if(test-path \\$env:computername\webroot) {
		$webroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT'").path
}

# Test if $webroot physical drive exists
if (!(Test-Path (split-path $webroot -qualifier))){
	 LogMessage "error" "Specify valid webroot argument. Drive/Path of webroot does not exist: " + $webroot
}else{
	#Set up the webroot folder, if not exist
	IF (!(TEST-PATH $webroot)){MD $webroot}
}

#Set up the webroot_archive folder, if not exist
if ($webroot_archive -eq (Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT_ARCHIVE'").path) { $webroot_archive }else{$webroot_archive}
IF (!(TEST-PATH $webroot_archive)){MD $webroot_archive}

# Set up file shares - Logroot is already done in CreateLogrootShare func.
if(!(test-path \\$env:computername\webroot)){	
	net share webroot=$webroot
}
if(!(test-path \\$env:computername\webroot_archive)){	
	net share webroot_archive=$webroot_archive
}

# Is execution policy set to restricted? Attempt to set 
Set-ExecutionPolicyUnrestricted

#AppCMD alias
new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force

# STEP 2 - Loading config file (hard coded since there will be one shared across environments)
	 
#Finding values for correct environment.
 $arrayposition=-1    
 Foreach($i in $DefaultCSV){
 $arrayposition++
 if ($i.environment -eq $environment)
	 {$EnvironmentServers= $i.ServersInEnvironment.split(";")
	 $IISCertificatePath = $i.IISCertificatePath
	 $IISCertificatePwd = $i.IISCertificatePwd
	 $IISCertName = $i.IISCertName
	 #$appPoolUser = $i.AppPoolUser
	 #$appPoolPassword = $i.AppPoolUserPassword
	 #$i.AppPoolUserPassword='************'
	 $arrayposition
	 write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
	}

# STEP 3 - install IIS
write-host -f cyan "Installing IIS"
InstallIIS-SetDefaultConfiguration

# Step 3.1 - Disable SSL 2.0
DisableSSL20

# Step 3.2 - Disable EI ESC
Disable-InternetExplorerESC

#Confirm .Net Framework 4.0 is installed
TestAndInstalldotNet40

# Grant $AppPoolUser security rights to IIS
#C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -ga $AppPoolUser

# STEP 5 - Install server level certs
write-host -f cyan "Installing Certs"

# actually installing the cert. () are to display output instead of just processing it.
($iiscert=certinstallloop $IISCertificatePwd $IISCertificatePath)
# saving the cert name for setting up Voyager portion (mostly to assign ngat app pool to e:\ngat)
$iiscert | out-file c:\cct_ops\iis_cert.txt
Write-Host -ForegroundColor Green "Cert name saved to a local file in C:\cct_ops\iis_cert.txt"

# STEP 7 - Enable PS Remoting on system
EnablePSRemoting

# Stop Default Web Site
if ((Test-Path("IIS:\Sites\Default Web Site"))) { 
	Stop-Website -Name "Default Web Site" 
}

function CreateSites($WebSiteName, $WebSiteHTTPPort, $WebSiteHTTPsPort){

	$WebSitePhysicalPath = "$webroot\$WebSiteName"
	if(!(test-path $WebSitePhysicalPath)) {md $WebSitePhysicalPath}
	
	# Create New web site
	if (!(Test-Path("IIS:\Sites\$WebSiteName"))) {
		#Create AppPool and Site
		if (!(test-path "IIS:\AppPools\$WebSiteName")) {New-Item "IIS:\AppPools\$WebSiteName" -force}
		New-Website -Name $WebSiteName -port $WebSiteHTTPPort -PhysicalPath $WebSitePhysicalPath -ApplicationPool $WebSiteName
	}else{
		#Set Site physical path and properties
		Set-ItemProperty "IIS:\Sites\$WebSiteName" -Name physicalPath -value "$WebSitePhysicalPath"
	}

	# This section not used: using Default App Pool
	# Create New "ICRS" ApplicationPool
	#if (!(test-path IIS:\AppPools\$WebAppName)) {New-Item "IIS:\AppPools\$WebAppName" -force}
	#	Set-ItemProperty "IIS:\AppPools\$WebAppName" managedRuntimeVersion v4.0

	# Create New web applications
	$WebAppNames | %{
		if (!(Test-Path("IIS:\Sites\$WebSiteName\$_"))) {
			#Create Site
			$appPoolName="$WebSiteName" + "_" + "$_"
			if (!(test-path "IIS:\AppPools\$appPoolName")) {New-Item "IIS:\AppPools\$appPoolName" -force}
			New-WebApplication -Site $WebSiteName -Name $_ -PhysicalPath "$WebSitePhysicalPath\$_" -ApplicationPool $appPoolName -force
		}else{
			#Set Site physical path and properties
			Set-ItemProperty "IIS:\Sites\$WebSiteName\$_" -Name physicalPath -value "$WebSitePhysicalPath\$_"
		}
	}

	# Stop site, if it is started
	("$WebSiteName") | %{ if ((gi "IIS:\Sites\$_").State -eq "Started")  { (gi "IIS:\Sites\$_").Stop() }; "$_ is " + (gi "IIS:\Sites\$_").State }

	# Remove all site bindings
	Get-WebBinding -Name $WebSiteName | Remove-WebBinding

	# Add Site Binding for :$WebSiteHTTPsPort only
	New-WebBinding -Name $WebSiteName -Port $WebSiteHTTPPort -IPAddress * -Protocol http
	New-WebBinding -Name $WebSiteName -Port $WebSiteHTTPsPort -IPAddress * -Protocol https
	if (!(test-path IIS:\SslBindings\0.0.0.0!$WebSiteHTTPsPort)) { Get-ChildItem cert:\LocalMachine\MY | ?{$_.Subject -match "\$IISCertName"} | New-Item IIS:\SslBindings\0.0.0.0!$WebSiteHTTPsPort }

	# Not creating virtual directories at this step
	#Set up virtual directory
	#CreateSiteVdir $WebSitePhysicalPath  $WebSiteName $WebAppName $WebVDirName $appPoolUser $appPoolPassword

	("$WebSiteName") | %{ if ((gi "IIS:\Sites\$_").State -eq "Stopped")  { (gi "IIS:\Sites\$_").Start() }; "$_ is " + (gi "IIS:\Sites\$_").State }

}

CreateSites $farm1[0] $farm1[1] $farm1[2]
CreateSites $farm2[0] $farm2[1] $farm2[2]
CreateSites $farm3[0] $farm3[1] $farm3[2]

# Testing if reboot is required
write-host -f cyan "Testing if reboot is required"

# Set extended properties for HTTPErr
EnableExtendedHTTPErrAttributes

# Force reboot to enable HTTPErr configuration
RebootRequired("True")