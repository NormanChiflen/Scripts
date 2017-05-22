# Remote deployment stuff
# If there are no credentials currently cached in the $CredPath below. The user will receive a windows popup to enter their creds. These will be stored in a securestring in the xml file.
# If the xml file exists in $CredPath, the script will decrypt the password and store it in $PWDclear
# To call this from another script, you need to dot source this script.

$CredPath = "~\creds.xml"

# Create a secure object and log into some server to execute the IIS config.
function Export-PSCredential {
	param ($currentusername=([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),
	$Credential = (Get-Credential -credential $currentusername), 
	$Path = $CredPath)
	
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
		$Path = $CredPath )

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

}

if (!(Test-Path $CredPath)) {
	Export-PSCredential
}
Import-PSCredential 
[string]$PWDclear = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Credential.password)))
