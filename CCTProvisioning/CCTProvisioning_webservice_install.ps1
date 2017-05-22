# Upgrade only script.
# version 2.7


param([string]$environment="none",[string]$buildversion="none",$Optional,$webroot="c:\inetpub\wwwroot\CCTProvisioningService",[DateTime]$StartTime = "1/1/1990")

# Import common functions
ImportSystemModules
Import-Module ..\lib\Functions_common.psm1 -verbose -Force

if($StartTime="1/1/1990"){$StartTime=getStartTime}
#variables:
$appname			= "CCTProvisioningService"
$BuildLabel			= $appname + "_" + $buildversion
if ($logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path) { $logroot }else{$logroot="d:\logroot"}
$logroot_install	="$logroot\install"
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"
$defaultconfig		="environments.csv"
$ServerName			="$env:ComputerName"
$webroot_backup	    ="d:\webroot_archive"
$webConfig			="$webroot\web.config"
$AppPoolName		=$appname

$DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain
#Setting build location and username based on domain where box is located.

#ph.expeso.com 
#ch.expeso.com

#Start Logging
CreateLogFilePath "$BuildLabel" "$ServerName" "$Environment" "$logroot_install"

Test-Administrator
	
If($DnsDomain -match "cct.expecn.com"){
	# CCT Production Settings: Both Chandler and Phoenix can access this share
		$buildstorage		= "\\che-filidx.idx.expedmz.com\Release\sait\CRM\modules\$appname"
	
	$versionTxt			="version.txt.config"
	$historyTxt			="History.txt.config"
	}Else{
	
	# CCTLab Settings
	
	## For Now manually copy the build to \\chclappadfs02\d$\binroot until the firewal is opened to allow access to \\karmalab.net\builds
	#$buildstorage		= "\\karmalab.net\builds\directedbuilds\sait\CRM\modules\$appname"			# Test

	$buildstorage		= "\\chclappadfs02\d$\binroot\$appname"
	$versionTxt			="version.txt"
	$historyTxt			="History.txt"
}

LogMessage "info"  "environment: $environment"
LogMessage "info"  "buildversion: $buildversion"
LogMessage "info"  "Optional: $Optional"

LogMessage "info" "Begin Logging"
LogMessage "info" "AppName: $appname"
LogMessage "info" "BuildLabel: $BuildLabel"
LogMessage "info"  "Based on $DnsDomain - Setting buildstorage to $buildstorage"
LogMessage "info" "envusername: $envusername"
LogMessage "info" "webroot: $webroot"
LogMessage "info" "webroot_backup: $webroot_backup"
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

	#$doc.SelectSingleNode("//client/endpoint").address = $ProvisioningEndpoint
	
	
	## Modify CCTProvisioningThumbprint
	LogMessage "info" "Setting CCTProvisioningThumbprint"
	$doc.SelectSingleNode("//serviceCredentials/serviceCertificate").findValue=$CCTProvisioningThumbprint
	
	## Set RollCallDBConnectionString
	LogMessage "info" "Setting RollCallDBConnectionString"
	$doc.SelectSingleNode("//configuration/appSettings/add[@key='ReadConnectionString']").value=$RollCallDBConnectionString
	$doc.SelectSingleNode("//configuration/appSettings/add[@key='WriteConnectionString']").value=$RollCallDBConnectionString
	
	## Modify log file path
	LogMessage "info" "Setting Log4Net log path"
	$doc.SelectSingleNode("//appender[@name='RollingLogFileAppender']/file").value=$logroot + "\" + $appName + "\" + $appName + ".txt"
	
	## Set baseOU of ActiveDirectory
	LogMessage "info" "Setting baseOU"
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='baseOU']").value = $baseOU

	## Set CreateUserBaseOU of ActiveDirectory
	LogMessage "info" "Setting baseOU"
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='CreateUserBaseOU']").value = $CreateUserBaseOU
	
	$doc.Save($webConfig)

}


# STEP 1 - Environment setup.
LogMessage "info" "Begin Environment Setup"


# Step 1b - Is execution policy set to restricted? Attempt to set 
Set-ExecutionPolicyUnrestricted


# Step 1c - load system modules
LoadAllModules


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
	$environment=($DefaultCSV | ? {$_.Servers_in_Environment.split(";") -eq $env:computername}).environment
	LogMessage "info" "Environment is: $environment"
	}

	
# Step 2c - If enabled - Auto determining latest build based on currently deployed build.
if($Optional -eq "auto"){
	LogMessage "info" "Auto Deployment selected. Auto determining build to install."
	#Determining version number from $versionTxt.config
	[string]$CurrentVersion=(gc $webroot\$versionTxt) -match "\b[v]\d{1}\."
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
	
	dir $buildstorage | %{$_.tostring() -replace '\.0\.\d*'}|select -unique | %{dir $buildstorage\$_*|sort -property LastWriteTime|select -last 3}
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
	if(!(($DefaultCSV | ? {$_.environment -eq $environment}).servers_in_environment -match $env:computername)){
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
			
			$EnvironmentServers = $i.Servers_in_Environment.trim().split(";")
			$webroot = $i.WebRootFolder
			$RollCallDBConnectionString = $i.RollCallDBConnectionString
			$CCTProvisioningThumbprint = $i.CCTProvisioningThumbprint
			$BaseOU = $i.BaseOU
			$CreateUserBaseOU = $i.CreateUserBaseOU
			LogMessage "info" "Environment $environment found, loading values: "
			break
		}
	}


#temporary safety net
#if (!(test-path $webroot)){LogMessage "error" "$webroot Not found"}


# if ($iisPfxcertpass -match '\A\\\\.*\\.*'){
	# #testing path to password file
	# if(test-path -path $matches){
		# $passwordfile=Import-Csv .\$matches | where {$_.environment -eq $environment}
		# $iisPfxcertpass = $passwordfile.$iisPfxcertpass
	# }else{
		# LogMessage "Warn" $("Script expect " + $matches +" to be a file and be accessible")
	# }
# }



##################################################
##### web.config generation 
if($Optional -eq "WebConfigOnly"){
	Logmessage "Warn" "Running in Webconfig Generation mode"
	Logmessage "Info" $("environment = " + $environment + " --  Buildversion = " + $buildversion)
	IF (!(TEST-PATH C:\CCT_Ops)){MD C:\CCT_Ops}
	
	$WebConfigModifiedFile      = "C:\CCT_Ops\web.config_" + $appname + "_" + $environment + "_" + $buildversion + ".config"
	
	copy $buildpath\deliverables\_PublishedWebsites\CCTProvisioningService\web.config      $WebConfigModifiedFile
	
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
LogMessage "info" "Deploying $appname"
LogMessage "info" "Stopping $appname website "
#accomodating multi instance deployment
if($webroot -ne "c:\inetpub\wwwroot\CCTProvisioningService"){$multisitepath=$webroot.replace("c:\","");Stop-Website $multisitepath
	}else{
	Stop-Website "Default Web Site"


	Stop-WebAppPool $AppPoolName
	}


# Delete webroot Share to prevent open handles
LogMessage "info" "deleting app share - prevents open handles"
if(test-path \\$env:computername\webroot){net share webroot /d /y 2>&1 | Out-Null}
if (!$?){
	LogMessage "info" "Webroot could not be deleted. Trying $webroot.."
	net share webroot /d /y}else{
		LogMessage "info" "$webroot deleted"
		}

# Step 5 - Backup of Web.config & Verstion.txt
LogMessage "info" "Backup of Web.config & $versionTxt"

if(!(test-path $webroot_backup)){md $webroot_backup}
	
# STEP x  - Back up current folder to webroot_backup location

if(test-path $webroot){	
	robocopy $webroot $webroot_backup\$appName.$installTimeStamp *.* /E /NP /NS /NFL /NDL
	Remove-item $webroot -recurse -force
	}else{LogMessage "warn" "Copy $webroot to $webroot_backup\$appName_$installTimeStamp didnt succeed"}

$VersionBack = "$webroot_backup\$appName.$installTimeStamp\$VersionTxt"
$oldweb_config= "$webroot_backup\$appName.$installTimeStamp\web.config"

# STEP 4 - Create App folders
LogMessage "info" "Creating App Folders and Granting permissions"

# Step 6a - Robocopy steps
LogMessage "info" "Starting ROBOCOPY"
$SourceDir= "$buildpath\deliverables\_PublishedWebsites\CCTProvisioningService"
$DestDir= "$webroot"

#new way of copying
LogMessage "info" "robocopy $SourceDir $DestDir *.* /E"
robocopy $SourceDir $DestDir *.* /E /NP /NS /NFL /NDL


$folderlist="$webroot", "$logroot\$appName"


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
LogMessage "info" "setting User and version number in $versionTxt"
[string]$OldVersion=(gc $VersionBack) -match "\b[v]\d{1}\."
$OldVersion=$OldVersion.substring(45,12).trim()

"<pre>"															| out-file "$webroot\$versionTxt"
$buildpath														| out-file "$webroot\$versionTxt" -append
[string]$currentuser=whoami
"You are looking at:  $env:computername" 						| out-file "$webroot\$versionTxt" -append
"deployment executed by $currentuser on $installTimeStamp"	 	| out-file "$webroot\$versionTxt" -append
"Build updated from $OldVersion to $buildnum"					| out-file "$webroot\$versionTxt" -append
"Environment values used for this deployment:" 					| out-file "$webroot\$versionTxt" -append
$DefaultCSV[$arrayposition]										| out-file "$webroot\$versionTxt" -append

# Step 6C - Creating History.txt file to keep track of ALL deployments ever done.
if (!(test-path "$webroot_backup\$historyTxt")){"<pre>"				| out-file "$webroot_backup\$historyTxt"}
"Build updated from $OldVersion to $buildnum by $currentuser on $installTimeStamp" | out-file "$webroot_backup\$historyTxt" -append
Copy-item "$webroot_backup\$historyTxt" "$webroot\$historyTxt"


# Execute Modify Config Files function define earlier.
. ModifyConfigFiles $webConfig



# STEP 8 - Post deployment steps.
		
LogMessage "info" "Restarting W3SVC"
restart-service w3svc
LogMessage "info" "Starting Default Web Site"
if($multisitepath -ne $null){Start-Website $multisitepath}Else{Start-Website "Default Web Site"}
LogMessage "info" "Starting AppPool"
if ((Get-WebAppPoolState $AppPoolName).Value -ne "Started") {Start-WebAppPool $AppPoolName}


#Recreating Webroot share
LogMessage "info" "Recreating Webroot share"
$webRootShare = Split-Path -parent $webroot
if(!(test-path $webroot)){	
	net share webroot=$webRootShare
}
if(!(test-path $webroot_backup)){	
	net share webroot_backup=$webroot_backup
}


#Create Logroot share if not exist
if(!(Test-Path("\\$env:computername\logroot"))) { net share logroot=$logroot }


# Return to executing folder
popd

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
			 $a			| out-file "$webroot\$versionTxt" -append
		} else {
			 ($a = "      " + $logHTML.Replace("$logroot_install\$env:computername", "\\$_\logroot\install\$_"))
			  $a		| out-file "$webroot\$versionTxt" -append		
		}
	}

# getting web.config differences.
$diff_webconfig = compare-object -ReferenceObject $(gc $webconfig) -DifferenceObject $(gc $oldweb_config) -PassThru  -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue

LogMessage "info"   "                 *********************************"
LogMessage "info"   " Build updated from $OldVersion to $buildNum"
LogMessage "info"   " Setup Complete, please scroll up and Examine output for errors."
LogMessage "info"   " notes if any: "
LogMessage "info"   " $notes "
LogMessage "info"   "                 *********************************"
LogMessage "info"   "                  THIS Server: $env:computername  "

#Sending email to person who ran deployment.
$VersionBackSharePath   = "\\$env:computername" +  ".$env:USERDNSDOMAIN" + "\webroot_backup\$appName.$installTimeStamp\$VersionTxt"
$oldweb_configSharePath = "\\$env:computername" +  ".$env:USERDNSDOMAIN" + "\webroot_backup\$appName.$installTimeStamp\web.config"

$emailbody = MailBodyADFS

$emailbody += 'Old Version.txt: <a href="' + $VersionBackSharePath + '"))">' + $VersionBackSharePath + '</a><br>"'
$emailbody += 'Old web.config: <a href="' + $oldweb_configSharePath + '">' + $oldweb_configSharePath + '</a><br>"'

$emailbody += "Differences (if any) between New web.config and one stored as backup: "
$diff_webconfig | foreach {$emailbody += "$_ <br>"}
$notes | foreach {$emailbody += "$_ <br>"}
#amail "$env:username@expedia.com" $("$env:username@expedia.com","cctrel@expedia.com") "Deployment on $environment - $env:computername finished successfully"  $emailbody -attachment $attachment
amail "$env:username@expedia.com" $("$env:username@expedia.com") "Deployment on $environment - $env:computername finished successfully"  $emailbody -attachment $attachment
