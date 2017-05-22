#Remote install


param([string]$environment="none",$buildversion="none",$targetServer="none" )
$DefaultCSV=Import-Csv .\environments.csv
$CCT_FOLDER="c:\cct_ops"
$SCRIPT_PATH="$CCT_FOLDER\remote_script.bat"
$LOG_FOLDER="d:\logroot\install"
$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
$buildstorage = "\\chc-filidx\cctss\Voyager\Web_UI"  # prod - NGAT_00.001.0012.23971
$buildstorage = "\\karmalab.net\builds\directedbuilds\sait\CRM\products\ngat"        # Test

set-alias ps-exec "$CCT_FOLDER\PsTools\PsExec.exe"  

if (!(TEST-PATH $CCT_FOLDER)) { md $CCT_FOLDER}
if (!(TEST-PATH $cct_folder\PsTools\)) { md $cct_folder\PsTools\}

#Testing if PSExec exists, creating if not.
if (!(TEST-PATH (alias ps-exec).definition)) {
		"PSExec not found. Copying..."
		copy ..\..\bin\PsExec.exe (alias ps-exec).definition
	} 

# Cache username/pwd
. .\cachedCred.ps1

$defaultconfig ="environments.csv"
$DefaultCSV=Import-Csv .\$defaultconfig

#Testing if specified value exists in environments.
if(-not($DefaultCSV | ? {$_.environment -eq $environment})){
	write-host -f red "Environment " $environment " not found in the $Defaultconfig"
	write "Available supported environments."
	foreach($i in $DefaultCSV){write $i.environment};break
}
		
Foreach($i in $DefaultCSV){
	if ($i.environment -eq $environment){
		$EnvironmentServers = $i.Servers_in_Environment.Split(";")
	}
}
				 

#Pick deployment share based on environment
$AUTOMATION_SCRIPTS_PROD="\\chc-filidx\cctss\Voyager\Web_UI"
$AUTOMATION_SCRIPTS_KARMALAB="\\chelappsbx001\DeploymentAutomation\Voyager_IIS\Deployment"
$USE_PROD_FILE_SHARE=@("Training1", "Training2", "Iso-prod", "DR", "PROD")

				 
#Testing if specified value exists in environments.
if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
	{write-host -f yellow "environment " $environment " not found in the $Defaultconfig"
	write "list of all available environments in the config."
	foreach($i in $DefaultCSV){write $i.environment};break}
    
write-host "You have selected the $environment environment"
#write-host "The following servers will be deployed"
#foreach($i in $DEPLOY_ENVS[$environment]){write-host $i}

write-host "Get Build Number"
# Get Build Number
if(!(test-path $buildstorage"\"$buildversion*)){"path not found, please make sure $buildstorage\Release_$buildversion exists"; break
	}else{
	#manual work around against network hickups.
	$r=1..1;$r|foreach{$buildpath = gci $buildstorage"\"$buildversion* | sort -property lastwritetime | select -last 1;start-sleep 1; write "Searching for the latest build..."}
	write-host -f cyan "build path: $buildpath"	}
	
$buildNum = $buildpath.name
write-host "Build Number: $buildNum"

Set-Content -Path $SCRIPT_PATH "pushd \\chelappsbx001\DeploymentAutomation\Voyager_IIS\Deployment"
Add-Content -Path $SCRIPT_PATH "if not exist $LOG_FOLDER md $LOG_FOLDER"
Add-Content -Path $SCRIPT_PATH "powershell -ExecutionPolicy Bypass .\Voyager_IISupgrade_withXmlLogging.ps1 $environment $buildNum < NUL 2>&1^| tee e:\logroot\install\remote_install_$environment_$buildNum_$installtime.log"
Add-Content -Path $SCRIPT_PATH "popd"

foreach($i in $EnvironmentServers){
	
	$out = "Deploy to " + $i + " ?"
	
	$caption = "++++++++++++++"
	$message = $out
	$yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
	$no = new-Object System.Management.Automation.Host.ChoiceDescription "&No",""
	$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
	$answer = $host.ui.PromptForChoice($caption,$message,$choices,0) 

	switch ($answer){
		0 {"Deploying " + $i;
			#Copy-Item -Path $SCRIPT_PATH -Destination \\$i.karmalab.net\c$\cct_ops -force
			$cmd="\\$i.karmalab.net -u " + $Credential.Username + " -p " + $PWDclear + " -h -f -c " + $SCRIPT_PATH + " -w c:\cct_ops cmd /c " + $SCRIPT_PATH;
			
			Invoke-Expression "ps-exec $cmd"
			break
		
		} #yes
		1 {"Skipping " + $i; break} #no
	} 

	
	
}




