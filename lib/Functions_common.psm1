#C:\Windows\System32\WindowsPowerShell\v1.0\Modules\ Functions 
# import-module .\modules.psm1
#Import-Module C:\Users\mcraig\Downloads\Pscx-2.0.0.1\Pscx\Pscx.psm1

######################################
#       Module Scope Variables       #
######################################
[DateTime]$script:__startTime=get-date
[String]$script:__logPath
[String]$script:__htmllogpath
[String]$script:__logXSLTPath="$PSScriptRoot\BuildReport.xslt"

function EnvironmentPrep{

    # STEP 1 - Environment setup.
    write-host -f Magenta "Environment setup.";""
    write-host -f cyan "Testing if User is an administrator...." -nonewline
    
    $a=Test-Administrator
    write-host -f cyan $a
    if($a -ne "True"){ 
        Write-host -ForegroundColor Red "Please run as Administrator";break}
        
    # Time executiong of the script started - for unique logging per script execution
    $global:installtime=get-date -uformat "%Y_%h_%d_%H_%M"
    $global:scriptexecutedfrom=$pwd

    # Is execution policy set to restricted? Attempt to set 
    write-host -f cyan "Testing execution policy."
    
    try {Set-ExecutionPolicy Bypass -scope localmachine -force}
    catch { Write-host -f red "Unable to set Execution Policy"
    "Current exec policy is $(Get-ExecutionPolicy). Please change remote policy to allow this script to run by executing *set-executionpolicy bypass*"}
    # If execution policy is set to prevent execution, script wont run in the first place, preventing testing of execution poliy
    #$a=Get-ExecutionPolicy
    #if ($a -ne "Unrestricted"){write-host  -ForegroundColor Red "ExecutionPolicy = $a. Please change remote policy to allow this script to run by executing set-executionpolicy unrestricted"
    #break}
    
    ImportSystemModules
    #Functoin notes $installtime and $scriptexecutedfrom are available for global consumption
    }

function Set-ExecutionPolicyUnrestricted{
    # Is execution policy set to restricted? Attempt to set 
    write-host -f cyan "Testing execution policy."
    try {Set-ExecutionPolicy Bypass -scope localmachine -force}
    catch { "Unable to set Execution Policy"}
}
function Test-Administrator{
    $user = [Security.Principal.WindowsIdentity]::GetCurrent() 
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

# function LoadAllModules{
    #load system modules
    # Get-Module -listavailable| foreach{write-host -ForegroundColor Cyan loading $_.name; Import-Module $_.name -global}
    # }

function InstallIIS-SetDefaultConfiguration{
    Add-WindowsFeature File-Services,FS-FileServer,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors, Web-Http-Redirect,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Filtering,Web-Performance,Web-Stat-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Service,NET-Win-CFAC,NET-HTTP-Activation,NET-Non-HTTP-Activ,PowerShell-ISE #–restart
    Remove-WindowsFeature Web-Includes,Web-CGI,Web-Basic-Auth,Web-Windows-Auth,Web-Digest-Auth,Web-Client-Auth,Web-Cert-Auth,Web-Url-Auth,Web-Dir-Browsing


}

function DisableIISLogging{
    # Disable IIS Logging
    new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force
    
    appcmd set config /section:httpLogging /dontLog:True
    
}

function MoveIISLogging([string]$Logroot){
    # Set IIS Logging defaults to new location - Changes %SystemDrive%\logs\LogFiles to $Logroot\logs\LogFiles 
    Set-WebConfigurationProperty '/system.applicationHost/log/centralBinaryLogFile' -PSPath IIS:\ -Name directory -Value (Get-WebConfigurationProperty '/system.applicationHost/log/centralBinaryLogFile' -PSPath IIS:\ -Name directory).Value.Replace('%SystemDrive%', $logroot)
    Set-WebConfigurationProperty '/system.applicationHost/log/centralW3CLogFile' -PSPath IIS:\ -Name directory -Value (Get-WebConfigurationProperty '/system.applicationHost/log/centralW3CLogFile' -PSPath IIS:\ -Name directory).Value.Replace('%SystemDrive%', $logroot)
    Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logFile' -PSPath IIS:\ -Name directory -Value (Get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logFile' -PSPath IIS:\ -Name directory).Value.Replace('%SystemDrive%', $logroot)
    if (!(test-path (get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logFile' -PSPath IIS:\ -Name directory).Value)) { md (get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logFile' -PSPath IIS:\ -Name directory).Value }

}


## Need to define inputs to function ##
function Example-MoveIISSiteLogging
{
    # Configure IIS Logpath
    [string]$LogPath="$logroot\logs\LogFiles\Default Web Site"
    (set-WebConfigurationProperty "/system.applicationHost/sites/site[@name='Default Web Site']/logFile" -PSPath IIS:\ -Name Directory).Value=$LogPath  
    if (!(test-path $LogPath)) { md $LogPath }
    
    # configure IIS Logpath for CustomerInteractionDataService web site
    [string]$LogPath="$logroot\logs\LogFiles\$WebAppName\$WebVDirName"
    set-WebConfigurationProperty "/system.applicationHost/sites/site[@name='$WebAppName']/logFile" -PSPath IIS:\ -Name Directory -Value $LogPath
    if (!(test-path $LogPath)) { md $LogPath }


}

function ReplaceString($workingVar,$StringMatch,$StringNew){
        foreach($i in $workingVar)
        {$i.replace($StringMatch,$StringNew)
            #write-host -f cyan "replaced" $StringMatch to `"$StringNew `"
        }   
    #return $workingVar
    }


function TestHotfix ($hotfix, $HotfixinstallPath, $logroot){
        LogMessage "info" "Testing for $hotfix"
        if(!(hotfix | ?{$_ -match $hotfix})){
            LogMessage "warn" "$hotfix is not installed"
            LogMessage "warn" "the patch MUST be installed for Voyager to function... Attempting to install"
            LogMessage "info" "patches should be placed here: 1986:://sait/DeploymentAutomation/bin/hotfixes/"
            wusa $HotfixinstallPath\$hotfix  /quiet /log:$logroot_$hotfix.log
            if($? -eq $True){LogMessage "info" "Hotfix $hotfix installed"
                } Else {
                    LogMessage "warn" "There was an error istalling the hotfix"
                    LogMessage "warn" "Logs available here: $logroot_$hotfix.log"
                    LogMessage "warm" "Printing Log"
                    gc $logroot_$hotfix.log
                    }
        }else{
            LogMessage "info" "No problems detected. Moving to next step..."
        }
    }

Function DisableSSL20{
    if(!(test-path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"))
    {
        pushd "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0"
        new-item Server
        new-itemproperty Server -Name Enabled  -Value 0 -Type DWORD
        popd
    } Else {
        if(-not((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server").enabled -eq 0))
            {
            pushd "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0"
            Set-itemproperty Server -Name Enabled  -Value 0 -Type DWORD
            popd
            }
        }
    }

    
Function TestAndInstalldotNet40{
    Write-Host -ForegroundColor Cyan "Checking to see if .Net Framework 4.0 is already installed."
    $arrFrameworks = (ls $Env:windir\Microsoft.NET\Framework | ? { $_.PSIsContainer -and $_.Name -match '^v\d.[\d\.]+' } | % { $_.Name.TrimStart('v') | sort })
    [string]$latestFramework = $arrFrameworks[-1]
    if ($latestFramework -match '^4.[\d\.]+')
        {
            Write-Host -ForegroundColor Green "Latest version of .Net Framework is already 4.0"
            Write-Host -ForegroundColor Green "Framework found: "$latestFramework
            #$global:boolFramework4Installed = $true
        }
            else
        {
            if (!(test-path c:\cct_ops)){md c:\cct_ops}

            Write-Host -ForegroundColor Yellow ".Net Framework requires installation"; 
            write-host -f cyan "Installing .NET 4.0 - process should take 5 to 10 minutes"
            if (TEST-PATH "\\chelappsbx001.karmalab.net\d$\apps\dotNet4.0Redist\dotNetFx40_Full_x86_x64.exe") {
                $dotNetInstaller="\\chelappsbx001.karmalab.net\d$\apps\dotNet4.0Redist\dotNetFx40_Full_x86_x64.exe"
            }ELSEIF (TEST-PATH "\\chelappsbx001.karmalab.net\Public\FileShare\dotNet4.0Redist\dotNetFx40_Full_x86_x64.exe"){
                $dotNetInstaller="\\chelappsbx001.karmalab.net\Public\FileShare\dotNet4.0Redist\dotNetFx40_Full_x86_x64.exe"
            }ELSEIF (TEST-PATH "..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe" ) {
                $dotNetInstaller="..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe"
            }ELSEIF (TEST-PATH "..\..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe" ) {
                $dotNetInstaller="..\..\bin\hotfixes\dotNetFx40_Full_x86_x64.exe"
            }ELSEIF (TEST-PATH "dotNetFx40_Full_x86_x64.exe") {
                $dotNetInstaller="dotNetFx40_Full_x86_x64.exe"
            }ELSEIF (!(Test-Path variable:dotNetinstaller)){
                throw "Can not locate dotNetFx40_Full_x86_x64.exe"}

            ##copy $dotNetInstaller c:\cct_ops -force
            
            ##pushd c:\cct_ops
            ##$installer_name= split-path $dotNetInstaller -leaf
            $dotNetlogfile = "$pwd\dotNet4setup_$installtime"
            $dotNetParams  = "/q /norestart /log $dotNetlogfile"
            Start-Process $dotNetInstaller $dotNetParams -wait -nonewwindow
            ##Start-Process -filepath $installer_name -argumentlist $dotNetParams -wait -nonewwindow
            write-host -ForegroundColor Green ".Net 4.0 Installed.  Log file located here: $dotNetlogfile.html"
            ##popd
            
            # Register ASP.net
            Write-host "Registering APT.net"
            C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i

        }
    }

Function TestAndInstall_MVC20{
	$mvc2Installer="\\chelappsbx001.karmalab.net\Public\FileShare\dotNetRedist\AspNetMVC2_VS2008.exe"
    
	Write-Host -ForegroundColor Cyan "Checking to see if MVC 2.0 is installed."
    
	$isInstalled = $False
	
	if (test-path "C:\Program Files (x86)\Microsoft ASP.NET\ASP.NET MVC 2") { $isInstalled="True"}
	if (test-path "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\ItemTemplates\CSharp\Web\MVC 2") { $isInstalled="True"}

	if ($isInstalled -eq $False) {
		if (!(test-path $mvc2Installer)) {write-error "MVC 2.0 must be installed. Binary is available at $mvc2Installer"}
	
		Start-Process $mvc2Installer -wait
	
	}
	return $isInstalled
}
	
	
function certinstallloop ($certpassin, $certnamein){
    $certout=certutil -f -importpfx -p $certpassin $certnamein
    #certutil -f -importpfx -p $iiscertpass $iiscertname
    if($? -eq $false){
            write-host -f red "There was an error in installation of the cert:";""
            return $certout
            break
        }else{
            $certout=($certout | select -first 1).replace('" added to store.',"").replace('Certificate "',"")
            Write-Host -ForegroundColor Green "Cert Installed"
        }
    return $certout
    }


Function EnablePSRemoting{

    Enable-WSManCredSSP -Role Client -DelegateComputer '*' –Force 
    Enable-WSManCredSSP -Role Server –Force
    gpupdate
        
    write-host -f cyan "Enable PS Remoting on system"
    pushd wsman::localhost\client 
    Set-Item TrustedHosts * -Force
    Set-Item AllowUnencrypted True -Force
    Enable-PSRemoting -Force

    #test-wsman -ComputerName $env:computername -Authentication none
    if ($? -eq $false){Write-Host "Enable PSRemoting failed."}
    popd
    }

Function EnableExtendedHTTPErrAttributes{

    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name ErrorLoggingFields -Value 0x7dff4e7 -type DWord
}

Function RebootRequired($ForceReboot="False"){
   $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $env:computername)
   $key = $baseKey.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
   $subkeys = $key.GetSubKeyNames()
   $key.Close()
   $baseKey.Close()

   If (($subkeys | Where {$_ -eq "RebootPending"}) -or ($ForceReboot -ne "False")) 
   {
      Write-Host "There is a pending reboot for" $env:computername
      Restart-Computer -ComputerName $env:computername -confirm
   }
   Else 
   {
      Write-Host "No reboot is pending for" $env:computername
   }
}

function Export-PSCredential {
    param ($currentusername=([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),
    $Credential = (Get-Credential -credential $currentusername), 
    $Path = "c:\cct_ops\"+$currentusername.replace("\","_")+"_encrypted_creds.xml")

    # Look at the object type of the $Credential parameter to determine how to handle it
    #switch ( $Credential.GetType().Name ) {
        # It is a credential, so continue
    #   PSCredential        { continue }
        # It is a string, so use that as the username and prompt for the password
    #   String              { $Credential = Get-Credential -credential $Credential }
        # In all other caess, throw an error and exit
    #   default             { Throw "You must specify a credential object to export to disk." }
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


Function LoadADFSplugin{
        if ( (Get-PSSnapin -Name Microsoft.Adfs.PowerShell -ErrorAction SilentlyContinue) -eq $null )
        {write-host -f cyan "loading Microsoft.Adfs.PowerShell"
        Add-PsSnapin Microsoft.Adfs.PowerShell
        }
    }

Function CreateLogrootShare($Logroot){
        IF (!(TEST-PATH $logroot)){MD $logroot}
        
        if ((Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path -eq $null) {
            write-warning 'Missing a Logroot Folder. Creating a Logroot folder, and map share as \\ServerName\logroot'
            If (!(TEST-PATH $logroot)){MD $logroot} 
            If(!(test-path \\$env:computername\logroot)) {
                net share logroot=$logroot
            }
            
        }else{
            $logroot=(Get-WmiObject Win32_Share -filter "Name LIKE 'LOGROOT'").path
        }
        
        
        
}
Function CreateLogFilePath([string]$BuildLabel, [string]$ServerName, [string]$Environment, [string]$LogFolder){
        IF (!(TEST-PATH $LogFolder)){md $LogFolder}
        
        CreateLogrootShare $LogFolder
        
        $logStart="" + $__startTime.Year + "_" + $__startTime.Month + "_" + $__startTime.Day + "_" + $__startTime.Hour + "_" + $__startTime.Minute + ""
        [string]$LogPath="" + $LogFolder + "\" + $ServerName + "_" + $BuildLabel + "_" + $logStart + ".xml"

        $script:__logPath=$LogFolder + "\" + $ServerName + "_" + $BuildLabel + "_" + $logStart + ".xml"
        $script:__logPath
        
        GenerateLogFile "$BuildLabel" "$ServerName" "$Environment"

}
    
Function GenerateLogFile([string]$BuildLabel, [string]$ServerName, [string]$Environment){

        $UserName=([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        $doc = New-Object -TypeName xml
        $el = $doc.CreateElement("BuildInstall")
        [void]$doc.AppendChild($el)
        
        $root = $doc.DocumentElement
        $root.SetAttribute("BuildLabel", $BuildLabel)
        $root.SetAttribute("ServerName", $ServerName)
        $root.SetAttribute("Environment", $Environment)
        $root.SetAttribute("StartTime", $script:__startTime.ToString("s"))
        $root.SetAttribute("InstalledBy", $UserName)
        
        $node=$doc.CreateElement("InstallLog")
        [void]$doc.BuildInstall.AppendChild($node)
        $doc.save($script:__logPath)
        
    }

Function LogMessage([string]$Type, $Message,[string]$Time=(Get-Date -format s)){
        
        $outMessage
        if ($Message -is [system.array]){
            foreach ($a in $Message) { 
                write-host "$a `n"
                $outMessage += "$a `n"
                }
        }else{
            $outMessage = $Message.ToString()
            Write-Host "$Time: $outMessage"
        }
        
        [xml]$doc= gc $script:__logPath
        
        $xml = $doc.SelectSingleNode("//InstallLog")
        $node = $doc.CreateElement("entry")
        [void]$xml.AppendChild($node)
        $node.SetAttribute("type", $Type)
        $node.SetAttribute("message", $outMessage)
        $node.SetAttribute("time", $Time)

        $doc.Save($script:__logPath)
        
        #I am not sure why the switch is here. Is it for future functionality?
        switch ($Type) {
        info{;break}
        warn{;break}
        error{  
                CloseLogFile 
                #CloseLogFile "deployment on $env:computername broke"
                #amail "$env:username@expedia.com" $("$env:username@expedia.com","cctrel@expedia.com") "deployment on $env:computername broke"  $((GenericMailBody) + $outMessage)
                amail "$env:username@expedia.com" $("$env:username@expedia.com") "deployment on $env:computername broke"  $((GenericMailBody) + $outMessage)
                throw $outMessage
                break}
        default{Write-Error -Exception "LogMessage type must be: info, warn, error" -Category InvalidArgument;break }
        }

    }
        
Function CloseLogFile($EmailSubject="Deployment on $env:computername finished successfully", $bodyPlus,[string]$StopTime=(Get-Date -format s)){
        
        [xml]$doc = Get-Content $script:__logPath
        $root = $doc.DocumentElement
        $root.SetAttribute("StopTime", $StopTime)
        $doc.Save($script:__logPath)
        transformXMLLog

        #email stuff is here to send email in case of failures inside LogMessage
        #$body = GenericMailBody
        #$body += $bodyPlus
        #amail "$env:username@expedia.com" "$env:username@expedia.com" $EmailSubject $body

        }
        
function getStartTime([string]$timeFormat){
    return $script:__startTime.ToString($timeFormat)
    }
    
function setStartTime([DateTime]$time){
    $script:__startTime = $time
    }

function getLogFilePath(){
    return $script:__logPath
    }

function getLogFilePathHtml(){
    return $script:__htmllogpath
    }

function transformXMLLog($xmlFilePath=$script:__logPath, $xslFilePath=$script:__logXSLTPath, [string]$outputFilePath=$script:__logPath){
    # "script:__logPath $script:__logPath"
    # "script:__logXSLTPath $script:__logXSLTPath"
    # "outputFilePath $outputFilePath"
    
    $outputFilePath=$outputFilePath.replace(".xml",".html")
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xslFilePath)
    $xslt.Transform($xmlFilePath, $outputFilePath)
    $script:__htmllogpath = $outputFilePath

    }

Function GenericMailBody{
        $a=getLogFilePathHtml
        $a=$a -Replace('.:\\LOGROOT\\', "\\$env:computername\logroot\")
        $emailbody  = '<a href="'+$a+'">'+$a + "</a><br>"
        $emailbody += '<a href="'+"https://$env:computername.karmalab.net/Version.txt" +'">'+"http://$env:computername.karmalab.net/Version.txt"        + "</a><br><br>"
        $emailbody += 'New Web.config:               <a href="'+"\\$env:computername\ngat\web.config"   +'">'+"\\$env:computername\ngat\web.config"     + "</a><br>"
        $emailbody += '<i>Additional output if any:</i><br><br>'
        $emailbody
        }

Function MailBodyADFS{
        $a=getLogFilePathHtml
        $a=$a -Replace('.:\\LOGROOT\\', "\\$env:computername\logroot\")
        $emailbody  = '<a href="'+$a+'">'+$a + "</a><br>"
        $emailbody += '<a href="'+"https://$env:computername.karmalab.net/adfs/ls/Version.txt" +'">'+"https://$env:computername.karmalab.net/adfs/ls/Version.txt"       + "</a><br><br>"
        $emailbody += 'New Web.config:               <a href="'+"\\$env:computername\webroot\ls\web.config" +'">'+"\\$env:computername\webroot\ls\web.config"       + "</a><br>"
        $emailbody += 'Tee command output:           <a href="'+"\\$env:computername\logroot\install"+'">'+"\\$env:computername\logroot\install"    + "</a><br><br><br>"
        $emailbody += '<i>Additional output if any:</i><br><br>'
        $emailbody
        }
        
function amail ($from, $mailto, $subject, $body, $smtpHost = "chelsmtp01.karmalab.net", $attachment){
    $email = New-Object System.Net.Mail.MailMessage
    $email.IsBodyHtml = $true
    $email.From = $from
    $mailto | foreach {$email.To.Add($_)}
    #-old email string to single recepient- $email.To.Add($to)
    $email.Subject = $subject
    $email.Body = $body
    if ($attachment){$email.attachments.add($attachment)}
    $DnsDomain = (Get-WmiObject Win32_ComputerSystem).domain
    
    # try {
        # Send the mail for the LAB
        # $client = New-Object System.Net.Mail.SmtpClient $smtpHost
        # $client.UseDefaultCredentials = $true
        # $client.Send($email)
        # }
    # catch {
        # Send the mail for the Prod
        # $email.To.Add("rjones@expedia.com")
        # $smtpHost = "chsmtp.expeso.com"
        # $client = New-Object System.Net.Mail.SmtpClient $smtpHost
        # $client.UseDefaultCredentials = $true
        # $client.Send($email)
        # }
    # throws errors because logmessage doesnt work by its self.
    #finally {if(test-path function:LogMessage){LogMessage "info" "Mail sent: from - $from `n  to - $mailto `n  subject - $subject `n  SMTP server used - $smtpHost `n"}
    #   }
    switch ($DnsDomain) {
        {$_ -match "expeso.com"}{
            "entering prod"
            $email.To.Add("rjones@expedia.com")
            $smtpHost = "chsmtp.expeso.com"
            $client = New-Object System.Net.Mail.SmtpClient $smtpHost
            $client.UseDefaultCredentials = $true
            $client.Send($email)
            break}
        {$_ -match "karmalab.net"}{
            "entering karmalab"
            $client = New-Object System.Net.Mail.SmtpClient $smtpHost
            $client.UseDefaultCredentials = $true
            $client.Send($email)
            break}
        {$_ -match "CORP.EXPECN.com"}{
            "entering sea"
            $smtpHost = "shost.sea.corp.expecn.com"
            $client = New-Object System.Net.Mail.SmtpClient $smtpHost
            $client.UseDefaultCredentials = $true
            $client.Send($email)
            break}
        }
    }


function InstallLocalbin{
        $ToolsStorage   = "\\CHELWEBE2ECCT34\localbin"
        dir $toolsstorage | %{if(!(Test-Path ("c:\localbin\$_"))){"copying $_";copy $_.fullname c:\localbin -recurse}}
        if (!($env:path -like "*c:\localbin*")){"adding Localbin to path";setx /m path "c:\localbin;$env:path"}
    }


function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Enable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green
}

function Disable-UserAccessControl {
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
    Write-Host "User Access Control (UAC) notification has been disabled." -ForegroundColor Green
    }

function BackupWebSiteConfiguration([string]$WebSiteName, [string]$BackupDirectory){
    #In Use by:
    #   CustomerInteractionDataService_webservice_install.ps1
    
    # Back up Site, VDir, and appPool configuration
    # If WebSiteName\$WebAppName\WebVDirname exists, perform the export
    new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force
    
    if (!(test-path $BackupDirectory)) { MD $BackupDirectory }
    $BackupSiteXML = $BackupDirectory + '\' + $WebSiteName + '.site.xml'
    
    # Test if site exists
    if(Test-Path "IIS:\Sites\$WebSiteName"){ 
        #Export WebSite
        appcmd list site $WebSiteName /config /xml > $BackupSiteXML 

        #Convert file to text and import to new variable - output of appcmd is unicode and will fail to load to xml object
        $a= cat $BackupSiteXML 
        $xdoc = new-object System.Xml.XmlDocument
        $xdoc.LoadXml($a)

        #find all nodes where applicationPool are declared
        $nodes=$xdoc.SelectNodes('//application[@applicationPool]')

        #Loop through each node and export configuration info to an xml file named after appPool
        $nodes | %{
        $txt=appcmd list apppool $_.applicationPool /config /xml
        $txtfile = $BackupDirectory + '\' + $_.applicationPool + '.apppool.xml'
        $txt > $txtfile
        }
        return 1 #Success
    }else{
        return 0 #Fail
        }
}

# pciCompliance: Disable the return of the .net version header
# https://jira/jira/browse/IT-17511
function set_enableVersionHeader_false(){
    new-alias -name appcmd -value "$env:windir\system32\inetsrv\APPCMD.exe" -force
    appcmd set config  -section:system.web/httpRuntime /enableVersionHeader:"False"  /commit:webroot
}

# Return list of environments from CSV
function getEnvironments($EnvCSV){
    $return=@($EnvCSV | %{$_.environment})
    return $return
}
    
function test() {
[String]$script:__logXSLTPath
#$myinvocation | gm
$myinvocation.CommandOrigin
$myinvocation.Equals
$myinvocation.GetHashCode
$myinvocation.GetType
$myinvocation.ToString
$myinvocation.BoundParameters
$myinvocation.CommandOrigin
$myinvocation.ExpectingInput
$myinvocation.HistoryId
$myinvocation.InvocationName
$myinvocation.Line
$myinvocation.MyCommand
$myinvocation.OffsetInLine
$myinvocation.PipelineLength
$myinvocation.PipelinePosition
$myinvocation.PositionMessage
$myinvocation.ScriptLineNumber
$myinvocation.ScriptName
$myinvocation.UnboundArguments
}

# SIG # Begin signature block
# MIIGBwYJKoZIhvcNAQcCoIIF+DCCBfQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvzyPXD5rYmh6DrKY6QqFNOaC
# uDagggQpMIIEJTCCA46gAwIBAgIQZYCiv3KRDoNH6gz2dQW5izANBgkqhkiG9w0B
# AQUFADAUMRIwEAYDVQQDDAlzaWduLXRlc3QwHhcNMTMwNDE3MDIxMzQ0WhcNMTQw
# NDE3MDIzMzQ0WjAUMRIwEAYDVQQDDAlzaWduLXRlc3QwgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBANQZDvA+Logv3V503oiAhUBXEILTYRl6PxL6J6Zi/3vIhQpF
# 7vn+1jgR2n1LlAYeHLdw6MqID+6V13Na4jzjDDm/+tfd9kO4oV40tjwZkos51CbJ
# ZC7OutbuQe97qcd43eBhsR40SwpIssSozYBPXgB+19c8+Fm/dqhOu4tAbBdBAgMB
# AAGjggJ2MIICcjA8BgkrBgEEAYI3FQcELzAtBiUrBgEEAYI3FQiCydcuwvhugt2X
# NYSgtwCH5PcmOoO63BSE7Nx3AgFkAgEEMA4GA1UdDwEB/wQEAwIFoDAoBgNVHSUE
# ITAfBggrBgEFBQcDAQYIKwYBBQUHAwMGCWCGSAGG+EIBATA0BgkrBgEEAYI3FQoE
# JzAlMAoGCCsGAQUFBwMBMAoGCCsGAQUFBwMDMAsGCWCGSAGG+EIBATAdBgNVHQ4E
# FgQU/ieVq6bAOt7L+Sjv7P03vYtKhzkwIgYKKwYBBAGCNwoLCwQUcwBpAGcAbgAt
# AHQAZQBzAHQAAAAwgYgGCisGAQQBgjcKCxoEegZ2AAAhAAAAQwBIAEMALQBTAFYA
# QwBQAEsASQAwADEALgBTAEUAQQAuAEMATwBSAFAALgBFAFgAUABFAEMATgAuAGMA
# bwBtAAAAFAAAAEUAeABwAGUAZABpAGEAIABJAG4AdABlAHIAbgBhAGwAIAAxAEMA
# AAAAAAAAMIHzBgorBgEEAYI3CgtXBIHkAAAAAAAAAAACAAAAIAAAAAIAAABsAGQA
# YQBwADoAAAB7ADQAQQA5ADAANABFAEQAMwAtAEYAOAAzADEALQA0ADMANAA2AC0A
# OABBADEAMgAtADEAMAA1AEYAQwAzADYANQA1ADkAQwAzAH0AAABDAEgAQwAtAFMA
# VgBDAFAASwBJADAAMQAuAFMARQBBAC4AQwBPAFIAUAAuAEUAWABQAEUAQwBOAC4A
# YwBvAG0AXABFAHgAcABlAGQAaQBhACAASQBuAHQAZQByAG4AYQBsACAAMQBDAAAA
# MwAwADIAMQA0AAAAMA0GCSqGSIb3DQEBBQUAA4GBAHBVsL90xsFGcxXMdp1RMFB/
# vgLsBeE86keu0HSGh0z8NRN+GNV6NPL+dy2Qr4S57Sufrn31QLUBHmR0bCjGLKYq
# mZ+kjtClT5JjHGM9fzp7aFKxDmuHxpfRIJ9gwcC7sn96KO6QYGMN/WF9ilTT5Vlr
# ghi1YR8xatnL7UZ3YY98MYIBSDCCAUQCAQEwKDAUMRIwEAYDVQQDDAlzaWduLXRl
# c3QCEGWAor9ykQ6DR+oM9nUFuYswCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPw26EkVkQfSQMK/
# kcyR5RAcbIvbMA0GCSqGSIb3DQEBAQUABIGApy8sNXstIusuzafL2fL5/7tk+MFg
# bTmMoexkYfoneX3Gh1dVDhgcdDNj5KdH4zxcCffBofo1wTTi0TsyuFXPc6jqoW9n
# f8HE8wdlh7eZl91ynev6yGXKmxry5ijftyJz0YW1vuHpBVy/7Iqa9bY+5KLE+g7v
# K1LnIVdd9ssONWU=
# SIG # End signature block
