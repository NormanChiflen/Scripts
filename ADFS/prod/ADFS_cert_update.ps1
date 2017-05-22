#Voyager SSL thumbprint update for Prod

Write "Executing on $env:computername";"----------------------------------";"----------------------------------"

# Variables
$NewADFSSSLThumbprint	= "8DBC7C4AD2B2D07338AD2B4C2A9FFB2C02665D50"
$webConfig				= "e:\ngat\web.config"

# optional 
# $CertName			= "*.karmalab.net"


# Step 1 - Environment setup

#Loading modules
Get-Module -listavailable| foreach{write "loading $_.name"; Import-Module $_.name}

function Test-Administrator{
	$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$admin=Test-Administrator
if($admin -ne "True"){ Write "Please run as Administrator";break}

write "Testing execution policy."
try {Set-ExecutionPolicy unrestricted -scope localmachine -force; "Execution OK"}
catch { "Unable to set Execution Policy"}


# Step 2 - Changing the thumbprint in web.config
Stop-Website "NGAT"
$doc = new-object System.Xml.XmlDocument
$doc.Load($webConfig)
write "SSL thumbprint = $NewADFSSSLThumbprint"
$doc.get_DocumentElement()."microsoft.identityModel".service.issuerNameRegistry.trustedissuers.add.thumbprint = $NewADFSSSLThumbprint

# This is here in case you have to change cert name.
# writelog "EncryptingCertificateSubject = $certname"
# $doc.SelectSingleNode("/configuration/appSettings/add[@key='EncryptingCertificateSubject']").value = $certname

$doc.Save($webConfig)
write "Web.config saved with Modifications"

Start-Website "NGAT"
