# Install/Upgrade only script.
# 	- Assumes we are installing to the RollCall/Synapps server
#
# Script is compatible with the following sites/services:
#	RollCall
#	RollCallService
#	ClearingHouse

param([string]$WebAppName="ClearingHouse",[string]$BuildType="",[string]$environment="none",[string]$buildversion="none",[string]$webroot="d:\Synapps",[string]$Optional)

# Import common functions
ImportSystemModules -verbose -Force
Import-Module ..\lib\Functions_common.psm1 -verbose -Force


$StartTime=getStartTime
#variables:
$WebSiteName		= "Default Web Site"
$WebAppFilePath		= "$webroot\$WebAppName"
$binroot			= "d:\binroot"

$ServerName			="$env:ComputerName"
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"
$AppPoolName		="$WebAppName"
$DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain


if ((Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path -eq $null) {
	throw 'Missing a Logroot Folder. Must create a Logroot folder, and map share as \\' + $env:computername + '\logroot'
}else{
	$logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path
	$logroot_install	="$logroot\install"
}
#Start Logging
#$LogRootApp = "$logroot\$WebAppName"

CreateLogFilePath "$WebAppName" "$ServerName" "$Environment" "$logroot_install"

# Test $BuildType argument
switch($BuildType)
{
	"ci" {$BuildType = "continuousintegration"}
	"db" {$BuildType = "directedbuilds"}
	"rc" {$BuildType = "releasecandidate"}
	"r"  {$BuildType = "release"}

	default{ LogMessage "error" "Parameter must be specified - BuildType: ci (ContinuousIntegration), db (DirectedBuild), rc (ReleaseCandidate), r (Release)" }

}

# Test $BuildVersion Argument
$AvailBuilds=(gi \\karmalab.net\builds\$BuildType\sait\VCI\products\branch\).GetDirectories()
while (($AvailBuilds | %{$_.Name}) -notcontains $BuildVersion){
	$AvailBuilds
	$BuildVersion= Read-Host 'Enter Build Version'
}
$BuildStorage="\\karmalab.net\builds\$BuildType\sait\VCI\products\branch\$BuildVersion\deliverables\$WebAppName"
LogMessage "info" "Build Storage: $BuildStorage"

# Test $environment Argument
if ($environment -eq "none"){ LogMessage "error" "Parameter must be specified - Environment"}


#If current share for webroot exists, get the physical path and use for $webroot
if(test-path \\$env:computername\webroot) {
		$webroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT'").path
}

#If current share for binroot exists, get the physical path and use for $webroot
if(test-path \\$env:computername\binroot) {
		$binroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'BINROOT'").path
}else{
	IF (!(TEST-PATH $binroot)){MD $binroot}
}

# Test if $webroot physical drive exists
if (!(Test-Path (split-path $webroot -qualifier))){
	 LogMessage "error" "It appears that you do not have a WEBROOT share, and the default location of $webroot does not exist.`nSpecify a valid webroot argument. Drive/Path of webroot does not exist: " + $webroot
}else{
	#Set up the webroot folder, if not exist
	IF (!(TEST-PATH $webroot)){MD $webroot}
}

$webroot_archive	    ="$webroot" + "_archive"
$webConfig			="$WebAppFilePath\web.config"
$BuildLabel			= $WebAppName + "_" + $buildversion

LogMessage "info" "Testing if User is an administrator."
if(!(Test-Administrator)){
	#Write "Please run as Administrator";break
	LogMessage "error" "Please run as Administrator."
	}else{
	LogMessage "info" "User is an Administrator."
	}
	
#Setting build location and username based on domain where box is located.

#ph.expeso.com 
#ch.expeso.com	
switch ($DnsDomain)
{
	#Production 
	"cct.expecn.com"
	{
		if ($ServerName.Substring(0,3) -eq "che") {
			# Production Chandler Jenkins file share			
			$BuildStorage = $BuildStorage.Replace("\\karmalab.net\builds", "\\che-filidx.idx.expedmz.com")
			#$BuildStorage = "\\che-filidx.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName + "\"
		}elseif($ServerName.Substring(0,3) -eq "phe"){
			# Production Phoenix Jenkins file share
			$BuildStorage = $BuildStorage.Replace("\\karmalab.net\builds", "\\phe-filidxprd.idx.expedmz.com")		
			#$BuildStorage		= "\\phe-filidxprd.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName + "\"
		}else{
			LogMessage "error" "Not able to determine physical location of server based on naming. Assumption is that the first 3 characters of the server name describe geographic location. `n'CHE' Chandler '`'PHE' Phoenix"
		}
		
		#Manual override until firewall rule in place
		#$buildstorage		= "\\chclappadfs02\d$\binroot" + $WebAppName + "\Service"
		$versionTxt			="version.txt.config"
		$historyTxt			="History.txt.config"
	}
	
	#LAB CCT servers
	"cctlab.expecn.com"
	{
		if ($ServerName.Substring(0,3) -eq "che") {
			# Production Chandler Jenkins file share			
			$BuildStorage		= "\\che-filidx.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName + "\"
		}elseif($ServerName.Substring(0,3) -eq "phe"){
			# Production Phoenix Jenkins file share
			$BuildStorage		= "\\phe-filidxprd.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName + "\"
		}else{
			LogMessage "error" "Not able to determine physical location of server based on naming. Assumption is that the first 3 characters of the server name describe geographic location. `n'CHE' Chandler '`'PHE' Phoenix"
		}
		
		#Manual override until firewall rule in place
		$BuildStorage		= "\\chclappadfs02\binroot\" + $WebAppName + "\"
		$versionTxt			="version.txt"
		$historyTxt			="History.txt"
	}
	
	default
	{
		$versionTxt			="version.txt"
		$historyTxt			="History.txt"
	}

}



LogMessage "info"  "environment: $environment"
LogMessage "info"  "buildversion: $buildversion"
LogMessage "info"  "Optional: $Optional"

LogMessage "info" "Begin Logging"
LogMessage "info" "AppName: $WebAppName"
LogMessage "info" "BuildLabel: $BuildLabel"
LogMessage "info"  "Based on $DnsDomain - Setting buildstorage to $BuildStorage"
LogMessage "info" "envusername: $envusername"
LogMessage "info" "webroot: $webroot"
LogMessage "info" "webroot_archive: $webroot_archive"
LogMessage "info" "logroot: $logroot"
LogMessage "info" "logroot_install: $logroot_install"
LogMessage "info" "scriptexecutedfrom: $pwd"
LogMessage "info" "StartTime: $StartTime"
LogMessage "info" "installTimeStamp: $installTimeStamp"
LogMessage "info" "defaultconfig: $defaultconfig"
LogMessage "info" "ServerName: $ServerName"


# STEP 1 - Environment setup.
# Testing if current context is admin
LogMessage "info" "Begin Environment Setup"

# Step 1b - Is execution policy set to restricted? Attempt to set 
LogMessage "info" "Testing execution policy."
try {Set-ExecutionPolicy bypass -force; "Execution OK"}
catch {
	LogMessage "warn" "Unable to set Execution Policy."
	LogMessage "warn" "Current ExecutionPolicy:  $(Get-ExecutionPolicy)"
	}

# Step 1d - set appcmd Alias
# Commenting out since we're not using it.
LogMessage "info" "Setting appcmd Alias"
new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force


# Step 2f - Getting build location and copy locally
LogMessage "info" "Getting build location"
if(!(test-path "$buildstorage")){
	LogMessage "error" "Path not found, please make sure $BuildStorage\$buildversion exists"
		}


# Step 2f+ - Copy zip file locally
$buildZip=(gci $BuildStorage\*.zip).FullName
$zipFileName = (Split-Path $buildZip -leaf)
$localZipPath="$Binroot\$WebAppName\$zipFileName"
$localZipDir=(Split-Path $localZipPath)
robocopy (Split-Path $buildZip) $localZipDir $zipFileName

#Step 3 - Make sure IIS is running - known good
if (($s=get-service w3svc).status -ne "running"){Start-Service -name w3svc}else{
	#testing complex logging  as a workaround
	LogMessage "info" $($s.name + " " + $s.status)
	}

# STEP 6 - Start Deployment of App
LogMessage "info" "Deploying $WebAppName"
LogMessage "info" "Stopping $WebAppName website "



# Delete webroot Share to prevent open handles
LogMessage "info" "deleting webroot share - prevents open handles"
if(test-path \\$env:computername\webroot){net share webroot /d /y 2>&1 | Out-Null}
if (!$?){
	LogMessage "info" "Webroot could not be deleted. Trying $webroot.."
	net share webroot /d /y}else{
		LogMessage "info" "\\$env:computername\webroot deleted"
		}

if (!(test-path "$webroot_archive\$WebAppName")){md "$webroot_archive\$WebAppName"}
		
# Step ## - Export Current Site/VDir/AppPool configuration to archive folder
BackupWebSiteConfiguration "$WebSiteName" "$webroot_archive\$WebAppName\$installTimeStamp\$WebAppName.SiteConfigurations."

# Step **- Stop WebAppPool if it already exists
if (test-path "IIS:\AppPools\$AppPoolName") { if ((Get-WebAppPoolState "$AppPoolName").Value -ne "Started") {Start-WebAppPool "$AppPoolName"} }
Read-Host "waiting"
# Step ## - Backup previous version of application
if(test-path $WebAppFilePath){	
	robocopy $WebAppFilePath $webroot_archive\$WebAppName\$installTimeStamp\$WebAppName *.* /E /NP /NS /NFL /NDL
	Remove-item $WebAppFilePath -recurse -force
	md $WebAppFilePath
	}else{
	
	# If folder doesn't exist, create it, create new VDIR and AppPool
	LogMessage "warn" "Creating new site at $WebAppFilePath"
	md $WebAppFilePath
	}

# Set webapp physical path
 #set-itemproperty IIS:\Sites\icrscids.expedia.com\POSService -name physicalPath -value "$WebAppFilePath"
Set-ItemProperty "IIS:\Sites\$WebSiteName\$WebAppName" -Name physicalPath -value "$WebAppFilePath"

# Step ## - Backup of Web.config & Verstion.txt
LogMessage "info" "Backup of Web.config & $versionTxt"

$VersionBack = "$webroot_archive\$WebAppName\$WebAppName.$installTimeStamp\$VersionTxt"
$oldweb_config= "$webroot_archive\$WebAppName\$WebAppName.$installTimeStamp\web.config"

# Step ## - Unzip steps
$shell = new-object -com shell.application
$shell.NameSpace($WebAppFilePath).copyhere($shell.Namespace(($localZipPath)).items())


##################################################
##### Select web.config 
if (Test-Path "$WebAppFilePath\configs.2008\$environment\web.config") 
	{ 
		copy "$WebAppFilePath\configs.2008\$environment\web.config" $WebAppFilePath -Force
		rd "$WebAppFilePath\configs.2008" -Force -Recurse
		rd "$WebAppFilePath\configs" -Force -Recurse
	}else{
		$a=(gci "$WebAppFilePath\configs" -Recurse -Include "web.config") | %{$_.Directory} | %{$_.Name}
		#LogMessage "warn" (gci "$WebAppFilePath\configs" -Recurse -Include "web.config") | %{$_.Directory})
		LogMessage "error" "Must specify one of these valid environment names:`t $a`n`n" 
	}

$folderlist="$logroot\$WebAppName","$WebAppFilePath"

$folderlist |foreach {IF (!(TEST-PATH $_))
		{	# folders should already be there, if not, reset all permissions just in case
			MD $_
				# STEP 4b - Grant permissions
			LogMessage "info" "Grant permissions to folder $_"
			icacls $_ /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)(RX)"
			icacls $_ /grant:r "IIS APPPOOL\DefaultAppPool:(OI)(CI)(RX)"
			icacls $_ /grant:r "IIS APPPOOL\" + $AppPoolName + ":(OI)(CI)(F)"
		}
	}

	
# Step 6b - setting User and version number in Version.txt
if (test-path $VersionBack) {
	LogMessage "info" "Getting old version number in $VersionBack"
	[string]$OldVersion=(gc $VersionBack) -match "\b[v]\d{1}\."
	$OldVersion=$OldVersion.substring(45,12).trim()
}

"<pre>"															| out-file "$WebAppFilePath\$versionTxt"
"Package installed from $buildZip"								| out-file "$WebAppFilePath\$versionTxt" -append
[string]$currentuser=whoami
"You are looking at:  $env:computername" 						| out-file "$WebAppFilePath\$versionTxt" -append
"deployment executed by $currentuser on $installTimeStamp"	 	| out-file "$WebAppFilePath\$versionTxt" -append
"Build updated from $OldVersion to $buildversion"				| out-file "$WebAppFilePath\$versionTxt" -append


# Step 6C - Creating History.txt file to keep track of ALL deployments ever done.
if (!(test-path "$webroot_archive\$WebAppName\$historyTxt")){"<pre>"				| out-file "$webroot_archive\$WebAppName\$historyTxt"}
"Build updated from $OldVersion to $buildversion by $currentuser `t on $installTimeStamp" | out-file "$webroot_archive\$WebAppName\$historyTxt" -append
copy "$webroot_archive\$WebAppName\$historyTxt" "$WebAppFilePath\$historyTxt"

# STEP ## - CreateEventLogSource
..\bin\CreateEventLogSource.exe $AppPoolName

# STEP ## - Post deployment steps.

LogMessage "info" "Starting AppPool"
if ((Get-WebAppPoolState $AppPoolName).Value -ne "Started") {Start-WebAppPool $AppPoolName}

#Recreating Webroot share
LogMessage "info" "Recreating Webroot share"
#$webRootShare = Split-Path -parent $webroot
if(!(test-path \\$env:computername\logroot)){	
	net share logroot=$logroot
}
if(!(test-path \\$env:computername\webroot)){	
	net share webroot=$webroot
}
if(!(test-path \\$env:computername\webroot_archive)){	
	net share webroot_archive=$webroot_archive
}
if(!(test-path \\$env:computername\binroot)){	
	net share binroot=$binroot
}
# Insert StopTime & Close the Log File
CloseLogFile 

# Post deployment tasks - mostly cosmetic and usability
# Displays logs for the whole deployment making it a little easier to pull up other servers from inside a log.
Write-Host "HTML Logs for the Deployment: "
$logHTML = getLogFilePathHtml
"$env:computername" | foreach {
	if($_ -eq $env:computername)
		{
			$attachment = $logHTML.Replace($logroot_install, "\\$_\logroot\install")
			($a =  "--->  " + $attachment)
			 $a			| out-file "$WebAppFilePath\$versionTxt" -append
		} else {
			 ($a = "      " + $logHTML.Replace("$logroot_install\$env:computername", "\\$_\logroot\install\$_"))
			  $a		| out-file "$WebAppFilePath\$versionTxt" -append		
		}
	}

# getting web.config differences.
if (test-path $oldweb_config) {
	$diff_webconfig = compare-object -ReferenceObject $(gc $webconfig) -DifferenceObject $(gc $oldweb_config) -PassThru  -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
}

$oldVersionTxt_UNCPath="\\$ServerName\webroot_archive\$WebAppName\$installTimeStamp\$WebAppName\$versionTxt"
$oldWebConfig_UNCPath="\\$ServerName\webroot_archive\$WebAppName\$installTimeStamp\$WebAppName\web.config"
$newVersionTxt_UNCPath="\\$ServerName\webroot\$WebAppName\$versionTxt"
$newWebConfig_UNCPath="\\$ServerName\webroot\$WebAppName\web.config"


$emailbody += 'New Version.txt: <a href="' + $newVersionTxt_UNCPath + '">' + $newVersionTxt_UNCPath + '</a><br>'
$emailbody += 'New web.config: <a href="' + $newWebConfig_UNCPath + '">' + $newWebConfig_UNCPath + '</a><br>'

$emailbody += 'Old Version.txt: <a href="' + $oldVersionTxt_UNCPath + '">' + $oldVersionTxt_UNCPath + '</a><br>'
$emailbody += 'Old web.config: <a href="' + $oldWebConfig_UNCPath + '">' + $oldWebConfig_UNCPath + '</a><br>'


$emailbody += "Differences (if any) between New web.config and one stored as backup: "
$diff_webconfig | foreach {$emailbody += "$_ <br>"}
$notes | foreach {$emailbody += "$_ <br>"}
#amail "$env:username@expedia.com" $("$env:username@expedia.com","cctrel@expedia.com") "Deployment on $environment - $env:computername finished successfully"  $emailbody -attachment $attachment
#amail "vcirel@expedia.com" $("mcraig@expedia.com"; "$env:username@expedia.com") "$WebAppName - Deployment on $environment environment - $env:computername finished successfully"  $emailbody -attachment $attachment

# Verify that Extended HTTPErr attributes are being logged
if ((get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters").ErrorLoggingFields -eq $null){
	EnableExtendedHTTPErrAttributes
	RebootRequired("True")
}