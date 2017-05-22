######################################################################
#     Script for setting up Primary ADFS on a brand new server       #
#                                                                    #
#              v2 Crude but effective by Alex Vinyar                 #
#     Scripts available here: p1986\sait\users\Automation\ADFS\      #
######################################################################

# This script expects to be either executed from "pushd \\CHELAPPSBX001.karmalab.net\DeploymentAutomation\Voyager_IIS\Deployment"
# Or as part of a copy of the whole DeploymentAutomation folder.

# Start Powershell with Modules (Run as Admin)
# The script must be executed from the same location as the config file.

Import-Module ..\lib\Functions_common.psm1 -Force
ImportSystemModules

$parentPath=Split-Path -Parent -Path .\ -Resolve

#Environment variables
$dotNetInstall = "$parentPath\bin\hotfixes\dotNetFx40_Full_x86_x64.exe"
$dotNet45Install = "$parentPath\bin\hotfixes\dotNetFx45_full_x86_x64.exe"

#Start Logging
write-host -f cyan "Environment setup."
write-host -f cyan "Start Transcript."
try {stop-transcript}
catch { "Unable to Stop Transcript, probably already stopped"}
try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$pwd\ADFS_Installation_Primary_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile}
catch { "Unable to Start Transcript"}

#Step 0 - Environment setup and Verification that everything is good.
# Is command window open as administrator?
Test-Administrator

# Is execution policy set to restricted?
Set-ExecutionPolicyUnrestricted

#get current location
$script_location=$pwd

#Step 1 - Gathering inputs
#future version this will be a user input
$config_file='mp_adfs_common_config.txt'
if(test-path -path $config_file){$allinputs=Import-Csv $config_file -Delimiter ~
$adfsacctname=$allinputs[0].value
$adfsacctpass=$allinputs[1].value
$iiscertname=$allinputs[2].value
$iiscertpass=$allinputs[3].value
$signcertname=$allinputs[4].value
$signcertpass=$allinputs[5].value
$deccertname=$allinputs[6].value
$deccertpass=$allinputs[7].value
$federationservicename=$allinputs[8].value
$Provisioningcert=$allinputs[10].value
$Provisioningpass=$allinputs[11].value
#$Identifiers=@(($allinputs[15].value).tolower().split(","))
Write-host -ForegroundColor Cyan "Input received"
} ELSE {
write-host -ForegroundColor Red "ERROR
$config_file was not in the same location as the script.";break}


# $adfsacctname
# $adfsacctpass
# $iiscertname
# $iiscertpass
# $signcertname
# $signcertpass
# $deccertname
# $deccertpass
# $federationservicename
# $Provisioningcert
# $Provisioningpass





#Test if cert files actually exist.
if(!(test-path -literalpath $iiscertname)){write-host  -ForegroundColor Red "$iiscertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$iiscertname - OK"}
if(!(test-path -literalpath $signcertname)){write-host  -ForegroundColor Red "$signcertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$signcertname - OK"}
if(!(test-path -literalpath $deccertname)){write-host  -ForegroundColor Red "$deccertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$deccertname - OK"}
if(!(test-path -literalpath $Provisioningcert)){write-host  -ForegroundColor Red "$deccertname not found at the path specified"
break}else{write-host -ForegroundColor Cyan "$Provisioningcert - OK"}


# Step 2 - Install ADFS (iis/.net/wfi/powershell plugin)
write-host "Installing ADFS - process should take between 30 seconds to 10 minutes, depending on missing components"
$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
$ADFSlogfile="$pwd\mp_ADFS_Setup_Primary_$installtime.log"
$ADFSInstall = "AdfsSetup.exe"
$ADFSInstallParams = "/quiet /logfile $ADFSlogfile"
Start-Process $ADFSInstall $ADFSInstallParams -wait
if ((gc -path $ADFSlogfile | select-string -pattern "AD FS 2.0 is already installed on this computer") -eq $null){write-host -ForegroundColor Cyan "ADFS Installed"} Else{write-host -ForegroundColor Red "There was an error Installing ADFS, please check the log file: $ADFSlogfile"
write-host "last line of file: " (gc -path $ADFSlogfile | select -last 1)
break}



#step 3 - installing IIS Scripting
PKGMGR.EXE /l:log.etw /iu:IIS-ManagementScriptingTools

#step 3a - Install .Net 4.0
write-host -f cyan "Installing .NET 4.0 - process should take 5 to 10 minutes"
$dotNetlogfile="$pwd\dotNet4setup_$installtime.log"
$dotNetParams = '/q /norestart /log '+$dotNetlogfile
Start-Process $dotNetInstall $dotNetParams -wait
write-host -ForegroundColor Cyan ".Net 4.0 Installed.  Log file located here: $dotNetlogfile"


#step 3a - Install .Net 4.5
write-host -f cyan "Installing .NET 4.5 - process should take 5 to 10 minutes"
$dotNetlogfile="$pwd\dotNet45setup_$installtime.log"
$dotNetParams = '/q /norestart /log '+$dotNetlogfile
Start-Process $dotNet45Install $dotNetParams -wait
write-host -ForegroundColor Cyan ".Net 4.0 Installed.  Log file located here: $dotNetlogfile"

#Step 4 - Add certs to computer

#------------IIS Cert function ----------
function certinstallloop ($certpassin, $certnamein){
$certout=certutil -f -importpfx -p $certpassin $certnamein
	if($? -eq $false){write-host -f red "There was an error in installation of the cert:";"";$certout;break
	}else{
	$certout=($certout | select -first 1).replace('" added to store.',"").replace('Certificate "',"")}
return $certout}

Write-host -f cyan "Installing IIS cert"
$iiscert=certinstallloop $iiscertpass $iiscertname
$iiscert # test code
Write-host -f cyan "Installing Signing cert"
$signcert=certinstallloop $signcertpass $signcertname
$signcert # test code
Write-host -f cyan "Installing Decrypting cert"
$deccert=certinstallloop $deccertpass $deccertname
$deccert # test code
Write-host -f cyan "Installing Provisioning cert"
$provcert=certinstallloop $Provisioningpass $Provisioningcert
$provcert # test code

# step 5 - Remove / Recreate SSL binding on default web site.
#
Remove-WebBinding  -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

#   step 5a - Create a binding on 443 with cert from above
New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https

#   step 5b - Get thumbprint for specific cert
Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert} | New-Item IIS:\SslBindings\0.0.0.0!443


#step 6 - Run config wizard.
#collect thumbprints for the certs.
($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})
($b=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $signcert})
($c=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $deccert})
($d=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $provcert})

#run the ADFS config wizard.
pushd "C:\Program Files\Active Directory Federation Services 2.0"
try{.\FSConfig.exe CreateFarm /ServiceAccount $adfsacctname /ServiceAccountPassword $adfsacctpass /CertThumbprint $a.thumbprint /SigningCertThumbPrint $b.thumbprint /DecryptCertThumbPrint $c.thumbprint /FederationServiceName $federationservicename /CleanConfig 
If ($? -eq $true){Write-Host -ForegroundColor Green ("SUCCESS: ADFS Configured")}}
catch{;break}
popd

#Step 9 - page 25 - Adding CCTAuthorization Database as User Attribute Store (Primary Server Only)  
# ------------------------------------------------------------------------------------------------------

# Add-ADFSAttributeStore -Name 'CCTAuthorization' -StoreType 'SQL' -Configuration @{"Query"="Data Source=$AttribStoreSQL;Initial Catalog=CCTAuthorization;Integrated Security=SSPI;"} 
# Write-host -ForegroundColor Cyan "Adding CCTAuthorization Database as User Attribute Store - Done"

# Add-ADFSAttributeStore -Name 'RollCall' -StoreType 'SQL' -Configuration @{"Query"="Data Source=$RollCallSQL;Initial Catalog=$RollCallDBName;Integrated Security=SSPI;"} 
# Write-host -ForegroundColor Cyan "Adding RollCall Database as User Attribute Store - Done"


# Page 28 - Changing Offered Claims for Metadata
# Add-ADFSClaimDescription -Name "First Name" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/firstname" -IsOffered 1
# Add-ADFSClaimDescription -Name "Middle Name" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/middlename" -IsOffered 1
# Add-ADFSClaimDescription -Name "Last Name" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/lastname" -IsOffered 1
# Add-ADFSClaimDescription -Name "Known As" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/knownas" -IsOffered 1
# Add-ADFSClaimDescription -Name "Email Address" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/email" -IsOffered 1
# Add-ADFSClaimDescription -Name "Primary Language" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/primarylanguage" -IsOffered 1
# Add-ADFSClaimDescription -Name "Secondary Language" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/secondarylanguage" -IsOffered 1
# Add-ADFSClaimDescription -Name "Third Language" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/thirdlanguage" -IsOffered 1
# Add-ADFSClaimDescription -Name "Location Name" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/locationname" -IsOffered 1
# Add-ADFSClaimDescription -Name "Vendor Name" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/vendorname" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentFirstName" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentLastName" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentLastName" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentUserRole" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentLogonName" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName" -IsOffered 1
# Add-ADFSClaimDescription -Name "CurrentSupervisorName" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentPeopleID" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID" -IsOffered 1
# Add-ADFSClaimDescription -Name "Tpid_Tuids" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentHubID" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentHubID" -IsOffered 1
# Add-ADFSClaimDescription -Name "AgentNavigatorLogin" -ClaimType "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin" -IsOffered 1
# Write-host -ForegroundColor Cyan "Changing Offered Claims for Metadata - Done"


# Page 29-50 - Adding Trust for Hat as Relying Party
#Add-ADFSRelyingPartyTrust -Name "Hat" -Notes "Hat is a relying party to CCT ADFS" -Identifier "https://us.expediaairagenttool.com","https://ca.expediaairagenttool.com", "https://uk.expediaairagenttool.com" , "https://de.expediaairagenttool.com" -IssuanceAuthorizationRules '@RuleName = "Query CCTAuthorization for HAT Authorization and add allowed claim" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=>issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.HatAuthorizeUser @pLogin = {0}", param = c.Value);' -IssuanceTransformRules '@RuleName = "Issue Hat claims from CCTAuthorization store" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]  => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/firstname", "http://contactcentertokenprovider.expedia.com/claims/middlename", "http://contactcentertokenprovider.expedia.com/claims/lastname", "http://contactcentertokenprovider.expedia.com/claims/knownas", "http://contactcentertokenprovider.expedia.com/claims/email", "http://contactcentertokenprovider.expedia.com/claims/primarylanguage","http://contactcentertokenprovider.expedia.com/claims/secondarylanguage", "http://contactcentertokenprovider.expedia.com/claims/thirdlanguage", "http://contactcentertokenprovider.expedia.com/claims/locationname", "http://contactcentertokenprovider.expedia.com/claims/vendorname", "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"), query = "EXEC dbo.HatGetUserAttributes @pLogin = {0}", param = c.Value);'


# Adding Trust Relying Party for all NGAT components from Config file.
# ForEach($i in $Identifiers){
# "Create Claims for $i "#test code

# try {
#Add-ADFSRelyingPartyTrust -Name $i -Notes "$i is a relying party to CCT ADFS" -Identifier $i -IssuanceAuthorizationRules '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=>issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Voyager_Authorize_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);' -IssuanceTransformRules '@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=> issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID"), query = "EXEC dbo.SSO_Claims_Voyager_PeopleDetails_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);@RuleName =  "TIPID-TUID" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=> issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);' -WSFedEndpoint $i
#Write-host -ForegroundColor Cyan  "Added $i Relying Party / Identifier / Endpoint - Done"
# .\Create_claims.ps1 $i 18 #Voyager
	# }
	# catch {
		# Write-host -ForegroundColor Cyan "$i Relying party creation failed, most likely: The name of the relying party trust must be unique in AD FS 2.0 configuration"
		# .\Update_claims_VoyagerLodging.ps1 $i 18
		# }
# }

# each identifier has to be matched to end point. Multiple Identifiers ok. There can not be multiple endpoints per identifier.

#broken but how it should be.
#Add-ADFSRelyingPartyTrust -Name $i -Notes "$i is a relying party to CCT ADFS" -Identifier $i -IssuanceAuthorizationRules ('@RuleName = '+""Auth_Rule_$i""+'c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=>issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Voyager_Authorize_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);') -IssuanceTransformRules '@RuleName = '+"people_detail_$i"+'c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=> issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID"), query = "EXEC dbo.SSO_Claims_Voyager_PeopleDetails_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);@RuleName =' +"TIPID-TUID_$i"+'c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"]=> issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);' -WSFedEndpoint $i


#Step 10 - add eventlog source
..\bin\CreateEventLogSource.exe "AD FS 2.0"

# Removing Directory Browsing
# try {LogMessage "info" "Removing Directory Browsing if installed"
	# Remove-WindowsFeature Web-Dir-Browsing}
# catch{LogMessage "warn" "WARNING!!!  Unable to remove Directory Browsing. Most likely cause is reboot required"}

set_enableVersionHeader_false


# End transcript
try {stop-transcript}
catch { "Unable to Stop Transcript"}