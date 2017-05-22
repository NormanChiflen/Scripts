#==========================================================================
# NAME: GetServiceAndTaskAccounts.ps1
#
# AUTHOR: Stephen Wheet 
# Version: 2.0
# Date: 7/21/10
#
# COMMENT: 
#	This script was created to find out which any which services on any of
#   the servers are running as domain accounts.  It will ignore local
#   accounts
#
#   Version 2: Added grabbing Scheduled Tasks info.
#
#==========================================================================

get-pssnapin -registered | add-pssnapin -passthru
$ReqVersion = [version]"1.2.2.1254" 
$QadVersion = (Get-PSSnapin Quest.ActiveRoles.ADManagement).Version  #Need Quest plugins installed

if($QadVersion -lt $ReqVersion) { 
    throw "Quest AD cmdlets version '$ReqVersion' is required. Please download the latest version" 
} #end If

$ErrorActionPreference = "SilentlyContinue"

# Accounts to ignore
$IgnoreAcct = "NT AUTHORITY\LocalService",
      "LocalSystem",
      ".\*", 
      "NT AUTHORITY\NETWORK SERVICE", 
      "NT AUTHORITY\NetworkService"

#Place Headers on out-put file
$list = "Server,Service,Account,"
$list | format-table | Out-File "c:\reports\GetSVCAccts\SVCAccounts.csv"
$list2 = "Server,Task,Next Run Time,Account,"
$list2 | format-table | Out-File "c:\reports\GetSVCAccts\TASKAccounts.csv"


#Get all the servers from the specified OU
$Servers = get-QADComputer -SearchRoot domain.local/' -OSName "*Server*" # change the container based on site.

Foreach ($server in $Servers ) {
    $serverFQDN = $server.dnsname
	#Test ping server to make sure it's up before querying it
	$ping = new-object System.Net.NetworkInformation.Ping
	$Reply = $ping.Send($serverFQDN)
    if ($Reply.status -eq "Success"){
        Write-Host "$serverFQDN ************* Online"
		
        # Get service info
        $error.clear()
		gwmi win32_service -computer $serverFQDN -property name, startname, caption |
			% {
                $name = $_.Name
                $Acctname = $_.StartName
                If ( $IgnoreAcct -notcontains $AcctName )
                { 
                    Write-host "$serverFQDN   $Name   $Acctname"
                    $list = "$serverFQDN,$Name,$Acctname"
    			    $list | format-table | Out-File -append "d:\reports\GetSVCAccts\SVCAccounts.csv"
                } #end If
			} #end ForEachObj
        
            #Write log if no access
			if (!$?) {
                $errmsg = "$serverFQDN,No RPC server,ACCESS DENIED"
                $errmsg | format-table | Out-File -append "d:\reports\GetSVCAccts\SVCAccounts.csv"
            } # end Error
            
        #Get scheduled tasks
       $SchQuery = Schtasks.exe /query /s $serverFQDN /NH /V /FO CSV  
            If ($SchQuery -ne "INFO: There are no scheduled tasks present in the system.") 
            {
                ForEach ($Sch in $SchQuery)
                {
                    Write-host "*********************" 
                    $Schfixed = $Sch.Replace("`"","")
                    $Props = $Schfixed.Split(',')
                
                    ForEach ($Prop in $Props)
                    {
                        If ($Prop -like "firm\*")
                        {
                            $list2 = $Props[0],$Props[1],$Props[2],$Prop
                            $list2 | format-table | Out-File -append "d:\reports\GetSVCAccts\TASKAccounts.csv"
                            Write-host $list
                        } # end If                              
                    } #end ForEach
                } #end ForEach
            } #end If 
            Else 
            {
                $list2 = $serverFQDN,$SchQuery
                $list2 | format-table | Out-File -append "d:\reports\GetSVCAccts\TASKAccounts.csv"
                Write-host $list
            } #end else
	} #end If
    Else
    {
        Write-Host "$serverFQDN ************* OffLine"
        $list = "$serverFQDN,OFFLINE"
        $list | format-table | Out-File -append "d:\reports\GetSVCAccts\SVCAccounts.csv"
    } #end Else
} #end ForEach