######################################################
#  Script for setting up ADFS on a brand new server  #
#                                                    #
#    v1. Adding Claims and Relying Parties           #
#                 by Alex Vinyar                     #
#    v2. Adding support for multiple productIDs      #
#                 by Michael Craig                   #
#    v2.103 Adding support for separate PID logic    #
#                 by Alex		                     #
######################################################

# Start Powershell with Modules (Run as Admin)
# If server is not on the internet, Navigate to location of ADFS installer.

# ToolID allowed
#   VoyagerFlights == 20
#   VoyagerLodging == 18
#   Navigator      == 21
#   MerchantPoint      == 99

#Environment setup
param([string]$userinput, [string]$toolID)

# Set up logroot
if ($logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path) { $logroot }else{$logroot="d:\logroot"}
if (!(Test-Path $logroot)) {md $logroot }
if (!(Test-Path "\\$env:computername\logroot")) {net share logroot=$logroot}


#Start logging.
try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$logroot\ADFS_Setup_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile|out-null}
catch { "Unable to Start Transcript"}

#is command window open as administrator?
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

#is execution policy set to restricted?
try {set-executionpolicy Bypass -force}
catch { "Unable to set Group Policy"}

$a=Get-ExecutionPolicy
if ($a -eq "Restricted"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy"
break}

#Add ADFS to powershell
if ( (Get-PSSnapin -Name Microsoft.Adfs.PowerShell -ErrorAction SilentlyContinue) -eq $null )
	{write-host -f cyan "loading Microsoft.Adfs.PowerShell"
	Add-PsSnapin Microsoft.Adfs.PowerShell}


#Step 2 - Gathering inputs
$ValidToolIDs = (20,18,21,99)

#if($userinput -ne ""){$identifiers=@(($userinput).tolower().split(","))
if($userinput -ne "" -and $ValidToolIDs -contains $toolID)
	{$identifiers=@(($userinput).split(","))
	write-host ""
	write-host "user input received:"
	$identifiers
	write-host "Creating claim for toolID $toolID"
	write-host -f Cyan "if above is not correct, you have 6 seconds to press CTRL + C multiple times to terminate"
	start-sleep 6
} ELSE {
	write-host "<=========================================>"
	write-host "<================HELP=====================>"
	""
	"NOTE: If you see this error: `"The term 'Add-ADFSRelyingPartyTrust' is not recognized as the name of a cmdlet`""
	Write-host "Please execute: Add-PSSnapin Microsoft.Adfs.PowerShell";"";""
	write-host "Help section:"
	write-host "ERROR Relying party has not been specified. Please use format below and dont forget the highlighted parts";
	Write-Host "Format for the script is: script.ps1 " -nonewline; write-host -f yellow "https" -nonewline; Write-Host "://relyingparty/" -nonewline;"";""
	Write-host "To create multiple Relying party, enclose them in quotes and separate by a comma:"
	write-host "                          script.ps1 " -nonewline;Write-Host -f yellow '"' -nonewline;write-host  "https://relyingparty1/"-NoNewline; Write-Host -f yellow ',' -nonewline;Write-host "https://relyingparty2/"-nonewline; Write-Host -f yellow ',' -nonewline;Write-host "etc..." -nonewline;Write-Host -f yellow '"';""
	Write-Host -f yellow "                                     /\                     /\                     /\     /\"
	Write-Host -f yellow "                                  Dont Forget           Dont Forget"
#yes, maybe i was a little bored :)
	write-host ""
	write-host -f red "The URL for the new RP Must followed by a valid ToolID" 
	write-host " "
	write-host "Valid toolIDs are"
	write-host "20 VoyagerFlights"
	write-host "18 VoyagerLodging"
	write-host "21 Navigator"
	write-host " "


stop-transcript|out-null;break
}

#a place to capture moving parts between Tool IDs
Switch ($toolID){
		#RP store name is not in use yet because CCTAuthorization is same as RollCall - shortcut for implementation is ' + $RP_Store_name + '
	18
		{
		$RP_Store_name				= "CCTAuthorization"
		$People_detail_query_Name	= "dbo.SSO_Claims_Voyager_PeopleDetails_Lst#03"
		$TIPID_TUID_Enabled			= 1
		$AppFamily					= "CCT"
		$ClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorRole", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsToolLogin", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsRole"), query="EXEC ' + $People_detail_query_Name + ' @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
		$ClaimDescription_IssuanceTransformRules+='@RuleName = "TIPID-TUID" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
		$ClaimDescription_IssuanceTransformRules+='@RuleName = "PeopleAuth_Log" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "RollCall", types = ("http://contactcentertokenprovider.expedia.com/claims/Permit"), query = "EXEC dbo.ToolLoginAttemptAdd @pPeopleAuthenticationLogin = {0}, @pToolID = {1}, @pLogonSuccessful = {2}", param = c.Value, param = "' + $toolID + '", param = "1");'
		$IssuanceAuthRule = '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Authorize_Lst @pPeopleAuthenticationLogin  = {0}, @pToolID = {1}", param = c.Value, param = "' + $toolID + '");'
		break
		}
	20	
		{
		$RP_Store_name				= "CCTAuthorization"
		$People_detail_query_Name	= "dbo.SSO_Claims_Voyager_PeopleDetails_Lst#02"
		$TIPID_TUID_Enabled			= 1
		$AppFamily					= "CCT"
		$ClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorRole", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsToolLogin", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsRole"), query="EXEC ' + $People_detail_query_Name + ' @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
		$ClaimDescription_IssuanceTransformRules+='@RuleName = "TIPID-TUID" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
		$ClaimDescription_IssuanceTransformRules+='@RuleName = "PeopleAuth_Log" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "RollCall", types = ("http://contactcentertokenprovider.expedia.com/claims/Permit"), query = "EXEC dbo.ToolLoginAttemptAdd @pPeopleAuthenticationLogin = {0}, @pToolID = {1}, @pLogonSuccessful = {2}", param = c.Value, param = "' + $toolID + '", param = "1");'
		$IssuanceAuthRule = '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Authorize_Lst @pPeopleAuthenticationLogin  = {0}, @pToolID = {1}", param = c.Value, param = "' + $toolID + '");'
		break
		}
	21	
		{
		$RP_Store_name				= "RollCall"
		$People_detail_query_Name	= "dbo.SSO_Claims_Voyager_PeopleDetails_Lst#03"
		$TIPID_TUID_Enabled			= 0
		$AppFamily					= "CCT"
		$ClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorRole", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsToolLogin", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsRole"), query="EXEC ' + $People_detail_query_Name + ' @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
		$ClaimDescription_IssuanceTransformRules+='@RuleName = "PeopleAuth_Log" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "RollCall", types = ("http://contactcentertokenprovider.expedia.com/claims/Permit"), query = "EXEC dbo.ToolLoginAttemptAdd @pPeopleAuthenticationLogin = {0}, @pToolID = {1}, @pLogonSuccessful = {2}", param = c.Value, param = "' + $toolID + '", param = "1");'
		$IssuanceAuthRule = '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Authorize_Lst @pPeopleAuthenticationLogin  = {0}, @pToolID = {1}", param = c.Value, param = "' + $toolID + '");'
		break
		}
		
	99 
		{
		$ClaimDescription_IssuanceTransformRules='@RuleTemplate = "LdapClaims" @RuleName = "Username" c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"] => issue(store = "Active Directory", types = ("http://contactcentertokenprovider.expedia.com/claims/Username"), query = ";userPrincipalName;{0}", param = c.Value);'
		$IssuanceAuthRule = '@RuleTemplate = "AllowAllAuthzRule" => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");'
		$ImpersenationAuthorizationRule = 'c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid", Issuer =~ "^(AD AUTHORITY|SELF AUTHORITY|LOCAL AUTHORITY)$" ] => issue(store="_ProxyCredentialStore",types=("http://schemas.microsoft.com/authorization/claims/permit"),query="isProxySid({0})", param=c.Value );c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Issuer =~ "^(AD AUTHORITY|SELF AUTHORITY|LOCAL AUTHORITY)$" ] => issue(store="_ProxyCredentialStore",types=("http://schemas.microsoft.com/authorization/claims/permit"),query="isProxySid({0})", param=c.Value );c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/proxytrustid", Issuer =~ "^SELF AUTHORITY$" ] => issue(store="_ProxyCredentialStore",types=("http://schemas.microsoft.com/authorization/claims/permit"),query="isProxyTrustProvisioned({0})", param=c.Value );'
		$AppFamily					= "MerchantPoint"
		break
		}
		
}

# set up people_detail rules, etc, if not MerchantPoint, Merchant point sets theirs above if ToolID is 99 
#	$ClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorRole", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsToolLogin", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsRole"), query="EXEC ' + $People_detail_query_Name + ' @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
	# set up tipid-tuid Rule
#	if($TIPID_TUID_Enabled -eq 1){
#		$ClaimDescription_IssuanceTransformRules+='@RuleName = "TIPID-TUID" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
#		}
	# set up PeopleAuth Rule
#	$ClaimDescription_IssuanceTransformRules+='@RuleName = "PeopleAuth_Log" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "RollCall", types = ("http://contactcentertokenprovider.expedia.com/claims/Permit"), query = "EXEC dbo.ToolLoginAttemptAdd @pPeopleAuthenticationLogin = {0}, @pToolID = {1}, @pLogonSuccessful = {2}", param = c.Value, param = "' + $toolID + '", param = "1");'

	# set up IssuanceAuthorizationRule
#	$IssuanceAuthRule = '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Authorize_Lst @pPeopleAuthenticationLogin  = {0}, @pToolID = {1}", param = c.Value, param = "' + $toolID + '");'


# Step 20 - Adding Trust Relying Party for all NGAT components from Config file.
ForEach($i in $Identifiers){
"Attempting to create  " +$i 
"             Tool ID: " +$toolID
	if ($AppFamily -eq "CCT"){
		Add-ADFSRelyingPartyTrust -Name $i -Notes "$i is a relying party to $AppFamily ADFS" -Identifier $i -IssuanceAuthorizationRules $IssuanceAuthRule -IssuanceTransformRules $ClaimDescription_IssuanceTransformRules -WSFedEndpoint $i
		if(Get-ADFSRelyingPartyTrust -name $i){write-host -f green "$i has been created / already exists"}
	}else{
		Add-ADFSRelyingPartyTrust -Name $i -Notes "$i is a relying party to $AppFamily ADFS" -Identifier $i -IssuanceAuthorizationRules $IssuanceAuthRule -IssuanceTransformRules $ClaimDescription_IssuanceTransformRules -WSFedEndpoint $i -ImpersonationAuthorizationRules $ImpersenationAuthorizationRule
		if(Get-ADFSRelyingPartyTrust -name $i){write-host -f green "$i has been created / already exists"}
	}
	
}

stop-transcript


