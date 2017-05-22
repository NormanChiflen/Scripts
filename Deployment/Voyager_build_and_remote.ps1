#Remote deployment stuff


Write-host -f cyan "";"";"";"              script not implemented";break

$targetserver = "CHELWBANGAT11"

$cctshare="c:\cct_ops"
IF (!(TEST-PATH $cctshare)){MD $cctshare}
pushd \\$targetserver\c`$
IF (!(TEST-PATH $cctshare)){MD $cctshare}

#copy deployment tools locally to avoid remote script problems
robocopy  \\CHELAPPSBX001\Public\ngatIISdeploymentAutomation \\$targetserver\c$\cct_ops /E /XA:H /PURGE /XO /NDL /NC /NS /NP


#Creating a build 
#msbuild ngat.msbuild /t:buildcore

# Copy build to a staging location.
#robocopy D:\Deployment\Depot\sait\CRM\projects\NGAT\builds\retail \\$targetserver\ngatroot *.* /E /XA:H /PURGE /XO /XD ".svn" /NDL /NC /NS /NP



# Create a secure object and log into some server to execute the IIS config.
function Export-PSCredential {
	param ($currentusername=([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),
	$Credential = (Get-Credential -credential $currentusername), 
	$Path = "c:\cct_ops\"+$currentusername.replace("\","_")+"_encrypted_creds.xml")

	# Look at the object type of the $Credential parameter to determine how to handle it
	#switch ( $Credential.GetType().Name ) {
		# It is a credential, so continue
	#	PSCredential		{ continue }
		# It is a string, so use that as the username and prompt for the password
	#	String				{ $Credential = Get-Credential -credential $Credential }
		# In all other caess, throw an error and exit
	#	default				{ Throw "You must specify a credential object to export to disk." }
	#}
	
	# Create temporary object to be serialized to disk
	$export = "" | Select-Object Username, EncryptedPassword
	
	# Give object a type name which can be identified later
	$export.PSObject.TypeNames.Insert(0,’ExportedPSCredential’)
	
	$export.Username = $Credential.Username

	# Encrypt SecureString password using Data Protection API
	# Only the current user account can decrypt this cipher
	$export.EncryptedPassword = $Credential.Password | ConvertFrom-SecureString

	# Export using the Export-Clixml cmdlet
	$export | Export-Clixml $Path
	Write-Host -foregroundcolor Green "Credentials saved to: " -noNewLine

	# Return FileInfo object referring to saved credentials
	Get-Item $Path
}

function Import-PSCredential {
	
	param ($currentusername=([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),
		$Path = "c:\cct_ops\"+$currentusername.replace("\","_")+"_encrypted_creds.xml" )

	# Import credential file
	$import = Import-Clixml $Path 
	
	# Test for valid import
	if ( !$import.UserName -or !$import.EncryptedPassword ) {
		Throw "Input is not a valid ExportedPSCredential object, exiting."
	}
	$Username = $import.Username
	
	# Decrypt the password and store as a SecureString object for safekeeping
	$SecurePass = $import.EncryptedPassword | ConvertTo-SecureString
	
	# Build the new credential object
	$global:Credential = New-Object System.Management.Automation.PSCredential $Username, $SecurePass
	Write-Output $Credential; "Credentials are accessible via `$Credential variable"
}

Export-PSCredential
Import-PSCredential 
# -for using windows authentication - $mycreds = New-Object System.Management.Automation.PSCredential ("username", (new-object System.Security.SecureString)) 
#$password_file="c:\cct_ops\$env:username"+"_password.txt"
#if (!(Test-Path $password_file)){read-host -assecurestring "Password file not found, Please enter password which will be stored as encrypted string here: $password_file" | convertfrom-securestring | out-file $password_file}


$targetserver = "CHELWBANGAT06"
Enter-PSSession -ComputerName $targetserver -credential $Credential
Set-ExecutionPolicy unrestricted -scope localmachine -force





#copy Voyager deployment folder locally.
#Execute server prep
#Execute Voyager deployment