•	# The script requires the EWS managed API, which can be downloaded here:
# http://www.microsoft.com/downloads/details.aspx?displaylang=en&FamilyID=c3342fb3-fbcc-4127-becf-872c746840e1
# This also requires PowerShell 2.0
# Make sure the Import-Module command below matches the DLL location of the API.
# This path must match the install location of the EWS managed API. Change it if needed.
[string]$info = "White"                # Color for informational messages
[string]$warning = "Yellow"            # Color for warning messages
[string]$error = "Red"                 # Color for error messages
[string]$LogFile = "C:\Temp\Log.txt"   # Path of the Log File
function StampPolicyOnFolder($MailboxName)
{
    Write-host "Stamping Policy on folder for Mailbox Name:" $MailboxName -foregroundcolor  $info
    Add-Content $LogFile ("Stamping Policy on folder for Mailbox Name:" + $MailboxName)
    #Change the user to Impersonate
    $service.ImpersonatedUserId = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$MailboxName);
    #Search for the folder you want to stamp the property on
    $oFolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(1)
    $oSearchFilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,$FolderName)
    #Uncomment the line below if the folder is in the regular mailbox
    #$oFindFolderResults = $service.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$oSearchFilter,$oFolderView)
    #Comment the line below and uncomment the line above if the folder is in the regular mailbox
    $oFindFolderResults = $service.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::ArchiveMsgFolderRoot,$oSearchFilter,$oFolderView)
    if ($oFindFolderResults.TotalCount -eq 0)
    {
         Write-host "Folder does not exist in Mailbox:" $MailboxName -foregroundcolor  $warning
         Add-Content $LogFile ("Folder does not exist in Mailbox:" + $MailboxName)
    }
    else
    {
        Write-host "Folder found in Mailbox:" $MailboxName -foregroundcolor  $info
        #PR_POLICY_TAG 0x3019
        $PolicyTag = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x3019,[Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Binary);
        #PR_RETENTION_FLAGS 0x301D    
        $RetentionFlags = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x301D,[Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer);
        
        #PR_RETENTION_PERIOD 0x301A
        $RetentionPeriod = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x301A,[Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer);
        #Bind to the folder found
        $oFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$oFindFolderResults.Folders[0].Id)
       
        #Same as the value in the PR_RETENTION_FLAGS property
        $oFolder.SetExtendedProperty($RetentionFlags, 137)
        #Same as the value in the PR_RETENTION_PERIOD property
        $oFolder.SetExtendedProperty($RetentionPeriod, 1095)
        #Change the GUID based on your policy tag
        $PolicyTagGUID = new-Object Guid("{92186ff7-7f4d-4efa-a09b-bbdc5aee3908}");

        $oFolder.SetExtendedProperty($PolicyTag, $PolicyTagGUID.ToByteArray())
        $oFolder.Update()

        Write-host "Retention policy stamped!" -foregroundcolor $info
        Add-Content $LogFile ("Retention policy stamped!")
    
    }    

    $service.ImpersonatedUserId = $null
}
#Change the name of the folder. This is the folder the properties will be stamped on.
$FolderName = "My Folder"
Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\1.1\Microsoft.Exchange.WebServices.dll"

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2010_SP1)
# Set the Credentials
$service.Credentials = new-object Microsoft.Exchange.WebServices.Data.WebCredentials("UserName","Password","Domain")
# Change the URL to point to your cas server
$service.Url= new-object Uri(http://YOUR-CAS-SERVER/EWS/Exchange.asmx)
# Set $UseAutoDiscover to $true if you want to use AutoDiscover else it will use the URL set above
$UseAutoDiscover = $false
#Read data from the UserAccounts.txt.
#This file must exist in the same location as the script.

import-csv UserAccounts.txt | foreach-object {
    $WindowsEmailAddress = $_.WindowsEmailAddress.ToString()

    if ($UseAutoDiscover -eq $true) {
        Write-host "Autodiscovering.." -foregroundcolor $info
        $UseAutoDiscover = $false
        $service.AutodiscoverUrl($WindowsEmailAddress)
        Write-host "Autodiscovering Done!" -foregroundcolor $info
        Write-host "EWS URL set to :" $service.Url -foregroundcolor $info

    }
    #To catch the Exceptions generated
    trap [System.Exception] 
    {
        Write-host ("Error: " + $_.Exception.Message) -foregroundcolor $error;
        Add-Content $LogFile ("Error: " + $_.Exception.Message);
        continue;
    }
    StampPolicyOnFolder($WindowsEmailAddress)
} 
