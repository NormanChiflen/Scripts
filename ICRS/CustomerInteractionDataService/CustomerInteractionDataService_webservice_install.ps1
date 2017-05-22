# Install/Upgrade only script.
# version 1.0


param([string]$environment="none",[string]$buildversion="none",$WebVDirName="v1",$webroot="d:\webroot",$Optional, [DateTime]$StartTime = "1/1/1990")

# Import common functions
ImportSystemModules
Import-Module ..\..\lib\Functions_common.psm1 -verbose -Force
import-module ..\..\lib\CustomerInteractionDataService_Functions.psm1 -Force

if($StartTime="1/1/1990"){$StartTime=getStartTime}
#variables:
$WebSiteName		= "CustomerInteractionDataService"
$WebAppName			= "CustomerInteractionDataService"

$BuildLabel			= $WebAppName + "_" + $buildversion
$ServerName			="$env:ComputerName"
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"
$defaultconfig		="..\icrs_environments.csv"
$AppPoolName		="$WebAppName" + "_" + "$WebVDirName"
$DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain


if ((Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path -eq $null) {
	throw 'Missing a Logroot Folder. Must create a Logroot folder, and map share as \\' + $env:computername + '\logroot'
}else{
	$logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path
	$logroot_install	="$logroot\install"
}
#Start Logging
$LogRootApp = "$logroot\$WebAppName\$WebVDirName"

CreateLogFilePath "$BuildLabel" "$ServerName" "$Environment" "$logroot_install"

#If current share for webroot exists, get the physical path and use for $webroot
if(test-path \\$env:computername\webroot) {
		$webroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'WEBROOT'").path
}

# Test if $webroot physical drive exists
if (!(Test-Path (split-path $webroot -qualifier))){
	 LogMessage "error" "It appears that you do not have a WEBROOT share, and the default location of $webroot does not exist.`nSpecify a valid webroot argument. Drive/Path of webroot does not exist: " + $webroot
}else{
	#Set up the webroot folder, if not exist
	IF (!(TEST-PATH $webroot)){MD $webroot}
}

$webroot_archive	    ="$webroot" + "_archive"
$webConfig			="$webroot\$WebSiteName\$WebVDirName\web.config"


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
			$buildstorage		= "\\che-filidx.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName
		}elseif($ServerName.Substring(0,3) -eq "phe"){
			# Production Phoenix Jenkins file share
			$buildstorage		= "\\phe-filidxprd.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName
		}else{
			LogMessage "error" "Not able to determine physical location of server based on naming. Assumption is that the first 3 characters of the server name describe geographic location. `n'CHE' Chandler '`'PHE' Phoenix"
		}
		
		
		#Manual override until firewall rule in place
		$buildstorage		= "\\phsxfilcct001.idx.expedmz.com\ICRS\CCT\binroot\" + $WebAppName
		$buildstorage		= "\\PHEXWBARID001.cct.expecn.com\c$\binroot\" + $WebAppName
		$versionTxt			="version.txt.config"
		$historyTxt			="History.txt.config"
	}
	
	#LAB CCT servers
	"cctlab.expecn.com"
	{
		if ($ServerName.Substring(0,3) -eq "che") {
			# Production Chandler Jenkins file share			
			$buildstorage		= "\\che-filidx.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName
		}elseif($ServerName.Substring(0,3) -eq "phe"){
			# Production Phoenix Jenkins file share
			$buildstorage		= "\\phe-filidxprd.idx.expedmz.com\Release\sait\CRM\products\" + $WebAppName
		}else{
			LogMessage "error" "Not able to determine physical location of server based on naming. Assumption is that the first 3 characters of the server name describe geographic location. `n'CHE' Chandler '`'PHE' Phoenix"
		}
		
		#Manual override until firewall rule in place
		$buildstorage		= "\\chclappadfs02\d$\binroot\" + $WebAppName
		$versionTxt			="version.txt"
		$historyTxt			="History.txt"
	}
	
	"karmalab.net"
	{
		$buildstorage		= "\\karmalab.net\builds\directedbuilds\sait\CRM\products\" + $WebAppName
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
LogMessage "info"  "Based on $DnsDomain - Setting buildstorage to $buildstorage"
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


# Loading Configuration function here. This will allow us to generate Config file without running deployment.
# None of of the stuff below is executed until the function is called
# ### To make sure nothing breaks, the function should be 'dot sourced' to expose variables to the rest of the script.

Function ModifyConfigFiles ($webconfig) {
	############################################
	# STEP 7 - Change web.config

	# Step 7b - Modifying web.config via XML
	LogMessage "info" "Modifying web.config via XML" 
	$doc = new-object System.Xml.XmlDocument
	$doc.Load($webConfig)

	
	#Convert LogRootApp to format needed by Log4Net
	$LogRootApp=$LogRootApp.Replace("\", "\\") + "\\"
	
	$doc.SelectSingleNode("//add[@name='CustomerInteractionConnectionString']").connectionString = $CustomerInteractionConnectionString
	$doc.SelectSingleNode("//appender[@name='EventLogAppender']/applicationName").value = "$WebAppName" + "_" + "$WebVDirName"
	$doc.SelectSingleNode("//appender[@name='FileAppender']/file").value = $LogRootApp
	$doc.SelectSingleNode("//appender[@name='BlobFileAppender']/file").value = $LogRootApp + "blob" + "\\"
	
	
	$doc.Save($webConfig)

}


# STEP 1 - Environment setup.
# Testing if current context is admin
LogMessage "info" "Begin Environment Setup"


# Step 1b - Is execution policy set to restricted? Attempt to set 
LogMessage "info" "Testing execution policy."
try {Set-ExecutionPolicy bypass -scope localmachine -force; "Execution OK"}
catch {
	LogMessage "warn" "Unable to set Execution Policy."
	LogMessage "warn" "Current ExecutionPolicy:  $(Get-ExecutionPolicy)"
	}


# Step 1c - load system modules
LogMessage "info" "Loading System Modules"
LogMessage "info" $(Import-Module ServerManager -passthru)
LogMessage "info" $(Import-Module WebAdministration -passthru)


# Step 1d - set appcmd Alias
# Commenting out since we're not using it.
LogMessage "info" "Setting appcmd Alias"
new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force


# STEP 2 - Loading config file and validating user input
LogMessage "info" "Loading config file and validating user input"
if(test-path -path $defaultconfig){
		$DefaultCSV=Import-Csv .\$defaultconfig
	}else{
		LogMessage "error" "$defaultconfig was not in the same location as the script." 
	}

	
# Step 2b - Setting the environment.
#   Basically $environment="xx" is now an optional variable. Only the version needs to be specified
LogMessage "info" "Auto determining your environment"
if($environment -eq "none"){
	$environment=($DefaultCSV | ? {$_.ServersInEnvironment.split(";") -eq $env:computername}).environment
	LogMessage "info" "Environment is: $environment"
	}

	
# Step 2c - If enabled - Auto determining latest build based on currently deployed build.
if($Optional -eq "auto"){
	LogMessage "info" "Auto Deployment selected. Auto determining build to install."
	#Determining version number from $versionTxt.config
	[string]$CurrentVersion=(gc $webroot\$WebAppName\$WebVDirName\$versionTxt) -match "\b[v]\d{1}\."
	$CurrentVersion=$CurrentVersion.substring(45,12).trim()
	$CurrentVersionShort=$CurrentVersion -replace '(.0.)[0-9]+\Z'
	$buildversion = (dir $buildstorage\$CurrentVersionShort* |sort -property LastWriteTime|select -last 1).name
	LogMessage "info" "Current installed version: $CurrentVersion"
	LogMessage "info" "New version: $buildversion"
	}


# Step 2d - Checking if all Input is received
#   Is server in environment.csv & if auto not set Was anything specified for buildversion?
if($environment -eq "none" -or $buildversion -eq "none" -or $environment -eq $null -or $buildversion -eq $null)
	{
	LogMessage "info"  "Display Usage:"
	LogMessage "info"  "Deployment environment or build version not specified. "
	LogMessage "info"  "you executed: script.ps1 $environment $buildversion"
	LogMessage "info"  "How to Run:";
	LogMessage "info"  "	Script_name.ps1 Project v1.0.0.2  -  this will deploy v1.0.0.2 build to Project environment."
	LogMessage "info"  "	list of all available environments in the config:"
	LogMessage "info"  " "
	LogMessage "info"  "To Generate config files w/o deployment, please execute: "
	LogMessage "info"  "             script.ps1 <environment> <buildversion> WebConfigOnly"
	
	
	foreach($i in $DefaultCSV){
		LogMessage "info" $i.environment
		}
	
	LogMessage "info" "list of 3 latest builds etc.."
	# "list of 3 latest builds for each version: 0.5, 0.6, 0.7, etc..";"";"";""
	# old code - dir $buildstorage|foreach{$_.name}; break
	# new functionality - compound variable, keep for reference.
	# $uniquevers= dir $buildstorage | %{$_.tostring() -replace '\.0\.\d*'}|select -unique
	# $uniquevers|%{dir $buildstorage\$_*|sort -property LastWriteTime|select -last 3}
	
	dir $buildstorage | %{$_.toString().Substring(0,4)} |select -unique | %{dir $buildstorage\$_*|sort -property LastWriteTime|select -last 3}
		break
	}else {
		LogMessage "info" "Executing script for Environment: $environment Build version: $buildversion"
	}

# Step 2e - Testing if specified environment value exists in environments.
if(-not($DefaultCSV | ? {$_.environment -eq $environment})){
	foreach($i in $DefaultCSV){$list+=$i.environment + " `n"}
	LogMessage "error" "Environment: $environment not found in $Defaultconfig. `n List of available environments. `n $list"
	break
		}ELSE{
	if(!(($DefaultCSV | ? {$_.environment -eq $environment}).ServersInEnvironment -match $env:computername)){
		LogMessage "warn" "Current server ($env:computername) not found in $environment `n Assuming user knows what they're doing... proceeding with deployment"
		}
	}

# Step 2f - Getting build location
LogMessage "info" "Getting build location"
if(!(test-path $buildstorage\$buildversion*)){
	LogMessage "error" "Path not found, please make sure $buildstorage\$buildversion exists"
	break
		}else{
		# work around against network hickups.
		$r=1..3;$r|foreach{
			LogMessage "info" "Searching for the latest build..."
			#Write "Searching for the latest build..."
			$buildpath = gci $buildstorage\$buildversion* | sort -property lastwritetime | select -last 1;start-sleep 1
		}
	LogMessage "info" "build path: $buildpath"
	$buildNum = $buildpath.name
	}


# Step 2g - Loading values for correct environment.
LogMessage "info" "Loading values for correct environment." 

$arrayposition=-1    
Foreach($i in $DefaultCSV){
	$arrayposition++
	if ($i.environment -eq $environment){
			$EnvironmentServers = $i.ServersInEnvironment.trim().split(";")
			$CustomerInteractionConnectionString = $i.CustomerInteractionConnectionString
			$CIDS_AppPoolUser = $i.CIDS_AppPoolUser
			$CIDS_AppPoolUserPassword = $i.CIDS_AppPoolPassword
			$IISCertificatePath = $i.IISCertificatePath
			$i.AppPoolUserPassword = '*********'
			LogMessage "info" "Environment $environment found, loading values: "
			break
		}
	}


##################################################
##### web.config generation 
if($Optional -eq "WebConfigOnly"){
	Logmessage "Warn" "Running in Webconfig Generation mode"
	Logmessage "Info" $("environment = " + $environment + " --  Buildversion = " + $buildversion)
	IF (!(TEST-PATH C:\CCT_Ops)){MD C:\CCT_Ops}
	
	$WebConfigModifiedFile      = "C:\CCT_Ops\web.config_$WebAppName_$environment_$buildversion.config"
	
	copy $buildpath\deliverables\CustomerInteractionDataService\web.config      $WebConfigModifiedFile
	
	ModifyConfigFiles $WebConfigModifiedFile
	
	Logmessage "Info" "Web.config is generated here:     $WebConfigModifiedFile"
	CloseLogFile
	break}
##################################################


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

# Step ## - Export Current Site/VDir/AppPool configuration to archive folder
BackupWebSiteConfiguration "$WebSiteName" "$webroot_archive\$WebAppName\$WebVDirName.$installTimeStamp"

# Step **- Stop WebAppPool if it already exists
if (test-path "IIS:\AppPools\$AppPoolName") { if ((Get-WebAppPoolState "$AppPoolName").Value -ne "Started") {Start-WebAppPool "$AppPoolName"} }

# Step ## - Backup previous version of application
if(test-path $webroot\$WebAppName\$WebVDirName){	
	robocopy $webroot\$WebAppName\$WebVDirName $webroot_archive\$WebAppName\$WebVDirName.$installTimeStamp *.* /E /NP /NS /NFL /NDL
	Remove-item $webroot\$WebAppName\$WebVDirName -recurse -force
	}else{
	
	# If folder doesn't exist, create it, create new VDIR and AppPool
	LogMessage "warn" "Creating new site at $webroot\$WebAppName\$WebVDirName"

	}

# Step ## - Remove and Create virtual directory - set apppool etc..
if (test-path "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName") { ri "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName" -recurse -force }
if (!(test-path "IIS:\Sites\$WebSiteName\$WebAppName\$WebVDirName")) {CreateSiteVdir $WebRoot $WebSiteName $WebAppName $WebVDirName $CIDS_AppPoolUser $CIDS_AppPoolUserPassword  }

# Step ## - Backup of Web.config & Verstion.txt
LogMessage "info" "Backup of Web.config & $versionTxt"

$VersionBack = "$webroot_archive\$WebAppName\$WebVDirName.$installTimeStamp\$VersionTxt"
$oldweb_config= "$webroot_archive\$WebAppName\$WebVDirName.$installTimeStamp\web.config"

# Step ## - Robocopy steps
$SourceDir= "$buildpath\deliverables\$WebAppName"
$DestDir= "$webroot\$WebAppName\$WebVDirName"
LogMessage "info" "robocopy $SourceDir $DestDir *.* /E"
robocopy $SourceDir $DestDir *.* /E /NP /NS /NFL /NDL

$folderlist="$logroot\$WebAppName"

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

# Do a diff on source and destination and raise an error if not in sync (exclude EndCall and Feedback dir)
LogMessage "info" "Diffing Source and Destination folders to ensure successful copy was performed"
$folders = get-childitem $SourceDir | ? {$_.PSIsContainer}
foreach($folder in $folders){
	LogMessage "info" "  Comparing folder: .\$folder" 
	#write-host "  Comparing folder: .\$folder" 
	$d1 = get-childitem -path "$SourceDir\$folder" -recurse
	$d2 = get-childitem -path "$DestDir\$folder"   -recurse
	$resultCompare = compare-object $d1 $d2 -PassThru
	if ($resultCompare) {
		LogMessage "warn" $("Source and Destination directories are not in sync:" + $folder)
		$notes += "`n`rSource and Destination directories are not in sync: $folder"}
		}

# Step 6b - setting User and version number in Version.txt
if (test-path $VersionBack) {
	LogMessage "info" "Getting old version number in $VersionBack"
	[string]$OldVersion=(gc $VersionBack) -match "\b[v]\d{1}\."
	$OldVersion=$OldVersion.substring(45,12).trim()
}

"<pre>"															| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt"
$buildpath														| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
[string]$currentuser=whoami
"You are looking at:  $env:computername" 						| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
"deployment executed by $currentuser on $installTimeStamp"	 	| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
"Build updated from $OldVersion to $buildnum"					| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
"Environment values used for this deployment:" 					| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
$DefaultCSV[$arrayposition]										| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append

# Step 6C - Creating History.txt file to keep track of ALL deployments ever done.
if (!(test-path "$webroot_archive\$WebAppName\$historyTxt")){"<pre>"				| out-file "$webroot_archive\$WebAppName\$historyTxt"}
"Build updated from $OldVersion to $buildnum by $currentuser `t on $installTimeStamp" | out-file "$webroot_archive\$WebAppName\$historyTxt" -append
copy "$webroot_archive\$WebAppName\$historyTxt" "$webroot\$WebAppName\$WebVDirName\$historyTxt"

# Execute Modify Config Files function define earlier.
. ModifyConfigFiles $webConfig

# STEP ## - CreateEventLogSource
..\..\bin\CreateEventLogSource.exe $AppPoolName

# STEP ## - Post deployment steps.

#Start App Pool
LogMessage "info" "Starting AppPool"
if ((Get-WebAppPoolState $AppPoolName).Value -ne "Started") {Start-WebAppPool $AppPoolName}

# Set Registry settings:
if (!(test-path "HKLM:\SOFTWARE\EXPSCOM\CCT\ReferenceIDService\WebServer")) { New-Item "HKLM:\SOFTWARE\EXPSCOM\CCT\ReferenceIDService\WebServer" -ItemType Directory -Force }


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
#Create Logroot share if not exist
if(!(Test-Path("\\$env:computername\logroot"))) { net share logroot=$logroot }

# Insert StopTime & Close the Log File
CloseLogFile 

# Post deployment tasks - mostly cosmetic and usability
# Displays logs for the whole deployment making it a little easier to pull up other servers from inside a log.
Write-Host "HTML Logs for the Deployment: "
$logHTML = getLogFilePathHtml
$EnvironmentServers | foreach {
	if($_ -eq $env:computername)
		{
			$attachment = $logHTML.Replace($logroot_install, "\\$_\logroot\install")
			($a =  "--->  " + $attachment)
			 $a			| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append
		} else {
			 ($a = "      " + $logHTML.Replace("$logroot_install\$env:computername", "\\$_\logroot\install\$_"))
			  $a		| out-file "$webroot\$WebAppName\$WebVDirName\$versionTxt" -append		
		}
	}

# getting web.config differences.
if (test-path $oldweb_config) {
	$diff_webconfig = compare-object -ReferenceObject $(gc $webconfig) -DifferenceObject $(gc $oldweb_config) -PassThru  -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
}

$oldVersionTxt_UNCPath = '\\' + $ServerName + '\webroot_archive\' + $WebAppName + '\' + $WebVDirName + "." + $installTimeStamp + '\' + $versionTxt
$oldWebConfig_UNCPath = '\\' + $ServerName + '\webroot_archive\' + $WebAppName + '\' + $WebVDirName + "."  + $installTimeStamp + '\web.config'

$newVersionTxt_UNCPath = '\\' + $ServerName + '\webroot\' + $WebAppName + '\' + $WebVDirName + '\' + $versionTxt
$newWebConfig_UNCPath = '\\' + $ServerName + '\webroot\' + $WebAppName + '\' + $WebVDirName + '\web.config'

$emailbody += 'New Version.txt: <a href="' + $newVersionTxt_UNCPath + '">' + $newVersionTxt_UNCPath + '</a><br>'
$emailbody += 'New web.config: <a href="' + $newWebConfig_UNCPath + '">' + $newWebConfig_UNCPath + '</a><br>'

$emailbody += 'Old Version.txt: <a href="' + $oldVersionTxt_UNCPath + '">' + $oldVersionTxt_UNCPath + '</a><br>'
$emailbody += 'Old web.config: <a href="' + $oldWebConfig_UNCPath + '">' + $oldWebConfig_UNCPath + '</a><br>'


$emailbody += "Differences (if any) between New web.config and one stored as backup: "
$diff_webconfig | foreach {$emailbody += "$_ <br>"}
$notes | foreach {$emailbody += "$_ <br>"}
#amail "$env:username@expedia.com" $("$env:username@expedia.com","cctrel@expedia.com") "Deployment on $environment - $env:computername finished successfully"  $emailbody -attachment $attachment
amail "cctrel@expedia.com" $("mcraig@expedia.com"; "$env:username@expedia.com") "$WebAppName\$WebVDirName - Deployment on $environment environment - $env:computername finished successfully"  $emailbody -attachment $attachment

# Verify that Extended HTTPErr attributes are being logged
if ((get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters").ErrorLoggingFields -eq $null){
	EnableExtendedHTTPErrAttributes
	RebootRequired("True")
}