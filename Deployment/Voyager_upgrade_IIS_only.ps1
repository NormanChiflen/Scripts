## Voyager Upgrade only script.
## version 2.9
## build to be executed from: \\chelappsbx001\deploymentautomation_dogfood\Voyager_IIS\Deployment


param([string]$environment="none",[string]$buildversion="none",$Optional,$ngatsharein,[DateTime]$StartTime)

# Import common functions
Import-Module ..\..\lib\Functions_common.psm1 -verbose -Force

# Allowing Self Deploy App to pass in start time
## broken - investigation slated for later - never worked 
## if(!(test-path environment:StartTime)){setStartTime $StartTime }

#variables:
$appname			= "VoyagerUI"
$BuildLabel			= "$appname_$buildversion"
# $ngatshare			= "E:\NGAT"		#moving into input
if ($logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path) { $logroot }else{$logroot="d:\logroot"}
$logroot_install	="$logroot\install"
$log_appEventLogs   ="$logroot\EventLogs\Application"
# This path is used to make sure the folder is created. Log4Net requires this format when setting value in web.config (d:\\logroot\\Voyager\\logfile)
$log_voyager_appLogs="$logroot\voyager"
# Capturing the current path for future consumption
$scriptexecutedfrom	=$pwd
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"
$defaultconfig		="environments.csv"
$ServerName			= "$env:ComputerName"
$DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain
## Adding functionality to deploy to Production environments using STATIC files.
$ProdEnvironment = ("prod", "iso-prod", "dr")

if (!(Test-Path $log_voyager_appLogs)) {md $log_voyager_appLogs }


#Setting build location and username based on domain where box is located.
# Removing logs older than specified time.
If($DnsDomain -match "ph.expeso.com"){
	$buildstorage		= "\\phc-filidx\cctss\Voyager\Web_UI"									# prod
	$envusername		= "expeso\_voyager"														# prod

	#Preliminary clean up to make sure CreateLogFilePath has enough space to run.
	Write-host "Removing files older than 5 days from $log_voyager_appLogs"
	foreach ($i in Get-Childitem $log_voyager_appLogs -Recurse | Where {$_.LastWriteTime -le (get-date).AddDays(-5)} ) {
		"removing " + $i.fullname
		ri $i.FullName -Force}

}ElseIf($DnsDomain -match "ch.expeso.com"){
	$buildstorage		= "\\chc-filidx\cctss\Voyager\Web_UI"									# prod
	$envusername		= "expeso\_voyager"														# prod

	#Preliminary clean up to make sure CreateLogFilePath has enough space to run.
	Write-host "Removing files older than 5 days from $log_voyager_appLogs"
	foreach ($i in Get-Childitem $log_voyager_appLogs -Recurse | Where {$_.LastWriteTime -le (get-date).AddDays(-5)} ) {
		"removing " + $i.fullname
		ri $i.FullName -Force}

}Else{
	#$buildstorage		= "\\karmalab.net\builds\directedbuilds\sait\CRM\products\ngat"			# Test
	$buildstorage		= "\\chlxfilklb001\DirectedBuilds\sait\CRM\products\ngat"			# alternative
	$ToolsStorage		= "\\CHELWEBE2ECCT34\localbin"
	$envusername		="karmalab\_crmdev","everyone"											# Test

	#Preliminary clean up to make sure CreateLogFilePath has enough space to run.
	Write-host "Removing files older than 1 days from $logroot\voyager"
	foreach ($i in Get-Childitem $logroot\voyager -Recurse -include *.* | Where {$_.LastWriteTime -le (get-date).AddDays(-1)} ) {
		"removing " + $i.fullname
		ri $i.FullName -Force}
	}




#Start Logging
CreateLogFilePath "$BuildLabel" "$ServerName" "$Environment" "$logroot_install"

LogMessage "info"  "environment: $environment"
LogMessage "info"  "buildversion: $buildversion"
LogMessage "info"  "Optional: $Optional"

LogMessage "info" "Begin Logging"
LogMessage "info" "AppName: $appname"
LogMessage "info" "BuildLabel: $BuildLabel"
LogMessage "info"  "Based on $DnsDomain - Setting buildstorage to $buildstorage"
LogMessage "info" "envusername: $envusername"
LogMessage "info" "ngatshare: $ngatshare"
LogMessage "info" "ngatbackup: $ngatbackup"
LogMessage "info" "logroot: $logroot"
LogMessage "info" "logroot_install: $logroot_install"
LogMessage "info" "scriptexecutedfrom: $scriptexecutedfrom"
LogMessage "info" "installTimeStamp: $installTimeStamp"
LogMessage "info" "defaultconfig: $defaultconfig"
LogMessage "info" "ServerName: $ServerName"


##
## Commented out 12/17/2012 - This was never requested to go to production ##
##
## Set registry keys if domain is not Production environment
#If($DnsDomain -match ".expeso.com"){
		###
		
#		}Else{
		
		# Edit Reg keys to set TCP/IP  IIS thread pooling: as per feedback from Helen and Karl Armani 6/20/2012
#		LogMessage "info" 'Setting  HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name TcpTimedWaitDelay  -Value 30'
#		Set-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name TcpTimedWaitDelay -Value 30

#		LogMessage "info" 'Setting  HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name KeepAliveTime   -Value 30000'
#		Set-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name KeepAliveTime -Value 30000
		
#	}




# Loading Configuration function here. This will allow us to generate Config file without running deployment.
# None of of the stuff below is executed until the function is called
# ### To make sure nothing breaks, the function should be 'dot sourced' to expose variables to the rest of the script.

Function ModifyConfigFiles ($webconfig, $FeedbackConfigFile, $voyagerUIconfig) {
	############################################
	# STEP 7 - Change web.config, version.txt and Feedback.config and we're done.

	# Step 7a - Modifying web.config via String replace to enable commented out section
	LogMessage "info" "Modifying web.config via String replace to enable commented out section"
	#uncommenting dev comments - should be active to work anywhere outside of dev environment
	LogMessage "info" "uncommenting dev comments - should be active to work anywhere outside of dev environment"
	$stringreplace = gc $webConfig

	function ReplaceString($workingVar,$StringMatch,$StringNew){
		foreach($i in $workingVar){
			$i.replace($StringMatch,$StringNew)
			##LogMessage "info" "replaced: $StringMatch with $StringNew "
			}
		}

	## 333 Removing commented out lines 
	#LogMessage "info" 	'deleting <sessionState mode="InProc" cookieless="false" timeout="120" />'
	#$stringreplace=ReplaceString $stringreplace '<sessionState mode="InProc" cookieless="false" timeout="120" />' ""
	
	#updating to XML parsing logic below @ web.config line #321
	
	#LogMessage "info" 'uncommenting <!--<sessionState mode="Custom" cookieless="false" timeout="120" customProvider="AppFabricCacheSessionStoreProvider">'
	#$stringreplace=ReplaceString $stringreplace '<!--<sessionState mode="Custom" cookieless="false" timeout="120" customProvider="AppFabricCacheSessionStoreProvider">' '<sessionState mode="Custom" cookieless="false" timeout="120" customProvider="AppFabricCacheSessionStoreProvider">'
	#LogMessage "info" 'uncommenting </sessionState>-->' 
	#$stringreplace=ReplaceString $stringreplace '</sessionState>-->' '</sessionState>'
	#LogMessage "info" "Saving to $webConfig"
	#$stringreplace | Set-Content $webConfig

	
	# Step 7b - Modifying web.config via XML
	LogMessage "info" "Modifying web.config via XML" 
	$doc = new-object System.Xml.XmlDocument
	$doc.Load($webConfig)

	## 29 - Adding AppFabric host servers
	LogMessage "info" "Adding AppFabric host servers"
	$hosts = $doc.DocumentElement.dataCacheClient.hosts
	$hosts.RemoveAll()
	$App_Fabric_Hosts | foreach {
		#Write-host -f green $_
		$newHost = $doc.CreateElement("host")
		$newhost.SetAttribute("name", $_)
		$newhost.SetAttribute("cachePort", 22233)
		$out=$hosts.AppendChild($newHost)
		LogMessage "info" "Append AppFabricHostNode for: $_,22233"
		}
		

	## 42 - Set Log4Net log path
	#  need to append \logfile to path, Log4Net uses 'logfile' as a placeholder for the actual log file name
	LogMessage "info" "Setting Log4Net path to $logroot"
	$log_voyager_appLogs="$log_voyager_appLogs\logfile"
	$doc.SelectSingleNode("/configuration/log4net/appender['WebLogFileAppender']/param[@name='File']").value = $log_voyager_appLogs.Replace('\', '\\')

	# Set Logging Level
	LogMessage "info" "Setting Log4Net Log Level to $LogAppenderLevel"
	
	#This node is gone from Voyager 2.3 and onward code
	$doc.SelectSingleNode("/configuration/log4net/logger[@name='WebLogger']/level") | where {$_.value -ne $null} | foreach {$_.value = $LogAppenderLevel}
	$doc.SelectSingleNode("/configuration/log4net/logger[@name='ServiceLogger']/level") | where {$_.value -ne $null} | foreach {$_.value = $LogAppenderLevel}
	$doc.SelectSingleNode("/configuration/log4net/logger[@name='Combres']/level") | where {$_.value -ne $null} | foreach {$_.value = $LogAppenderLevel}





	## 78 Modify Expedia.ContactCenter.NGAT.Web.Properties.Settings for VOY (not VOYSTB)
	## New Value Expedia.ContactCenter.Voyager.AppFabricCaching. AppFabricCache, Expedia.ContactCenter.Voyager.AppFabricCaching 
	if($NGAT_Web_Properties_Settings -ne "default"){
	$doc.Selectsinglenode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='WebCacheImplementation']").value=$NGAT_Web_Properties_Settings
	}

	## 236 Modify Expedia.ContactCenter.Voyager.BusinessLayer.Properties.Settings for VOY (not VOYSTB)
	if($Voyager_BusinessLayer_Properties_Settings -ne "default"){
	$doc.Selectsinglenode("/configuration/applicationSettings/Expedia.ContactCenter.Voyager.BusinessLayer.Properties.Settings/setting[@name='BizCacheImplementation']").value=$Voyager_BusinessLayer_Properties_Settings
	## New Value Expedia.ContactCenter.Voyager.AppFabricCaching. AppFabricCache, Expedia.ContactCenter.Voyager.AppFabricCaching 
	}


	# If production, training, isoprod, disable WebLogFileAppender by setting appender-ref to blank
	If($DnsDomain -match ".expeso.com"){
		$doc.SelectSingleNode("/configuration/log4net/logger[@name='ServiceLogger']/appender-ref[@ref='WebLogFileAppender']").ref=""
	}

	
	## 91 - Setting Expedia Suggest URLs  - Old web.config prior to 2.3
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='ExpediaSuggestBaseURL']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" $("setting " + $_.contract + " to " + $ExpediaSuggestBaseURL)
		$_.value = $_.value -replace '\w*\:.*?\.com', $ExpediaSuggestBaseURL
		}
	
	## 91 - Setting Expedia Suggest URLs  - New Web.config for Voyager 2.3 and beyond.
		$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='ExpediaSuggestBaseUrl']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" $("setting " + $_.contract + " to " + $ExpediaSuggestBaseURL)
		$_.value = $_.value -replace '\w*\:.*?\.com', $ExpediaSuggestBaseURL
		}
		



	## 92 - Setting Expedia Suggest URLs - Old web.config only - gone in 2.3 and beyond.
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='ExpediaSuggestPropertySearchBaseURL']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" $("setting " + $_.contract + " to " + $ExpediaSuggestBaseURL)
		$_.value = $_.value -replace '\w*\:.*?\.com', $ExpediaSuggestBaseURL
		}




	## 93 - Setting Navigator URL for AppSettings  - Old web.config prior to 2.3
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='NavigatorURL']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" $("setting " + $_.key + " to " + $Navigator_UI_URL)
		$_.value = $_.value -replace '\w*\:.*?prweb', $Navigator_UI_URL
		}

	## 94 - Setting Navigator URL for AppSettings  - New Web.config for Voyager 2.3 and beyond.
		$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='NavigatorUrl']") | where {$_.value -ne $null} | foreach {
		#LogMessage "info" "NEW Webconfig Update"
		#LogMessage "info" $("setting " + $_.contract + " to " + $Navigator_UI_URL)
		$_.value = $_.value -replace '\w*\:.*?prweb', $Navigator_UI_URL
		}




	## 94 - Setting PseudoLoc Property  - Old web.config prior to 2.3
	if($PseudoLoc -ne "default"){$doc.SelectSingleNode("/configuration/appSettings/add[@key='PseudoLoc']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "PseudoLoc = $PseudoLoc"
		$_.value = $PseudoLoc
		}
	}

	## 100 - Setting PseudoLoc Property  - New Web.config for Voyager 2.3 and beyond.
	if($PseudoLoc -ne "default"){$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='PseudoLoc']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "PseudoLoc = $PseudoLoc"
		$_.value = $PseudoLoc
		}
	}




	## 98  - Setting Federation URL Property  - Old web.config prior to 2.3
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='FederationMetadataLocation']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "FederationMetadataLocation = $tokenproviderURL"
		$_.value = $tokenproviderURL
		}

	## 112 - Setting Federation URL Property
	## should not be in a new web.config - keeping temporary - should be removed by March 2013.
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='FederationMetadataLocation']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "FederationMetadataLocation = $tokenproviderURL"
		$_.value = $tokenproviderURL
	}




	## 117 - Setting Cert Name that website uses to find SSL Cert - should go away soon.  - Old web.config prior to 2.3
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='EncryptingCertificateSubject']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "EncryptingCertificateSubject = $IISCertName"
		$_.value = $IISCertName
	}

	## 169 - Setting Cert Name that website uses to find SSL Cert - should go away soon.  - New Web.config for Voyager 2.3 and beyond.
	## should not be in a new web.config - keeping temporary - should be removed by March 2013.
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='EncryptingCertificateSubject']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "EncryptingCertificateSubject = $IISCertName"
		$_.value = $IISCertName
	}




	## 118 - Setting Cert Thumb that website uses to find SSL Cert
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='EncryptingCertificateThumbprint']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "EncryptingCertificateThumbprint = IISCertThumb"
		$_.value = $IISCertThumb
	}

	## 169 - Setting Cert Name that website uses to find SSL Cert - should go away soon.  - New Web.config for Voyager 2.3 and beyond.
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='EncryptingCertificateThumbprint']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "EncryptingCertificateThumbprint = IISCertThumb"
		$_.value = $IISCertThumb
	}




	## 124 - Setting Omniture Tagging
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='OmnitureTagging_EnvironmentValue']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "applying OmnitureTagging_EnvironmentValue: $OmnitureTagging "
		$_.value = $OmnitureTagging
	}

	## 184 - Setting Omniture Tagging
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='OmnitureTagging_EnvironmentValue']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "applying OmnitureTagging_EnvironmentValue: $OmnitureTagging "
		$_.value = $OmnitureTagging
	}




	## 131 - Modifying SMTP server
	LogMessage "info" "setting SMTP server to $SMTP"
	$doc.SelectSingleNode("/configuration/appSettings/add[@key='feedbackSmtpServer']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "OLD Webconfig Update"
		LogMessage "info" "applying OmnitureTagging_EnvironmentValue: $OmnitureTagging "
		$_.value = $SMTP
	}

	## 205 - Modifying SMTP server
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='FeedbackSmtpServer']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "NEW Webconfig Update"
		LogMessage "info" "applying OmnitureTagging_EnvironmentValue: $OmnitureTagging "
		$_.value = $SMTP
	}



	## 190 - Setting EnableJsAndCssOptimization to True (per Brennan)
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='EnableJsAndCssOptimization']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "Setting EnableJsAndCssOptimization to True "
		$_.value = "True"
	}

	## 205 - Setting EnableHtmlOptimization to True (per Brennan)
	$doc.SelectSingleNode("/configuration/applicationSettings/Expedia.ContactCenter.NGAT.Web.Properties.Settings/setting[@name='EnableHtmlOptimization']") | where {$_.value -ne $null} | foreach {
		LogMessage "info" "Setting EnableHtmlOptimization to True"
		$_.value = "True"
	}



	############ Adding App Fabric stuff from above
	## 322 - Modifying App Fabric setting. Changing mode to Custom to enable AppFabric for Lab.
	$doc.SelectSingleNode("/configuration/system.web/sessionState").mode = "Custom"
	if (!$?){throw}
	$doc.SelectSingleNode("/configuration/system.web/sessionState").setattribute("customProvider","AppFabricCacheSessionStoreProvider")
	if (!$?){throw}
	
	## 324 - Setting App Fabric Cache name
	LogMessage "info" "App Fabric Cache name=$App_Fabric_Cache"
	$doc.get_DocumentElement()."system.web".sessionState.providers.add.cacheName = $App_Fabric_Cache
	if (!$?){throw}


	
	## 192 - matching prod
	LogMessage "info" "applying Compilation Debug = False "
	$doc.get_documentelement()."system.web".compilation.debug = "False"


	## Support N number of Endpoints, replace the root portion of the URL with the 'base' portion listed in environments.csv
	## 325- Setting services endpoints - Same Base URL for both services, per dev.
	$n=$doc.SelectNodes("/configuration/system.serviceModel/client/endpoint")
	$n | where {$_.bindingConfiguration -like "lodgingSupplyBinding" -or `
				$_.bindingConfiguration -like "lodgingSupplyHttpsBinding" -or `
				$_.bindingConfiguration -like "voyagerRefDataBinding" -or `
				$_.bindingConfiguration -like "voyagerRefDataHttpsBinding"}| `
		foreach {
			LogMessage "info" $("setting " + $_.address + " to " + $ServiceEndpointURL)
		## regex explained - \http or https \: ungreedy * until next : \ 4 or more numbers
		## -old regex $_.address = $_.address -replace '\w*\:.*?\:[0-9]{4,}', $ServiceEndpointURL
		## regex explained - \http or https \: ungreedy * look ahead but not include next /
		## New regex with lookahead
			$_.address = $_.address -replace '\w*\://.*?(?=/)', $ServiceEndpointURL
		}


	## Setting Endpoint binding to SSL
		$n | where {$_.bindingConfiguration -like "lodgingSupplyBinding" }| `
		foreach {
			LogMessage "info" $("setting " + $_.bindingConfiguration + " to lodgingSupplyHttpsBinding")
			$_.bindingConfiguration = "lodgingSupplyHttpsBinding"
		}

	## Setting Endpoint binding to SSL
		$n | where {$_.bindingConfiguration -like "voyagerRefDataBinding"}| `
		foreach {
			LogMessage "info" $("setting " + $_.bindingConfiguration + " to voyagerRefDataHttpsBinding")
			$_.bindingConfiguration = "voyagerRefDataHttpsBinding"
		}





## START temporary wrapper to excluse training HTTPS switch (for John beaver since training does not support HTTPS)
$TrainingHTTPSExclusionEnvironment = "TRN-DEV-01","TRN-DEV-02","TRN-DEV-03","TRN-DEV-04","TRN-DEV-STABLE01","TRN-DEV-STABLE02","TRN-DEV-STABLE03","TRN-DEV-STABLE04","QA-Perf"

if ($TrainingHTTPSExclusionEnvironment -match $environment){
	## Setting Endpoint binding back to HTTP
		$n | where {$_.bindingConfiguration -like "lodgingSupplyHttpsBinding" }| `
		foreach {
			LogMessage "info" $("setting " + $_.bindingConfiguration + " to lodgingSupplyBinding")
			$_.bindingConfiguration = "lodgingSupplyBinding"
		}

	## Setting Endpoint binding to SSL
		$n | where {$_.bindingConfiguration -like "voyagerRefDataHttpsBinding"}| `
		foreach {
			LogMessage "info" $("setting " + $_.bindingConfiguration + " to voyagerRefDataBinding")
			$_.bindingConfiguration = "voyagerRefDataBinding"
		}
	}
## END of temporary wrapper to excluse training HTTPS switch







		## 329 - Setting Navigator / Autodoc URL - Same Base URL for both services, per dev.
		#	code for setting values individually
		# $AutodocEIN=$doc.configuration."system.servicemodel".client.endpoint | where {$_.name -eq "Enterprise-Interface-NavDataTablesPort"}
		# $AutodocEIN.address=$AutodocURL
		# $AutodocSP=$doc.configuration."system.servicemodel".client.endpoint | where {$_.name -eq "ServicesPort"}
		# $AutodocSP.address=$AutodocURL
	$n | where {$_.contract -eq "DocumentationService.ServicesType" -or $_.contract -eq "ComplaintMatrixService.EnterpriseInterfaceNavDataTablesType"} | 
		foreach {
			LogMessage "info" $("setting " + $_.contract + " to " + $AutodocURL)
			$_.address = $AutodocURL
			$_.bindingConfiguration = $Nav_binding}


	## 384 - Setting Token provider URL   - Old web.config prior to 2.3
	$doc.get_DocumentElement()."microsoft.identityModel".service.federatedAuthentication.wsfederation  | where {$_.issuer -ne $null} | foreach {
	LogMessage "info" "wsfederation.issuer = $ADFSUrl"
	$_.issuer = $ADFSUrl}

	## 513 - Setting Token provider URL  - New Web.config for Voyager 2.3 and beyond.
	$doc.configuration."system.identityModel.services".federationConfiguration.wsfederation  | where {$_.issuer -ne $null} | foreach {
	LogMessage "info" "wsfederation.issuer = $ADFSUrl"
	$_.issuer = $ADFSUrl}




	## 387 - Setting Token Provider SSL Cert Thumbprint    - Old web.config prior to 2.3
	$doc.get_DocumentElement()."microsoft.identityModel".service.issuerNameRegistry.trustedissuers.add  | where {$_.thumbprint -ne $null} | foreach {
	LogMessage "info" "SSL thumbprint = $SSLThumbprint"
	$_.thumbprint = $SSLThumbprint}

	## 500 - Setting Token provider URL  - New Web.config for Voyager 2.3 and beyond.
	$doc.configuration."system.identityModel".identityConfiguration.issuerNameRegistry.trustedissuers.add  | where {$_.thumbprint -ne $null} | foreach {
	LogMessage "info" "SSL thumbprint = $SSLThumbprint"
	$_.name = $SSLThumbprint}




	## 387 - Setting Token Provider Trust URL - Is this used?
	$doc.get_DocumentElement()."microsoft.identityModel".service.issuerNameRegistry.trustedissuers.add | where {$_.name -ne $null} | foreach {
	LogMessage "info" "Trustedissuers = $TrustURL"
	$_.name = $TrustURL}

	## 500 - Setting Token Provider Trust URL  - New Web.config for Voyager 2.3 and beyond.
	$doc.configuration."system.identityModel".identityConfiguration.issuerNameRegistry.trustedissuers.add  | where {$_.name -ne $null} | foreach {
	LogMessage "info" "SSL thumbprint = $SSLThumbprint"
	$_.name = $TrustURL}


	$doc.Save($webConfig)
	LogMessage "info" "Web.config saved with Modifications"


	# STEP 7c - Change Feedback.config and we're done. - temporary until rolled into web.config in 1.7
	LogMessage "warn" "Temporary - Feedback.config as a standalone - until rolled into web.config in 1.7"
	LogMessage "info" "Change Feedback.config and we're done."


	if (test-path -path "$ngatshare\Feedback.config"){
		[xml]$Feedbackreplace = gc $FeedbackConfigFile
		 switch ($Feedbackreplace.FeedbackSettings.EmailSettings.GroupSettings) {
			{$_.id -eq "ContentIssue"}{$_.Target_Email = $Feedb_target_email[0]
				LogMessage "info" "Setting ContentIssue Target email to $Feedb_target_email[0]"}
			{$_.id -eq "Suggestions"}{$_.Target_Email = $Feedb_target_email[1]
				LogMessage "info" "Setting Suggestions target email to $Feedb_target_email[1]"}
			{$_.id -eq "UnExpectedBehavior"}{$_.Target_Email = $Feedb_target_email[2]
				LogMessage "info" "Setting UnExpectedBehavior target email to $Feedb_target_email[2]"}
			default {LogMessage "warn" "nodes not found";break }
			}
			$Feedbackreplace.Save($FeedbackConfigFile)
		}else{
		LogMessage "warn" "$ngatshare\Feedback.config not found, skipping"
		}


	

	# Disabling this as per Sujal - She wants this to be a dev configured value. If the value needs to change the Dev needs to check in an updated config file and push a new build. 
	
	# if (test-path -path "$ngatshare\VoyagerUI.config"){
		# LogMessage "info" "Modifying $voyagerUIconfig via XML" 
		# [xml]$VoyagerUIreplace = gc $voyagerUIconfig
		# $VoyagerUIreplace."Expedia.ContactCenter.NGAT.Web.Config.VoyagerUI".selectsinglenode("setting[@name='MigrationFlags']").value.migrationflags.hotelsVenereBookings=$HotelsVenereBookings
		# $VoyagerUIreplace.Save($voyagerUIconfig)
		# }else{
		# LogMessage "warn" "$ngatshare\VoyagerUI.config not found, skipping"
		# }
		
	# Done with the Config file changes	
	#############################################################
}










# STEP 1 - Environment setup.
# Testing if current context is admin
LogMessage "info" "Begin Environment Setup"
LogMessage "info" "Testing if User is an administrator."
# function Test-Administrator{
	# $user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	# (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
	
if(!(Test-Administrator)){
	#Write "Please run as Administrator";break
	LogMessage "error" "Please run as Administrator."
	}else{
	LogMessage "info" "User is an Administrator."
	}

# Step 1a - Starting Logging
#$Transcriptlogfile="$logroot_install\Voyager-build-to-build-update_transcript_$installTimeStamp.log"
#	start-transcript -path $Transcriptlogfile


# Step 1b - Is execution policy set to restricted? Attempt to set 
LogMessage "info" "Testing execution policy."
try {Set-ExecutionPolicy Bypass -scope localmachine -force; "Execution OK"}
catch {
	LogMessage "warn" "Unable to set Execution Policy."
	LogMessage "warn" "Current ExecutionPolicy:  $(Get-ExecutionPolicy)"
	}


# Step 1c - load system modules
LogMessage "info" "Loading System Modules"
LogMessage "info" $(Import-Module ServerManager -passthru)
LogMessage "info" $(Import-Module WebAdministration -passthru)
# Removing extra modules
		# Get-Module -listavailable| foreach{
		# LogMessage "info" $("Loading Module: "+$_.name)
		# write "loading $_.name"; 
		# Import-Module $_.name
		# }

# SStep 1d - set appcmd Alias
# Commenting out since we're not using it.
	# LogMessage "info" "Setting appcmd Alias"
	# new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force



# STEP 2 - Loading config file and validating user input
LogMessage "info" "Loading config file and validating user input"
if(test-path -path $defaultconfig){
		$DefaultCSV=Import-Csv .\$defaultconfig
	}else{
		LogMessage "error" "$defaultconfig was not in the same location as the script." 
		break
	}


# Step 2a - Testing to see if server was configured using Server Prep or manually.
#     terminate execution for manual server to avoid random errors
if(!(test-path c:\cct_ops\iis_cert.txt)){
	LogMessage "warn"  "iis_cert.txt is not found in C:\cct_ops. Please run Server Prep script `n wiki here: http://confluence/display/ContactCenter/Voyager+UI+-+Prepping+Blank+Server `n`n "
	#break
	}


# Step 2b - Setting the environment.
#   Basically $environment="xx" is now an optional variable. Only the version needs to be specified
LogMessage "info" "Auto determining your environment"
if($environment -eq "none"){
	$environment=($DefaultCSV | ? {$_.Servers_in_Environment.split(";") -eq $env:computername}).environment
	LogMessage "info" "Environment is: $environment"
	}


## commenting out because it has not been used .. probably ever. This is the only snipper which used 
	# Step 2c - If enabled - Auto determining latest build based on currently deployed build.
# if($Optional -eq "auto"){
	# LogMessage "info" "Auto Deployment selected. Auto determining build to install."
	#Determining version number from Version.txt
	# [string]$CurrentNgatVersion=(gc $ngatshare\version.txt) -match '([v]\d{1}\..{1,10})$'
	# $CurrentNgatVersion=($CurrentNgatVersion -split("to "))[1]
	# $CurrentNgatVersionShort=$CurrentNgatVersion -replace '(.0.)[0-9]+\Z'
	# $buildversion = (dir $buildstorage\$CurrentNgatVersionShort* |sort -property LastWriteTime|select -last 1).name
	# LogMessage "info" "Current installed version: $CurrentNgatVersion"
	# LogMessage "info" "New version: $buildversion"
	# }


# Step 2d - Checking if all Input is received
#   Is server in environment.csv & if auto not set Was anything specified for buildversion?
#if($environment -eq "none" -or $buildversion -eq "none" -or $environment -eq $null -or $buildversion -eq $null)
if(!(Test-Path variable:environment) -or !(Test-Path variable:buildversion)) {
	LogMessage "info"  "Display Usage:"
	LogMessage "info"  "Deployment environment or build version not specified. "
	LogMessage "info"  "you executed: script.ps1 $environment $buildversion"
	LogMessage "info"  "How to Run:";
	LogMessage "info"  "	Script_name.ps1 Test01 0.7.0.2  -  this will deploy 0.7.0.2 build to Test01 environment."
	LogMessage "info"  "	list of all available environments in the config:"
	LogMessage "info"  " "
	LogMessage "info"  "To Generate config files w/o deployment, please execute: "
	LogMessage "info"  "             script.ps1 <environment> <buildversion> WebConfigOnly"
	
	
	foreach($i in $DefaultCSV){
		LogMessage "info" $i.environment
		}
	
	LogMessage "info" "list of 3 latest builds for each version: 0.5, 0.6, 0.7, etc.."
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
	LogMessage "error" "Environment: $environment not found in $Defaultconfig. `n Printing list of available environments."
	$list
	break
}ELSE{
	if(!(($DefaultCSV | ? {$_.environment -eq $environment}).servers_in_environment -match $env:computername)){
		LogMessage "warn" "Current server ($env:computername) not found in $environment `n Assuming user knows what they're doing... proceeding with deployment"
		}
	}

# Step 2f - Getting build location
LogMessage "info" "Getting build location"
if(!(test-path $buildstorage\$buildversion)){
	LogMessage "error" "Path not found, please make sure $buildstorage\$buildversion exists"
	break
		}else{
		LogMessage "info" "Grabbing the build..."
		#$buildpath = gci $buildstorage\$buildversion* | sort -property lastwritetime | select -last 1;start-sleep 1
		$buildpath = "$buildstorage\$buildversion"
		
	LogMessage "info" "build path: $buildpath"
	$buildNum = split-path $buildpath -leaf
	}


# Step 2g - Loading values for correct environment.
LogMessage "info" "Loading values for correct environment." 

$arrayposition=-1    
Foreach($i in $DefaultCSV){
	$arrayposition++
	if ($i.environment -eq $environment){
			$EnvironmentServers = $i.Servers_in_Environment.trim().split(";")
			if($ngatsharein -ne $null -and $ngatsharein -ne $i.NgatRootFolder){$ngatshare = $ngatsharein}else{$ngatshare = $i.NgatRootFolder}
			$iisPfxcertname		= $i.PFXfilename.trim()
			$iisPfxcertpass		= $i.PFXPassword.trim()
			$App_Fabric_Hosts	= $i.App_Fabric_Hosts.trim().split(";")
			$NGAT_Web_Properties_Settings	= $i.NGAT_Web_Properties_Settings
			$Voyager_BusinessLayer_Properties_Settings	= $i.Voyager_BusinessLayer_Properties_Settings
			$tokenproviderURL	= $i.Token_Provider_Url.trim()
			$IISCertName		= $i.IIS_Cert_Name.trim()
			$IISCertThumb		= $i.IIS_cert_Thumbprint.trim()
			$OmnitureTagging	= $i.OmnitureTagging.trim()
			$SMTP				= $i.SMTP.trim()
			$App_Fabric_Cache	= $i.App_Fabric_Cache.trim()
			$ExpediaSuggestBaseURL = $i.ExpediaSuggestBaseURL.trim()
			$Navigator_UI_URL   = $i.Navigator_UI_URL.trim()
			$PseudoLoc			= $i.PseudoLoc.trim()
			$ServiceEndpointURL	= $i.Srv_End_Point_URL.trim()
			$AutodocURL			= $i.Navigator_AutodocURL
			$Nav_binding		= $i.Navigator_bidning
			$ADFSUrl			= $i.ADFS_Url.trim()
			$SSLThumbprint		= $i.ADFS_TokenCertThumb.trim()
			$TrustURL			= $i.ADFS_TrustURL.trim()
			$Feedb_target_email	= $i.Feedback_target_email_123.trim().split(";")
			$HotelsVenereBookings=$i.HotelsVenereBookings_VoyagerUIconfig.trim()
			$LogAppenderLevel	=$i.LogAppenderLevel.trim()
			#$App_Fabric_Hosts_h= @{};foreach($r in $i.App_Fabric_Hosts.split(";")){$App_Fabric_Hosts_h.add($r,"22233")}
			LogMessage "info" "Environment $environment found, loading values: "
			$DefaultCSV[$arrayposition].pfxpassword="****"
			#LogMessage "info" "$DefaultCSV[$arrayposition]"
			break
		}
	}

#moving here from Top of the script.
$ngatbackup			= $ngatshare+"_Backup"


#temporary safety net
if (!(test-path $ngatshare)){LogMessage "error" "$ngatshare Not found"}



if ($iisPfxcertpass -match '\A\\\\.*\\.*'){
	#testing path to password file
	if(test-path -path $matches){
		$passwordfile=Import-Csv .\$matches | where {$_.environment -eq $environment}
		$iisPfxcertpass = $passwordfile.$iisPfxcertpass
	}else{
		LogMessage "Warn" $("Script expect " + $matches +" to be a file and be accessible")
	}
}



##################################################
##### web.config generation 
if($Optional -eq "WebConfigOnly"){
	Logmessage "Warn" "Running in Webconfig Generation mode"
	Logmessage "Info" $("environment = " + $environment + " --  Buildversion = " + $buildversion)
	IF (!(TEST-PATH C:\CCT_Ops)){MD C:\CCT_Ops}
	
	$WebConfigModifiedFile      = "C:\CCT_Ops\web.config_$environment_$buildversion.config"
	$FeedBackConfigModifiedFile = "C:\CCT_Ops\Feedback.config_$environment_$buildversion.config"
	$voyagerUIconfigModifiedFile= "C:\CCT_Ops\VoyagerUI.config_$environment_$buildversion.config"
	copy $buildpath\deliverables\web.config      $WebConfigModifiedFile
	copy $buildpath\deliverables\Feedback.config $FeedBackConfigModifiedFile
	copy $buildpath\deliverables\VoyagerUI.config $voyagerUIconfigModifiedFile
	
	ModifyConfigFiles $WebConfigModifiedFile $FeedBackConfigModifiedFile $voyagerUIconfigModifiedFile
	
	Logmessage "Info" "Web.config is generated here:     $WebConfigModifiedFile"
	Logmessage "Info" "Feedback.config is generated here:  $FeedBackConfigModifiedFile"
	Logmessage "Info" "VoyagerUI.config is generated here:  $voyagerUIconfigModifiedFile"
	CloseLogFile
	break}
##################################################


#Step 3 - Make sure IIS is running - known good
if (($s=get-service w3svc).status -ne "running"){Start-Service -name w3svc}else{
	#testing complex logging  as a workaround
	LogMessage "info" $($s.name + " " + $s.status)
	}

# STEP 6 - Start Deployment of NGAT
LogMessage "info" "Deploying NGAT"
LogMessage "info" "Stopping NGAT website "
#accomodating multi instance deployment

$active_website = get-website | ? {$_.physicalpath -like [string]$ngatshare}
$active_website | Stop-Website 



# Delete NGAT Share to prevent open handles
LogMessage "info" "deleting NGAT share - prevents open handles"
net share $ngatshare /d /y 2>&1 | Out-Null
if ($? -eq 0){
	LogMessage "info" "$ngatshare could not be deleted. Trying NGAT.."
	net share ngat /d /y}else{
		LogMessage "info" "$ngatshare deleted"
		}

# Step 5 - Backup of Web.config & Verstion.txt
LogMessage "info" "Backup of Web.config & Version.txt"
$VersionTxt			= "$ngatshare\version.txt"
$FeedbackConfigFile = "$ngatshare\Feedback.config"
$voyagerUIconfig	= "$ngatshare\VoyagerUI.config"
$webConfig			= "$ngatshare\web.config"

#testing simplification
	# Function BackupConfigs ($inputfile){
		# LogMessage "info" $("Creating backup of existing $inputfile to: $ngatbackup\$installTimeStamp"+"_$inputfile")
		# copy $inputfile $("$ngatbackup\$installTimeStamp"+"_$inputfile")
	# }

	# BackupConfigs $ngatshare\version.txt
	# BackupConfigs $FeedbackConfigFile
	# BackupConfigs $voyagerUIconfig
	# BackupConfigs $webConfig

$VersionBack="$ngatbackup\$installTimeStamp"+"_version.txt"
LogMessage "info" "Creating backup of existing version.txt to: $VersionBack"
if(test-path $VersionTxt){copy $VersionTxt $Versionback}else{LogMessage "warn" "backup of $VersionTxt didnt succeed"}

$FeedbackBack="$ngatbackup\$installTimeStamp"+"_Feedback.config"
LogMessage "info" "Creating backup of existing Feedback.config to: $FeedbackBack"
if(test-path $FeedbackConfigFile){copy $FeedbackConfigFile $FeedbackBack}else{LogMessage "warn" "backup of $FeedbackConfigFile didnt succeed"}

$UIconfigBack="$ngatbackup\$installTimeStamp"+"_VoyagerUI.config"
LogMessage "info" "Creating backup of existing VoyagerUI.config to: $UIconfigBack"
if(test-path $voyagerUIconfig){copy $voyagerUIconfig $UIconfigBack}else{LogMessage "warn" "backup of $voyagerUIconfig didnt succeed"}

$oldweb_config="$ngatbackup\$installTimeStamp"+"_web.config"
LogMessage "info" "Creating backup of existing Web.Config to: $oldweb_config"
if(test-path $webConfig){copy $webConfig $oldweb_config}else{LogMessage "warn" "backup of $webConfig didnt succeed"}



# STEP x  - Renaming current NGAT to NGAT.Old
MD E:\ngat_deployment_temp\ -force
if(test-path $ngatshare\feedback){Move-item $ngatshare\feedback E:\ngat_deployment_temp\ -PassThru}else{LogMessage "warn" "Move $ngatshare\feedback didnt succeed"}
if(test-path $ngatshare\EndCall){Move-item $ngatshare\EndCall E:\ngat_deployment_temp\ -PassThru}else{LogMessage "warn" "Move $ngatshare\feedback didnt succeed"}
#hacky workaround until someone takes the time to make it prettier
  #for whatever reason executing the same command twice cleans everything w/o errors.
try{
	if(test-path $ngatshare){Remove-Item $ngatshare\* -force -recurse}else{LogMessage "warn" "Remove $ngatshare didnt succeed because it's likely not there"}
	}
Catch{
	if(test-path $ngatshare){
		"=========================================Hacky work around to delete files"
		Remove-Item $ngatshare\* -force -recurse}else{
		LogMessage "warn" "Remove $ngatshare didnt succeed because it's likely not there"}
	}

# STEP 4 - Create NGAT folders
LogMessage "info" "Creating NGAT Folders and Granting permissions"
$folderlist=$ngatshare,"$ngatshare\EndCall","$ngatshare\EndCall\Drop","$ngatshare\EndCall\Temp","$ngatshare\Feedback","$ngatshare\Feedback\Drop","$ngatshare\Feedback\Temp","c:\cct_ops",$ngatbackup,$log_appEventLogs,$log_voyager_appLogs
$folderlist |foreach {IF (!(TEST-PATH $_))
		{	# folders should already be there, if not, reset all permissions just in case
			MD $_
				# STEP 4b - Grant permissions
			LogMessage "info" "Grant permissions to folder $_"
			icacls $_ /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)(RX)"
			icacls $_ /grant:r "IIS APPPOOL\DefaultAppPool:(OI)(CI)(RX)"
			icacls $_ /grant:r "IIS APPPOOL\NGAT:(OI)(CI)(F)"
			icacls $_ /grant:r "SEA\s-tfxlabrun%:(OI)(CI)(RX)"
		}
	}
# test code - cleanup - rd e:\ngat -recurse



# Step 6a - Robocopy steps
$SourceDir= "$buildpath\deliverables"
$DestDir= "$ngatshare"

LogMessage "info" "Starting ROBOCOPY"
#new way of copying
robocopy $SourceDir $DestDir /NP /MIR /R:5 /W:5

#cleaning 'fake' folders
RD $ngatshare\feedback -force -recurse -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
RD $ngatshare\EndCall -force -recurse -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
Move-item E:\ngat_deployment_temp\feedback $ngatshare\ -PassThru -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
"Copy of Feedback was $?"
Move-item E:\ngat_deployment_temp\EndCall $ngatshare\ -PassThru -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
"Copy of Endcall was $?"
RD E:\ngat_deployment_temp\ -force -recurse


# Do a diff on source and destination and raise an error if not in sync (exclude EndCall and Feedback dir)
LogMessage "info" "Diffing Source and Destination folders to ensure successful copy was performed"
$folders = get-childitem $SourceDir | ? {$_.PSIsContainer -and $_.name -ne "EndCall" -and $_.name -ne "Feedback"} 
foreach($folder in $folders){
	LogMessage "info" "  Comparing folder: .\$folder" 
	#write-host "  Comparing folder: .\$folder" 
	$d1 = get-childitem -path "$SourceDir\$folder" -recurse
	$d2 = get-childitem -path "$DestDir\$folder"   -recurse
	$resultCompare = compare-object $d1 $d2 -PassThru
	if ($resultCompare) {
		LogMessage "warn" $("Source and Destination directories are not in sync:" + $folder)
		$notes += "`n`rSource and Destination directories are not in sync: $folder"
		}
	}


# Step 6b - setting User and version number in Version.txt
LogMessage "info" "setting User and version number in Version.txt"
# not needed - new version numbers are completely different.
##[string]$OldVersion=(gc $VersionBack) -match '([v]\d{1}\..{1,10})$'
##$OldVersion=($OldVersion -split("to "))[1]
[string]$OldVersion=split-path (gc $VersionBack)[5] -leaf


[string]$currentuser=whoami
"<pre>"															| out-file "$ngatshare\Version.txt"
"You are looking at:  $env:computername ($environment)" 		| out-file "$ngatshare\Version.txt" -append -width 150
"deployment executed by $currentuser on $installTimeStamp"	 	| out-file "$ngatshare\Version.txt" -append -width 150
"Build updated from $OldVersion to $buildnum"					| out-file "$ngatshare\Version.txt" -append -width 150
"Environment values used for this deployment:" 					| out-file "$ngatshare\Version.txt" -append -width 150
$buildpath														| out-file "$ngatshare\Version.txt" -append -width 150
$DefaultCSV[$arrayposition]										| out-file "$ngatshare\Version.txt" -append -width 150
"Contact information for the branch: "							| out-file "$ngatshare\Version.txt" -append -width 150
if (test-path $ngatshare\release-contacts.config) {
	gc $ngatshare\release-contacts.config 	| out-file "$ngatshare\Version.txt" -append -width 150 
	}


# Step 6C - Creating History.txt file to keep track of ALL deployments done on the server and make it accessible via IIS.
"Build updated from $OldVersion to $buildnum by $currentuser `t on $installTimeStamp" | out-file "$ngatbackup\history.txt" -append
copy "$ngatbackup\history.txt" $ngatshare




# Execute Modify Config Files function define earlier.
if ($ProdEnvironment -contains $environment.tolower()){
	ren $ngatshare\web.config $ngatshare\web.config-original
	ren $ngatshare\web.config_$environment $ngatshare\web.config	
	} ELSE {
	. ModifyConfigFiles $webConfig $FeedbackConfigFile $voyagerUIconfig
	}



# STEP 8 - Post deployment steps.
		
LogMessage "info" "Clearing IIS Cache and Handles"
restart-service w3svc
LogMessage "info" "Starting NGAT Website"
#if($multisitepath -ne $null){Start-Website $multisitepath}Else{Start-Website "NGAT"}
$active_website | Start-Website 

# CreateEventLogSource.exe
pushd $ngatshare
LogMessage "info" "Running CreateEventLogSource.exe " 
.\CreateEventLogSource.exe 'Expedia.ContactCenter.NGAT'

# Set maxlog size to 500mb
LogMessage "info" 'Setting  HKLM:SYSTEM\CurrentControlSet\services\eventlog\Application" -Name MaxSize -Value 524288000'
Set-ItemProperty "HKLM:\system\CurrentControlSet\services\eventlog\Application" -Name MaxSize -Value 524288000

# disable Auto archive log when it reaches max size
LogMessage "info" 'Setting "HKLM:SYSTEM\CurrentControlSet\services\eventlog\Application" -Name AutoBackupLogFiles -Value 0'
Set-ItemProperty "HKLM:\system\CurrentControlSet\services\eventlog\Application" -Name AutoBackupLogFiles -Value 0





# Move Archive log files and remove items older than 7 days
# Disabling since we're not archiving any more

	#LogMessage "info" "Attempting to Delete the old Application event logs"
	#foreach ($_ in Get-Childitem $log_appEventLogs | Where {$_.LastWriteTime -le (get-date).AddDays(-7)} ) {"removing $_.FullName";ri $_.FullName}
	#LogMessage "info" "Attempting to Move the Application event logs"
	#pushd $env:windir\system32\winevt\Logs
	#gci -Name "archive-application*" | foreach $_ { move $_ $log_appEventLogs }
	#popd

# Move Voyager app log files to d:\logroot and remove items older than 30 days
#LogMessage "info" "Removing files older than 7 days from $logroot\voyager"
#foreach ($_ in Get-Childitem $logroot\voyager -Recurse | Where {$_.LastWriteTime -le (get-date).AddDays(-7)} ) {"removing " + $_.fullname;ri $_.FullName}

if(test-path -path $ngatshare\logs){
		try{
			LogMessage "info" "Moving Log Files from $ngatshare\logs to $logroot\voyager"
			Copy-Item -Path $ngatshare\logs -Destination $logroot\voyager -Recurse
			rd $ngatshare\logs -Force -Recurse
			LogMessage "info" "Moved $ngatshare\logs to $logroot\voyager"
		}catch{
			LogMessage "warn" "Problem occured moving $gatshare\logs to $logroot\voyager"
		}
		
	}

# Disable SSL 2.0
LogMessage "info" "Removing SSL 2.0 if found" 
DisableSSL20

# Checking if MVC(AppFabric), Eventvwr Hotfixes are installed
LogMessage "info"  "Checking if MVC(AppFabric), Eventvwr Hotfixes are installed"
$Hotfix_Location = $scriptexecutedfrom.providerpath+"\..\..\bin\hotfixes\"
TestHotfix KB2546548 $Hotfix_Location\Windows6.1-KB2546548-x64.msu
TestHotfix KB980368 $Hotfix_Location\Windows6.1-KB980368-x64.msu


## Removing Directory Browsing - 02/19/2013 - alex - this has been in server prep script for a year.
# try {LogMessage "info" "Removing Directory Browsing if installed"
	# Remove-WindowsFeature Web-Dir-Browsing}
# catch{LogMessage "warn" "WARNING!!!  Unable to remove Directory Browsing. Most likely cause is reboot required"}

#Recreating NGAT share
LogMessage "info" "Recreating NGAT share"
$envusername | %{$string+='"'+"/grant:$_,full"+'" '}
net share ngat=$ngatshare $string

#Create Logroot share if not exist
if(!(Test-Path("\\$env:computername\logroot"))) { net share logroot=$logroot }



#check if IIS is up and running
# Commenting out functionality to speed up deployment
	#try{LogMessage "info" "trying to get the version via IIS"
	#	$client = new-object System.Net.WebClient
	#	$tempiistestpath="$logroot\temp.txt"
	#	$client.DownloadFile("https://$env:computername.$DnsDomain/version.txt", $tempiistestpath )
		## probably useless code - testing IIS and comparing the output vs what was shoved into version.txt - should be identical
	#	$tempiisver=((gc $tempiistestpath) -match "\b[v]\d{1}\.")[0].tostring().substring(45,12).trim()
	#	LogMessage "info" "Version retrieved from IIS  = $tempiisver" ;""
	#	 }
	#catch{LogMessage "warn" "WARNING!!! Unable to retrieve IIS version.txt"
	#	 LogMessage "warn" "Please hit the URL manually: https://$env:computername.$DnsDomain/version.txt"
	#	 # - throws a silly-long error message - LogMessage "warn" "$error[0]"
	#	 }

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
			 $a			| out-file "$ngatshare\Version.txt" -append
		} else {
			 ($a = "      " + $logHTML.Replace("$logroot_install\$env:computername", "\\$_\logroot\install\$_"))
			  $a		| out-file "$ngatshare\Version.txt" -append		
		}
	}



# Make sure SENS service is started - requested from E2E team
# old Get-Service | %{ if( $_.name.contains("SENS") ) { if ( $_.status -eq 'Stopped') { $_.Start() } }}
get-service -name *sens* | start-Service


#If Production, rename version.txt to version.config
if ($ProdEnvironment -contains $environment.tolower()){
		ren "$ngatshare\Version.txt" "$ngatshare\Version.txt.config" 
		ren "$ngatshare\history.txt" "$ngatshare\history.txt.config" 
	}ELSE{
		# Step 6C - Creating shared History.txt file to keep track of ALL deployments ever done.
		"$ServerName`t$environment`tBuild updated from $OldVersion to $buildnum by $currentuser`ton $installTimeStamp"| out-file "\\chelappsbx001\Public\cct_ops\total_History.txt" -append

		#setting up tools folder
		InstallLocalbin
		
		#Clean up logs
		stop-Service EventSystem -force -passthru

		Clear-EventLog application
		
		## seems killing the handle was preventing new logs from being written. Commenting out 8/22/12 (Alex)
		## $file=(Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\eventlog\Application\).file
		## $a=c:\localbin\handle.exe -accepteula $file
		## 	try{$a[5..$a.count] -gt 0|%{c:\localbin\handle.exe -p $_.substring(24,7).trim() -c $_.substring(31.4).trim() -y}}
		## catch{"cant close handle"}
		## foreach($i in $b){c:\localbin\handle.exe -p $i.substring(24,7).trim() -c $i.substring(31.4).trim() -y}
		## if (test-path $file){del $file}

		start-Service EventSystem -passthru
		
		### Enabling Kerboros auth to run deployment via Powershell directly
		set-item wsman:localhost\client\trustedhosts -value *.karmalab.com -Force
		enable-psremoting -force
		Enable-WSManCredSSP -Role server -Force
		Enable-WSManCredSSP -Role client -DelegateComputer "*.karmalab.net" -Force
		
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
$emailbody = GenericMailBody
$emailbody += 'Tee command output:           <a href="' + "\\$env:computername\logroot\install\remote_install_"+$environment+"_"+ $buildNum + "_tee.log" + '">' + "\\$env:computername\logroot\install\remote_install_"+$environment+"_"+ $buildNum + "_tee.log"	+ "</a><br><br><br>"
$emailbody += 'Old Version.txt: <a href="'+ $($VersionBack.replace("E:\","\\$ServerName\E$\"))	+'">'+"\\$ServerName\e$\ngat_backup"+ "</a><br>"
$emailbody += 'Old Feedback.config: <a href="'+$($FeedbackBack.replace("E:\","\\$ServerName\E$\")) +'">'+"\\$ServerName\e$\ngat_backup"		+ "</a><br>"
$emailbody += 'Old VoyagerUI.config: <a href="'+$($UIconfigBack.replace("E:\","\\$ServerName\E$\"))+'">'+"\\$ServerName\e$\ngat_backup"		+ "</a><br>"
$emailbody += 'Old Web.config: <a href="'+$($oldweb_config.replace("E:\","\\$ServerName\E$\"))+'">'+"\\$ServerName\e$\ngat_backup"			+ "</a><br><br>"


$emailbody += "Differences (if any) between New web.config and one stored as backup: "
$diff_webconfig | foreach {$emailbody += "$_ <br>"}
$notes | foreach {$emailbody += "$_ <br>"}
amail "$env:username@expedia.com" $("$env:username@expedia.com","voyrel@expedia.com") "Deployment on $environment - $env:computername finished successfully"  $emailbody -attachment $attachment

RebootRequired
# SIG # Begin signature block
# MIIGBwYJKoZIhvcNAQcCoIIF+DCCBfQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9qyH22ukYy2luRU9/gwnuFdP
# U1CgggQpMIIEJTCCA46gAwIBAgIQZYCiv3KRDoNH6gz2dQW5izANBgkqhkiG9w0B
# AQUFADAUMRIwEAYDVQQDDAlzaWduLXRlc3QwHhcNMTMwNDE3MDIxMzQ0WhcNMTQw
# NDE3MDIzMzQ0WjAUMRIwEAYDVQQDDAlzaWduLXRlc3QwgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBANQZDvA+Logv3V503oiAhUBXEILTYRl6PxL6J6Zi/3vIhQpF
# 7vn+1jgR2n1LlAYeHLdw6MqID+6V13Na4jzjDDm/+tfd9kO4oV40tjwZkos51CbJ
# ZC7OutbuQe97qcd43eBhsR40SwpIssSozYBPXgB+19c8+Fm/dqhOu4tAbBdBAgMB
# AAGjggJ2MIICcjA8BgkrBgEEAYI3FQcELzAtBiUrBgEEAYI3FQiCydcuwvhugt2X
# NYSgtwCH5PcmOoO63BSE7Nx3AgFkAgEEMA4GA1UdDwEB/wQEAwIFoDAoBgNVHSUE
# ITAfBggrBgEFBQcDAQYIKwYBBQUHAwMGCWCGSAGG+EIBATA0BgkrBgEEAYI3FQoE
# JzAlMAoGCCsGAQUFBwMBMAoGCCsGAQUFBwMDMAsGCWCGSAGG+EIBATAdBgNVHQ4E
# FgQU/ieVq6bAOt7L+Sjv7P03vYtKhzkwIgYKKwYBBAGCNwoLCwQUcwBpAGcAbgAt
# AHQAZQBzAHQAAAAwgYgGCisGAQQBgjcKCxoEegZ2AAAhAAAAQwBIAEMALQBTAFYA
# QwBQAEsASQAwADEALgBTAEUAQQAuAEMATwBSAFAALgBFAFgAUABFAEMATgAuAGMA
# bwBtAAAAFAAAAEUAeABwAGUAZABpAGEAIABJAG4AdABlAHIAbgBhAGwAIAAxAEMA
# AAAAAAAAMIHzBgorBgEEAYI3CgtXBIHkAAAAAAAAAAACAAAAIAAAAAIAAABsAGQA
# YQBwADoAAAB7ADQAQQA5ADAANABFAEQAMwAtAEYAOAAzADEALQA0ADMANAA2AC0A
# OABBADEAMgAtADEAMAA1AEYAQwAzADYANQA1ADkAQwAzAH0AAABDAEgAQwAtAFMA
# VgBDAFAASwBJADAAMQAuAFMARQBBAC4AQwBPAFIAUAAuAEUAWABQAEUAQwBOAC4A
# YwBvAG0AXABFAHgAcABlAGQAaQBhACAASQBuAHQAZQByAG4AYQBsACAAMQBDAAAA
# MwAwADIAMQA0AAAAMA0GCSqGSIb3DQEBBQUAA4GBAHBVsL90xsFGcxXMdp1RMFB/
# vgLsBeE86keu0HSGh0z8NRN+GNV6NPL+dy2Qr4S57Sufrn31QLUBHmR0bCjGLKYq
# mZ+kjtClT5JjHGM9fzp7aFKxDmuHxpfRIJ9gwcC7sn96KO6QYGMN/WF9ilTT5Vlr
# ghi1YR8xatnL7UZ3YY98MYIBSDCCAUQCAQEwKDAUMRIwEAYDVQQDDAlzaWduLXRl
# c3QCEGWAor9ykQ6DR+oM9nUFuYswCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMtajWVwXeSbPpeh
# 9J56DXy4eT2YMA0GCSqGSIb3DQEBAQUABIGAADS1h0TUifwdj3kh2Cnt0gGq7kDp
# sX5g/G5VcmHn67XonPFwvyP/4l36koJ0JYj7DlcQGm5UaYPdE8bZBwazG/Cof+FW
# PvXqW3j3fJ0dFjme4rjPJWO4Lwb3RZSY2qk+pE80tdat4Mvg/RkO3IzO8dj1wujH
# 8UYyHpDhLc3bdKs=
# SIG # End signature block
