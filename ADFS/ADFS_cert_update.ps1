#Voyager SSL cert update script

#$defaultconfig ="environments.csv"
#$DefaultCSV=Import-Csv .\$defaultconfig
Write "Executing on $env:computername";"----------------------------------";"----------------------------------"

$iiscertname		= "\\CHELAPPSBX001\cert_update\karmalab.net\karmalab.net.pfx"
$iiscertpass		= "giraug"
$OldSSLThumbprint	= "496E3778928ECC25D0B601EDCDB55350B1D76C4E"
$NewADFSSSLThumbprint	= "8DBC7C4AD2B2D07338AD2B4C2A9FFB2C02665D50"
$NewSSLThumbprint	= "5314BDFA0255BE36E53E749D03339AE2964FB4CD"
$CertName			= "*.karmalab.net"
$webConfig			= "e:\ngat\web.config"
$installtime		= get-date -uformat "%Y_%h_%d-%H_%M"


#Loading modules
Get-Module -listavailable| foreach{write "loading $_.name"; Import-Module $_.name}


# Step 1 - Environment setup
function Test-Administrator{
	$user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	(New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}
$admin=Test-Administrator
if($admin -ne "True"){ Write "Please run as Administrator";break}

write "Testing execution policy."
try {Set-ExecutionPolicy unrestricted -scope localmachine -force; "Execution OK"}
catch { "Unable to set Execution Policy"}


# Step 2 - Getting old cert info 
write "Getting old cert info ";"---"
$currentcert="c:\cct_ops\iis_cert.txt"
$Oldiiscert= gc c:\cct_ops\iis_cert.txt
($OldIIScertProperties=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $Oldiiscert})


# Step 3 - Deleting the old cert
#certutil -store my $OldSSLThumbprint
#certutil -store my $NewSSLThumbprint
#(certutil -store my *.karmalab.net).count -ge 29

write "Deleting the old cert";"---"
if($OldIIScertProperties.Thumbprint -ne $NewSSLThumbprint){
	certutil -delstore my $OldIIScertProperties.Thumbprint
	}else{
	#brute force approach - just in case
	certutil -delstore my "496E3778928ECC25D0B601EDCDB55350B1D76C4E"
	}


#Rename iis_cert.txt  to old 
if(test-path $currentcert){ren $currentcert "$currentcert_$installtime"}



# STEP 4 - Install server level cert
write "Installing Certs"

function certinstallloop ($certpassin, $certnamein){
	$certout=certutil -f -importpfx -p $certpassin $certnamein
	#certutil -f -importpfx -p $iiscertpass $iiscertname
	if($? -eq $false){write-host -f red "There was an error in installation of the cert:";"";return $certout;break
		}else{
	$certout=($certout | select -first 1).replace('" added to store.',"").replace('Certificate "',"")
	Write-Host -ForegroundColor Green "Cert Installed"}
	return $certout}


# actually installing the cert. () are to display output instead of just processing it.
($iiscert=certinstallloop $iiscertpass $iiscertname)
# saving the cert name for setting up Voyager portion (mostly to assign ngat app pool to e:\ngat)
$iiscert | out-file c:\cct_ops\iis_cert.txt
Write "Cert name saved to a local file in C:\cct_ops\iis_cert.txt"

# collect properties for the certs.
write "collect properties for the certs."
($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})



# STEP 5 - Assign IIS users & AppPools to cert
write "Applying Default AppPool security to Cert"
	#username - ngat\apppool  - cant do NGAT app pool until NGAT is deployed.
$uname="IIS APPPOOL\DefaultAppPool"
$keyname=$a.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
	write "before change"  #debug code
	icacls $keypath$keyname #debug code
write "";"";"after change"
icacls $keypath$keyname /grant:r $uname":R"
icacls $keypath$keyname #debug code



# Script 2

# STEP 6 - Granting IIS apppool\ngat read access to the cert
write "Granting IIS apppool\ngat read access to the cert."
$uname="IIS APPPOOL\NGAT"
$keyname=$a.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
	write "before change"
	icacls $keypath$keyname       #debug code
icacls $keypath$keyname /grant:r $uname":R"
write "";"";"after change"
icacls $keypath$keyname  #debug code




# STEP 7 - Assign cert to the NGAT website
write "Assign cert to the NGAT website"
Stop-Website "default web site"
Remove-WebBinding -Name "NGAT" -IP "*" -Port 443 -Protocol https
remove-item IIS:\SslBindings\0.0.0.0!443
#   Create a binding on 443 with cert from above
New-WebBinding -Name "NGAT" -IP "*" -Port 443 -Protocol https
#   Set thumbprint for specific cert
Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.thumbprint -eq $a.thumbprint} | New-Item IIS:\SslBindings\0.0.0.0!443




# Script 3
Stop-Website "NGAT"

$doc = new-object System.Xml.XmlDocument
$doc.Load($webConfig)

#writelog "EncryptingCertificateSubject = $certname"
#$doc.SelectSingleNode("/configuration/appSettings/add[@key='EncryptingCertificateSubject']").value = $certname
write "SSL thumbprint = $NewADFSSSLThumbprint"
$doc.get_DocumentElement()."microsoft.identityModel".service.issuerNameRegistry.trustedissuers.add.thumbprint = $NewADFSSSLThumbprint

$doc.Save($webConfig)
write "Web.config saved with Modifications"

Start-Website "NGAT"

#Remove the SSL
#Ports?
#Add new SSL
#Ports?

#web.config
#-cert name
#thumbprint



