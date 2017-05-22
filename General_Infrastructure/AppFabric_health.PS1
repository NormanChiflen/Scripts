# App Fabric Babysitting script v0.9


#Import-Module \\chelappsbx001\deploymentautomation\lib\Functions_common.psm1 -force -verbose
# Export-PSCredential
#Import-PSCredential

#New-PSSession  -name Test -ComputerName CHELCHENGAT07.karmalab.net -Credential $Credential -Authentication Credssp
# maybe put loop for all servers.
#New-PSSession  -name Dev -ComputerName CHELCHENGAT01.karmalab.net -Credential $Credential -Authentication Credssp
#New-PSSession  -name E2E -ComputerName CHELCHENGAT07.karmalab.net -Credential $Credential -Authentication Credssp


#Enter-PSSession -name test
#Invoke-Command -session $(get-pssession 2) -ScriptBlock {} 
Set-ExecutionPolicy Bypass -scope localmachine -force -WarningAction SilentlyContinue


Import-Module DistributedCacheAdministration -force #-passthru
Import-Module DistributedCacheConfiguration -force #-passthru
#Import-Module \\chelappsbx001\deploymentautomation\lib\Functions_common.psm1 -verbose -force
Import-Module \\chelappsbx001\deploymentautomation\lib\Functions_common.psm1 -verbose -force
# odd bug - cant load modules from inside function:


$Test = "\\chelappsbx001\AppFabric_XMLConfigs\Test"
$Dev = "\\chelappsbx001\AppFabric_XMLConfigs\Dev"
$E2E = "\\CHELCHENGAT07\Fabric"

#\\chelappsbx001\AppFabric_XMLConfigs\Test	CHELCHENGAT04;CHELCHENGAT05;CHELCHENGAT06;CHELCHENGAT17;CHELCHENGAT18;CHELCHENGAT19
#\\chelappsbx001\AppFabric_XMLConfigs\Dev	CHELCHENGAT01;CHELCHENGAT02;CHELCHENGAT03;CHELCHENGAT14;CHELCHENGAT15;CHELCHENGAT16
#\\CHELCHENGAT07\Fabric						CHELCHENGAT07;CHELCHENGAT08;CHELCHENGAT09;CHELCHENGAT20;CHELCHENGAT21;CHELCHENGAT22;CHELCHENGAT23


# Testing health of each cluster
$mailbody=@()

#Stop-CacheHost CHELCHENGAT16 22233
#restart-cachehost  CHELCHENGAT16 22233
#Remove-Item Function:\TestClusterHealth

function TestClusterHealth ($Location_of_Config) {
	Use-CacheCluster -Provider XML -ConnectionString $Location_of_Config
	
	$FullAppFabricCluster=convertfrom-csv $(Get-CacheHost | ConvertTo-Csv )
	#$FullAppFabricCluster| ? {$_.hostname -match "CHELCHENGAT15"} | %{Restart-CacheHost $_.hostname $_.portno}
	[array]$DownNodes=$FullAppFabricCluster | ? {$_.Status -ne "up"}

	if ($DownNodes.count -gt 0){

		#pushd "HKLM:\SOFTWARE\Wow6432Node\Expedia\"
		#if (!(test-path CCTRel)){new-item CCTRel}
		#if (!(test-path HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel)){new-item HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel}
		
		# Make reg key
		if (!(test-path HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel)){ md HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel}
		
		# See if AppFabricRestartCount is created yet
		if (!(Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel")) {New-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel" -Name AppFabricRestartCount -Value 0 -Type String -force}
		
		#if (!(Get-ItemProperty CCTRel)){new-itemproperty CCTRel -Name AppFabricRestartCount  -Value 0 -Type string -force}

		try {
			$mailbody += "Detected down nodes:"
			$mailbody += $DownNodes | ConvertTo-Html
			$mailbody += "<br> auto restarted the following nodes:<br>"
			$mailbody += $DownNodes | %{start-CacheHost $_.hostname $_.portno} | ConvertTo-Html
			}
		catch [Microsoft.ApplicationServer.Caching.DataCacheException]{

			$mailbody += "Unable to restart down nodes. Current status:"
			$mailbody += $FullAppFabricCluster| ? {$_.Status -match "down"} | ConvertTo-Html
			$mailbody += "<br><br>"

			if ((get-itemproperty -path "HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel").appfabricrestartcount -lt 1){
				$mailbody += "Unable to Start node - No Previous restarts attempted - Attempting to restart cluster:<br>"			
				$mailbody += Restart-CacheCluster | ConvertTo-Html
				new-itemproperty CCTRel -Name AppFabricRestartCount  -Value 1 -Type string -force
			} else {
				$mailbody += "Cluster restart already attempted and didnt seem to have helped<br>"
				$mailbody += "Current script error:"
				$mailbody += $_.Exception.ToString()
				
				$event = get-winevent -providername AppFabricCachingService |sort timecreated |select -last 1
				$mailbody += "<br><br>Full error message from Eventvwr: <br>"
				$mailbody += $event.message
				#$date = (get-date).AddDays(-2)  /// AddHours
				#get-event | where {$_.TimeGenerated -ge "11/13/2008 12:15:00 PM"}
				#get-winevent -listlog Setup | format-list -property *
				#get-winevent -listprovider *policy*
				}
			}

		finally{
			$mailbody += "<BR>Config location: $Location_of_Config <br>"
			}
		#amail avinyar@expedia.com cctrel@expedia.com "app fabric experienced issues" $mailbody 
		amail chelchengat07@expedia.com cctrel@expedia.com "AppFabric experienced issues" $mailbody 

	} else {
	#no down nodes detected
	New-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Expedia\CCTRel" -Name AppFabricRestartCount -Value 0 -Type String -force
	$mailbody += $FullAppFabricCluster | sort hostname | ConvertTo-Html
	amail chelchengat07@expedia.com voyrel@expedia.com "AppFabric Health Check Successful" $mailbody 
	}
}

TestClusterHealth $dev
TestClusterHealth $Test
TestClusterHealth $E2E