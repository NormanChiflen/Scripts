##########################################################################################
#                  Script for setting up blank Voyager IIS server                        #
#                                                                                        #
#                     v0.2 Crude but effective by Alex Vinyar                            #
#  Scripts available here: p1986\sait\users\Automation\NGAT\Deployment\ngat_iis.ps1      #
##########################################################################################
# 
# Script is designed to be exectuted Locally on the server.
#
param([string]$environment)

Import-Module ..\..\lib\Functions_common.psm1 -verbose -Force


## - Alex - 12/20/2012 - now consuming from common function
EnvironmentPrep
# STEP 1 - Environment setup.
# function Test-Administrator{
	# $user = [Security.Principal.WindowsIdentity]::GetCurrent() 
	# (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)}

# $a=Test-Administrator
# if($a -ne "True"){ Write-host -ForegroundColor Red "Please run as Administrator";break}



# Time executiong of the script started - for unique logging per script execution
$installtime=get-date -uformat "%Y_%h_%d_%H_%M"

#Create CCT Ops share for centralized file storage and such
$cctshare="c:\cct_ops"
IF (!(TEST-PATH $cctshare)){MD $cctshare}

## - Alex - 12/20/2012 - now consuming from common function
# Is execution policy set to restricted? Attempt to set 
# try {Set-ExecutionPolicy bypass -scope localmachine -force}
# catch { "Unable to set Group Policy"}
# $a=Get-ExecutionPolicy
# if ($a -ne "bypass"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy unrestricted"
# break}

#load system modules
## - Alex - 12/20/2012 - now consuming from common function
# Get-Module -listavailable| foreach{write-host -ForegroundColor Cyan loading $_.name; Import-Module $_.name}
#Import-module webadministration,ServerManager



# STEP 2 - Loading config file (hard coded since there will be one shared across environments)
$defaultconfig ="environments.csv"
$DefaultCSV=Import-Csv .\$defaultconfig

#Was anything specified for environment?
if($environment -eq "")
	{Write-host -f yellow "Deployment environment not specified. ";
	write "example:  Script_name.ps1 Test01"; 
	write "list of all available environments in the config."
	foreach($i in $DefaultCSV){write $i.environment};break}
else {"Executing script for $environment"}

#Testing if specified value exists in environments.
if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
	{"environment "+$environment+" not found in the $Defaultconfig"
	write "list of all available environments in the config."
	foreach($i in $DefaultCSV){write $i.environment};break}

#Finding values for correct environment.
$arrayposition=-1    
Foreach($i in $DefaultCSV){
$arrayposition++
if ($i.environment -eq $environment)
	{$EnvironmentServers= $i.Servers_in_Environment.split(";")
	$tokenproviderURL	= $i.Token_Provider_Url
	$CertName			= $i.Cert_Name
	$EndpointURL		= $i.End_Point_URL
	$App_Fabric_Cache	= $i.App_Fabric_Cache
	$App_Fabric_Hosts_a	= $i.App_Fabric_Hosts.split(";")
	$ADFSUrl			= $i.ADFS_Url
	$SSLThumbprint		= $i.SSLThumbprint
	$TrustURL			= $i.TrustURL
	$iisPfxcertname		= $i.PFXfilename
	$iisPfxCertPass		= $i.PFXPassword
	$arrayposition
		write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
	}



#Variables:
$scriptstartlocation=$pwd
##$SCOMscriptLocation=	"\\CHELAPPSCM35\AgentInstall\amd64\install_SCOMAgent-x64.cmd"
##$LocationOfdotNet40=	"\\CHELWBANGAT15\c$\cct_ops\"
##$LocationOfWebDeploy=	"\\CHELWBANGAT15\c$\cct_ops\"        # Location of webDeploy_2_10_amd64_en-US.msi

#Disable Firewall
{


                    "future disable firewall script goes here"
																}


# STEP 3 - install IIS
write-host -f cyan "Installing IIS"
Add-WindowsFeature File-Services,FS-FileServer,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors, Web-Http-Redirect,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Filtering,Web-Performance,Web-Stat-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Service,NET-Win-CFAC,NET-HTTP-Activation,NET-Non-HTTP-Activ,PowerShell-ISE #–restart
Remove-WindowsFeature Web-Includes,Web-CGI,Web-Basic-Auth,Web-Windows-Auth,Web-Digest-Auth,Web-Client-Auth,Web-Cert-Auth,Web-Url-Auth,Web-Dir-Browsing


# Step 3.1 - Disable SSL 2.0
DisableSSL20
## - Alex - 12/20/2012 - now consuming from common function
# if(!(test-path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server")){
	# pushd "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0"
	# new-item Server
	# new-itemproperty Server -Name Enabled  -Value 0 -Type DWORD
	# popd
# } Else {
	# if(-not((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server").enabled -eq 0)){
		# pushd "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0"
		# Set-itemproperty Server -Name Enabled  -Value 0 -Type DWORD
		# popd
		# }
	# }


# Step 3.2 - Disable EI ESC
Disable-InternetExplorerESC


# STEP 4 - Setup .Net 4.0
##################### may have to copy locally to supress prompt
#temp testing
$global:boolFramework4Installed = $false


#Confirm .Net Framework 4.0 is installed
## - Alex - 12/20/2012 - now consuming from common function
TestAndInstalldotNet40

# Write-Host -ForegroundColor Cyan "Checking to see if .Net Framework 4.0 is already installed."
# $arrFrameworks = (ls $Env:windir\Microsoft.NET\Framework | ? { $_.PSIsContainer -and $_.Name -match '^v\d.[\d\.]+' } | % { $_.Name.TrimStart('v') | sort })
# [string]$latestFramework = $arrFrameworks[-1]
    # if ($latestFramework -match '^4.[\d\.]+')
    # {
        # Write-Host -ForegroundColor Green "Latest version of .Net Framework is already 4.0"
        # Write-Host -ForegroundColor Green "Framework found: "$latestFramework
        #$global:boolFramework4Installed = $true
	# }
		# else
    # {
        # Write-Host -ForegroundColor Yellow ".Net Framework requires installation"; 
		#robocopy $LocationOfdotNet40  c:\cct_ops dotNetFx40_Full_x86_x64.exe
		#pushd c:\cct_ops

		# write-host -f cyan "Installing .NET 4.0 - process should take 5 to 10 minutes"
		# $dotNetlogfile="$pwd\dotNet4setup_$installtime.log"
		# $dotNetInstaller = "..\..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe"
		# $dotNetParams = '/q /norestart /log '+$dotNetlogfile
		# IF (!(TEST-PATH $dotNetInstaller)){
			# write-host -ForegroundColor Red ".Net 4.0 is not found at this location:  $dotNetInstaller"
			# break}
		# Start-Process $dotNetInstaller $dotNetParams -wait
		# write-host -ForegroundColor Green ".Net 4.0 Installed.  Log file located here: $dotNetlogfile"

    # }

# Register ASP.net
C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i



# STEP 5 - Install server level cert
write-host -f cyan "Installing Certs"

## - Alex - 12/20/2012 - now consuming from common function
# function certinstallloop ($certpassin, $certnamein){
	# $certout=certutil -f -importpfx -p $certpassin $certnamein
	#certutil -f -importpfx -p $iisPfxCertPass $iisPfxcertname
	# if($? -eq $false){write-host -f red "There was an error in installation of the cert:";"";return $certout;break
		# }else{
	# $certout=($certout | select -first 1).replace('" added to store.',"").replace('Certificate "',"")
	# Write-Host -ForegroundColor Green "Cert Installed"}
# return $certout}

# actually installing the cert. () are to display output instead of just processing it.
($iiscert=certinstallloop -certpassin $iisPfxCertPass -certnamein $iisPfxcertname)
# saving the cert name for setting up Voyager portion (mostly to assign ngat app pool to e:\ngat)
$iiscert | out-file c:\cct_ops\iis_cert.txt
Write-Host -ForegroundColor Green "Cert name saved to a local file in C:\cct_ops\iis_cert.txt"

# collect thumbprints for the certs.
write-host -f cyan "collect thumbprints for the certs."
($a=Get-ChildItem cert:\LocalMachine\MY | Where-Object {$_.Subject -eq $iiscert})



# STEP 6 - Assign IIS users & AppPools to cert
write-host -f cyan "Applying security to Cert"
	#username - ngat\apppool  - cant do NGAT app pool until NGAT is deployed.
$uname="IIS APPPOOL\DefaultAppPool"
$keyname=$a.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keypath="$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\"
	write-host -f cyan "before change"  #debug code
	icacls $keypath$keyname #debug code
write-host -f cyan "after change"
icacls $keypath$keyname /grant:r $uname":R"
icacls $keypath$keyname #debug code


# STEP 7 - Enable PS Remoting on system
write-host -f cyan "Enable PS Remoting on system"
pushd wsman::localhost\client 
Set-Item TrustedHosts * -Force
Set-Item AllowUnencrypted True -Force
Enable-PSRemoting -Force
test-wsman -ComputerName $env:computername -Authentication none
if ($? -eq $false){Write-Host "Enable PSRemoting failed."}
popd


# STEP 8 - Register system to CCT.Voyager SCOM
write-host -f cyan "Register CCT.Voyager SCOM"
REG ADD "HKLM\SOFTWARE\EXPSCOM\CCT\Voyager\Web Server" /f 


# \\CHELAPPSCM35\AgentInstall\amd64\install_SCOMAgent-x64.cmd	-	disabled for prod script
			# write-host "Install SCOM Agent"
			# cmd /c echo monkey>c.txt
				# $a ="cmd"
				# $b =" /c $SCOMscriptLocation < c.txt"
				# Start-Process $a $b -wait -nonewwindow
			# del c.txt



# Setup Web Deploy 2.0											-	disabled for prod script
			# write-host "Setting up Web Deploy tool"
			# robocopy $LocationOfWebDeploy c:\cct_ops "webDeploy_2_10_amd64_en-US.msi" 
			# pushd c:\cct_ops
			# $webdeploylog="$pwd\WebDeply_log_$installtime.txt"
			# msiexec /i $LocationOfWebDeploy /qr /norestart /lv $webdeploylog # change /qr to /quiet for fully remote deployment
			# if($? -eq $false)
				# {write-host -f red "There was an error in installation of the Web Deploy tool, please examine the log file: ";"";$webdeploylog;break
				# }else{"deployment complete, log available here:  $webdeploylog"}
			# net stop w3svc
			# net start w3svc




#Reboot required? 
## - Alex - 12/20/2012 - now consuming from common function
# Function RebootRequired{
   # $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $env:computername)
   # $key = $baseKey.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
   # $subkeys = $key.GetSubKeyNames()
   # $key.Close()
   # $baseKey.Close()

   # If ($subkeys | Where {$_ -eq "RebootPending"}) 
   # {
      # Write-Host "There is a pending reboot for" $env:computername
      # Restart-Computer -ComputerName $env:computername -confirm
   # }
   # Else 
   # {
      # Write-Host "No reboot is pending for" $env:computername
   # }
# }

# Testing if reboot is required
write-host -f cyan "Testing if reboot is required"
RebootRequired

