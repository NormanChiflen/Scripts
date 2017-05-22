##Creating multiple websites for Voyager by Alex Vinyar
##v2 - connected with voyager upgrade iis only script



#Note:	The script is hard coded to use *.voyager.sb.karmalab.net certificate. 
#		Please make appropriate changes in Environment.csv to make sure it matches.

param([string]$Site="none",$environment="none",$buildnumer="none",$HH="none")


if ($Site -eq "none"){
	"An error has occured:"
	"Specify a site to deploy"
	"You executed: Sites=$Site  environment=$environment  Build=$buildnumer  HH=$HH"
	""
	"Please specify Required parameters"
	"script <Required:Site Name> <Optional:Environment to use as a base for config> <Optional:Build to deploy> <Optional:Unique HH>";""
	"Example script John-training01 ";"or"
	"Example script John-training01 Dev01 v1.0.0.27";"or"
	"Example script -site John-training01 -hh John-Dragon74 -environment dev01 -buildnumber v1.0.0.99";"or"
	"Example script John-training01 Dev01 v1.0.0.27 John-Dragon74";"";""
	break}




if ((test-path e:) -ne $true){"No E: drive found. Please create one"; Break}

# Import common functions
Import-Module ..\..\..\lib\Functions_common.psm1 -verbose -Force

#variables:
$appname			= "VoyagerUI"
$BuildLabel			= "$appname_$buildversion"
$buildstorage		= "\\karmalab.net\builds\directedbuilds\sait\CRM\products\ngat"			# Test
$envusername		= "karmalab\_crmdev","everyone"	
$defaultconfig		= "environments.csv"
$ServerName			= "$env:ComputerName"
$LogFolder			= "d:\logroot\"
$installTimeStamp	=getStartTime "yyyy_MM_dd_HH_mm_ss"


CreateLogFilePath "createSite" "$env:computername" "$environment" "$LogFolder"

# STEP 1 - Environment setup.
write-host -f cyan "Environment setup."
write-host -f cyan "Testing if User is an administrator."
if(!(Test-Administrator)) { Write-host -ForegroundColor Red "Please run as Administrator";break }


# Is execution policy set to restricted? Attempt to set 
write-host -f cyan "Testing execution policy."
try {Set-ExecutionPolicy bypass -scope localmachine -force}
catch { "Unable to set Execution Policy"}
$a=Get-ExecutionPolicy
if ($a -ne "bypass"){write-host  -ForegroundColor Yellow "ExecutionPolicy = $a. You can change Please change execution policy to *Bypass* to avoid all the Y/N questions"
}

#load system modules
Import-Module ServerManager -passthru
Import-Module WebAdministration -passthru

# Set appcmd Alias
write-host -f cyan "Seting appcmd Alias"
new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force

# STEP 2 - Loading config file (hard coded since there will be one shared across environments)
		#$DefaultCSV=Import-Csv ..\$defaultconfig

#Was anything specified for environment?
		# if($environment -eq "none")
			# {Write-host -f yellow "Deployment environment not specified. ";
			# write "example:  Script_name.ps1 Test01"; 
			# write "Examples all environments currently in the config."
			# foreach($i in $DefaultCSV){write $i.environment};break}
		# else {"Executing script for $environment"}

	#this is only needed for Host Headers.
			#Testing if specified value exists in environments.	-	
			# if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
				# {write-host -f yellow "environment " $environment " not found in the $Defaultconfig"
				# write "list of all available environments in the config."
				# foreach($i in $DefaultCSV){write $i.environment};break}

	#dont need this because deployment is separate
		#Finding values for correct environment.
		# $arrayposition=-1    
		# Foreach($i in $DefaultCSV){
			# $arrayposition++
			# if ($i.environment -eq $environment){
					# $EnvironmentServers = $i.Servers_in_Environment.trim().split(";")
					# $tokenproviderURL	= $i.Token_Provider_Url.trim()
					# $CertName			= $i.Cert_Name.trim()
					# $EndpointURL		= $i.End_Point_URL.trim()
					# $App_Fabric_Cache	= $i.App_Fabric_Cache.trim()
					# $App_Fabric_Hosts	= $i.App_Fabric_Hosts.trim().split(";")
					##$App_Fabric_Hosts_h= @{};foreach($r in $i.App_Fabric_Hosts.split(";")){$App_Fabric_Hosts_h.add($r,"22233")}
					# $ADFSUrl			= $i.ADFS_Url.trim()
					# $SSLThumbprint		= $i.SSLThumbprint.trim()
					# $TrustURL			= $i.TrustURL.trim()
					# $iiscertname		= $i.PFXfilename.trim()
					# $iiscertpass		= $i.PFXPassword.trim()
					# $SMTP				= $i.smtp.trim()
					# $OmnitureTagging	= $i.OmnitureTagging.trim()
					# $AutodocURL			= $i.AutodocURL
					# LogMessage "info" "Environment $environment found, loading values: "; 
					# $DefaultCSV[$arrayposition].pfxpassword="****"
					# LogMessage "info" "$DefaultCSV[$arrayposition]"
					# break
				# }
			# }

######Creating other versions of NGAT 
$HostHeaderURL="environment.voyager.sb.karmalab.net"

:home Foreach($i in $Site){

	if ($HH -eq "none"){$HH=$i}


	#$z=$HostHeaderURL.replace("environment",$HH) #.replace("version",$i.replace("NGAT_",""))
	$z=$HostHeaderURL.replace("environment",$HH) #.replace("version",$i.replace("NGAT_",""))
	
	#Test if DNS already exists and points to the correct server
	$TestHostAddress = ping $z -n 1
	
	if ($? -eq $true){
		$TestHostAddress[1] -match '([\d]{1,3}\.){3}\d{1,}' | Out-Null
		if ($matches[0] -eq (Test-Connection $env:computername -count 1).ipv4address.ipaddresstostring){
			"looks like DNS is already setup for this site ($Z). Great!"
		}ELSE{
		"DNS name already taken. Please check Perforce:1970 //deployment/net/karmalab/AUTOPILOT/WIN32/ENV/DNS"
		break home
		}
	}ELSE{
	$errorMessage = @()
	$errorMessage += "No DNS setup, please setup ($z) and point it to this servers IP "
	$errorMessage += "Please setup in Perforce:1970 //deployment/net/karmalab/AUTOPILOT/WIN32/ENV/DNS"
	$errorMessage += "DNS address for this site should be: " + $z
	}

	$x=gc ..\NGAT_AppPool_config_basic.xml
	$x[4]=$x[4].replace("NGAT",$i)
	$x[6]=$x[6].replace("NGAT",$i)
	
	write-host -f cyan "Deleting NGAT website, NGAT App Pool and Application in case they're here"
	appcmd delete app "$i/"
	appcmd delete site "$i"
	appcmd delete apppool "$i"

	$x | appcmd add apppool /in

	
	$y=gc ..\NGAT_site_config_full.xml
	$y[4] =$y[4].replace("NGAT",$i).replace('SITE.ID="2"',"") #.replace('"https/*:443":','"https/*:443":dev01-v05.voyager.sb.karmalab.net')
	$y[6] =$y[6].replace('id="2"',"").replace("NGAT",$i)
	$y[86]=$y[86].replace("NGAT",$i)
	$y[90]=$y[90].replace("NGAT",$i)
	$Y | appcmd add site /in
	#per bug in powershell http://forums.iis.net/t/1159223.aspx
	set-webconfigurationproperty "/system.applicationHost/sites/site[@name=`'$i`']/bindings/binding[@protocol='https']" -name bindingInformation -value "*:443:$z"
	write-host -f cyan $z " assigned"
	start-website $i
	
	# STEP 4a - Create NGAT folders
	write-host -f Cyan "Creating NGAT Folders and Granting permissions"
	$ngatshare="E:\$i"
	$folderlist=$ngatshare,"E:\$i\EndCall","E:\$i\EndCall\Drop","E:\$i\EndCall\Temp","c:\cct_ops"
	$folderlist |foreach {IF (!(TEST-PATH $_)){MD $_}}
	#cleanup rd e:\ngat -recurse

	# STEP 4b - Grant permissions
	write-host -f Cyan "Grant permissions to folders"
	net share ngat=$ngatshare "/grant:$envusername,full"
	icacls $ngatshare /grant:r "BUILTIN\IIS_IUSRS:(OI)(CI)(RX)"
	icacls $ngatshare /grant:r "IIS APPPOOL\DefaultAppPool:(OI)(CI)(RX)"
	icacls $ngatshare /grant:r "IIS APPPOOL\$i`:(OI)(CI)(F)"

	# STEP 4c - Granting AppPool\NGAT access to the cert.
	#  Collecting Cert for IIS
	write-host -f cyan "collect Cert name for the IIS cert."
	$iiscert= gc c:\cct_ops\iis_cert.txt
	($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})

	# STEP 4d - Granting IIS apppool\ngat read access to the cert
	write-host -f cyan "Granting IIS apppool\ngat read access to the cert."
	$uname="IIS APPPOOL\$i"
	$keyname=$a.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
	$keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
	write-host "before change";icacls $keypath$keyname       #debug code
	icacls $keypath$keyname /grant:r $uname":R"
	write-host "";"";"after change";icacls $keypath$keyname  #debug code

	# STEP 5 - Assign cert to the NGAT website
	write-host -f cyan "Assign cert to the NGAT website"
	if (Test-Path "IIS:\Sites\default web site"){Stop-Website "default web site"}
	Remove-WebBinding -Name "$i" -IP "*" -Port 443 -Protocol https
	remove-item IIS:\SslBindings\0.0.0.0!443
	#   Create a binding on 443 with cert from above
	New-WebBinding -Name "$i" -IP "*" -Port 443 -Protocol https
	#   Set thumbprint for specific cert
	Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | New-Item IIS:\SslBindings\0.0.0.0!443
	
}

$errormessage | %{write-host -f yellow $_}

if($buildnumer -ne "none" -and $environment -ne "none"){
	pushd ..
	.\Voyager_upgrade_IIS_only.ps1 $environment $buildnumer -ngatsharein $ngatshare
	$errormessage | %{write-host -f yellow $_}
	}

