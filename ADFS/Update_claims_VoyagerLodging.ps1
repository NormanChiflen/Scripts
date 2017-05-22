# Script to update Claims based on Localhost configuration




# set up people_detail Rule
# $newClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor"), query="EXEC dbo.SSO_Claims_Voyager_PeopleDetails_Lst#01 @pPeopleAuthenticationLogin  = {0}", param = c.Value);'

# ToolID allowed
#   VoyagerFlights == 20
#   VoyagerLodging == 18
#   Navigator      == 21


#Environment setup
param([string]$RelyingParty, [string]$toolID)


#Start logging.
try {$installtime=get-date -uformat "%Y_%h_%d_%H_%M"
	$Transcriptlogfile="$pwd\ADFS_Update_IssuanceTransformRules_Transcript_$installtime.log"
	start-transcript -path $Transcriptlogfile|out-null}
catch { "Unable to Start Transcript"}

#is command window open as administrator?
function Test-Administrator
{$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$a=Test-Administrator
if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}

#is execution policy set to restricted?
try {set-executionpolicy remotesigned -force}
catch { "Unable to set Group Policy"}

$a=Get-ExecutionPolicy
if ($a -eq "Restricted"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy"
break}

#Add ADFS to powershell
if ( (Get-PSSnapin -Name Microsoft.Adfs.PowerShell -ErrorAction SilentlyContinue) -eq $null )
	{write-host -f cyan "loading Microsoft.Adfs.PowerShell"
	Add-PsSnapin Microsoft.Adfs.PowerShell}

#Step 2 - Gathering inputs
# Available ToolIDs are
#
# 20 VoyagerFlights
# 18 VoyagerLodging
# 21 Navigator
#
$ValidToolIDs = (20,18,21)
if($ValidToolIDs -contains $toolID){
	write-host "Creating claim for toolID $toolID"
}else{
	write-host " "
	write-error "Must enter a valid ToolID" 
	write-host " "
	write-host "Valid toolIDs are"
	write-host "20 VoyagerFlights"
	write-host "18 VoyagerLodging"
	write-host "21 Navigator"
	write-host " "
	stop-transcript|out-null;break	
}


# Make this case sensitive, instead of all lower case	
if($relyingParty -ne ""){$identifiers=@(($relyingParty).split(","))
"";"relyingParty received:"; $identifiers;; write-host -f Cyan "if above is not correct, you have 6 seconds to press CTRL + C multiple times to terminate";start-sleep 6
} ELSE {
write-host "";"NOTE: If you see this error: `"The term 'Add-ADFSRelyingPartyTrust' is not recognized as the name of a cmdlet`""
Write-host "Please execute: Add-PSSnapin Microsoft.Adfs.PowerShell";"";""
write-host "Help section:"
write-host "ERROR Relying party has not been specified. Please use format below and dont forget the highlighted parts";
Write-Host "Format for the script is: script.ps1 " -nonewline; write-host -f yellow "https" -nonewline; Write-Host "://relyingparty/" -nonewline;"";""
Write-host "To create multiple Relying party, enclose them in quotes and separate by a comma:"
write-host "                          script.ps1 " -nonewline;Write-Host -f yellow '"' -nonewline;write-host  "https://relyingparty1/"-NoNewline; Write-Host -f yellow ',' -nonewline;Write-host "https://relyingparty2/"-nonewline; Write-Host -f yellow ',' -nonewline;Write-host "etc..." -nonewline;Write-Host -f yellow '"';""
Write-Host -f yellow "                                     /\                     /\                     /\     /\"
Write-Host -f yellow "                                  Dont Forget           Dont Forget"
#yes, maybe i was a little bored :)
stop-transcript|out-null;break
}


# set up people_detail rule
$ClaimDescription_IssuanceTransformRules='@RuleName = "people_detail" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/AgentPeopleID", "http://contactcentertokenprovider.expedia.com/claims/AgentFirstName", "http://contactcentertokenprovider.expedia.com/claims/AgentLastName", "http://contactcentertokenprovider.expedia.com/claims/CurrentSupervisorName", "http://contactcentertokenprovider.expedia.com/claims/AgentLogonName", "http://contactcentertokenprovider.expedia.com/claims/AgentUserRole", "http://contactcentertokenprovider.expedia.com/claims/AgentHubID", "http://contactcentertokenprovider.expedia.com/claims/AgentEmail", "http://contactcentertokenprovider.expedia.com/claims/AgentLocation", "http://contactcentertokenprovider.expedia.com/claims/AgentVendor", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorLogin", "http://contactcentertokenprovider.expedia.com/claims/AgentNavigatorRole", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsToolLogin", "http://contactcentertokenprovider.expedia.com/claims/VoyagerFlightsRole"), query="EXEC dbo.SSO_Claims_Voyager_PeopleDetails_Lst#02 @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
# set up tipid-tuid Rule
$ClaimDescription_IssuanceTransformRules+='@RuleName = "TIPID-TUID" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://contactcentertokenprovider.expedia.com/claims/Tpid_Tuids"), query = "EXEC dbo.SSO_Claims_Voyager_TPIDTUID_Lst @pPeopleAuthenticationLogin  = {0}", param = c.Value);'
# set up PeopleAuth Rule
$ClaimDescription_IssuanceTransformRules+='@RuleName = "PeopleAuth_Log" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "RollCall", types = ("http://contactcentertokenprovider.expedia.com/claims/Permit"), query = "EXEC dbo.ToolLoginAttemptAdd @pPeopleAuthenticationLogin = {0}, @pToolID = {1}, @pLogonSuccessful = {2}", param = c.Value, param = "' + $toolID + '", param = "1");'

# set up IssuanceAuthorizationRule
$IssuanceAuthRule = '@RuleName = "Auth_Rule" c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] => issue(store = "CCTAuthorization", types = ("http://schemas.microsoft.com/authorization/claims/permit"), query = "EXEC dbo.SSO_Claims_Authorize_Lst @pPeopleAuthenticationLogin  = {0}, @pToolID = {1}", param = c.Value, param = "' + $toolID + '");'


ForEach($i in $Identifiers){

	#$i = "https://mcraig.karmalab.net"

	#start-sleep 3
	# Get Current RelyingPartyTrusts
	$trusts=Get-ADFSRelyingPartyTrust

	#start-sleep 2
	#clear;
	foreach ( $a in $trusts) {if($a.Name -eq $i){$localhostClaim=$a.IssuanceTransformRules}}

	# echo out claim info
	#write-host " ============= LocalHost Claim =============="
	#$localhostClaim

	# echo out claim info
	#write-host " ============= newClaimDescription Claim =============="
	$newClaimDescription_IssuanceTransformRules=$ClaimDescription_IssuanceTransformRules

	#start-sleep 3


	# Select the one I'm testing - Next will be to iterate through all of them
	foreach ( $a in $trusts) {if($a.Name -eq "$i"){"Found: " + $a.Name;$oldClaim=$a.IssuanceTransformRules}}
	#write-host " ============= Old Claim =============="
	#$oldClaim

	#start-sleep 3

	write-host " ====***====== Setting -IssuanceTransformRules for $i ====***======="
	Set-ADFSRelyingPartyTrust -TargetName $i -Notes "$i is a relying party to CCT ADFS" -IssuanceAuthorizationRules $IssuanceAuthRule -IssuanceTransformRules $newClaimDescription_IssuanceTransformRules

	#start-sleep 3
	# Get Current RelyingPartyTrusts
	$trusts=Get-ADFSRelyingPartyTrust

	#start-sleep 5
	foreach ( $a in $trusts) {if($a.Name -eq $i){$updatedClaim=$a.IssuanceTransformRules}}

	write-host " ============= Updated Claim =============="
	#$updatedClaim
}

