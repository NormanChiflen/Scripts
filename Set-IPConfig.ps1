# script parameters
param(
[string[]] $Computers = $env:computername,
[switch] $ChangeSettings,
[switch] $EnableDHCP
)
# check for Admin rights
if ($ChangeSettings -or $EnableDHCP){
	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
		Write-Warning "You need Administrator rights to run this script!"
		Break
	}
}
else{
""
Write-Warning "For changing settings add -ChangeSettings as parameter, if not this script is output only"
}
# script variables
$nl = [Environment]::NewLine
$Domain = "domain.local"
$DNSSuffix = @("domain.local", "domain.com")
$DNSServers = @("10.10.0.1", "10.20.0.1", "10.10.0.2", "10.20.0.2")
$WINSServers = @("10.10.0.125", "10.10.0.126")
$Gateway = @("10.10.255.254")
# script functions
Function NewNICDetails($NIC, $Computer){
	# retrieve updated values for changed NIC
	$UpdatedNIC = Get-WMIObject Win32_NetworkAdapterConfiguration -Computername $Computer | where{$_.Index -eq $NIC.Index}
	ShowDetails $UpdatedNIC
}

Function ChangeIPConfig($NIC){
	if ($EnableDHCP){$NIC.EnableDHCP()}
	#$NIC.SetGateways($Gateway)
	#$NIC.SetWINSServer($WINSServers)
	$DNSServers = Get-random $DNSservers -Count 4
	$NIC.SetDNSServerSearchOrder($DNSServers)
	$NIC.SetDynamicDNSRegistration("TRUE")
	$NIC.SetDNSDomain($Domain)
	# remote WMI registry method for updating DNS Suffix SearchOrder
	$registry = [WMIClass]"\\$computer\root\default:StdRegProv"
	$HKLM = [UInt32] "0x80000002"
	$registry.SetStringValue($HKLM, "SYSTEM\CurrentControlSet\Services\TCPIP\Parameters", "SearchList", $DNSSuffix)
}

Function ShowDetails($NIC){
	Write-Host "Hostname = "  $NIC.DNSHostName
	Write-Host "DNSDomain= "  $NIC.DNSDomain
	Write-Host "Domain DNS Registration Enabled = "  $NIC.DomainDNSRegistrationEnabled
	Write-Host "Full DNS Registration Enabled = "  $NIC.FullDNSRegistrationEnabled
	Write-Host "DNS Domain Suffix Search Order = "  $NIC.DNSDomainSuffixSearchOrder
	Write-Host "MAC address = "  $NIC.MACAddress
	Write-Host "DHCP enabled = "  $NIC.DHCPEnabled
	# show all IP adresses on this NIC
	$x = 0
	foreach ($IP in $NIC.IPAddress){
		Write-Host "IP address $x =" $NIC.IPAddress[$x] "/" $NIC.IPSubnet[$x]
		$x++
	}
	Write-Host "Default IP Gateway = "  $NIC.DefaultIPGateway
	Write-Host "DNS Server Search Order = "  $NIC.DNSServerSearchOrder	
}
# actual script execution
foreach ($Computer in $Computers){
	if (Test-connection $Computer -quiet -count 1){
	Try {
		[array]$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration -Computername $Computer | where{$_.IPEnabled -eq "TRUE"}
		} 
	Catch { 
		Write-Warning "$($error[0]) " 
		Break 
		}
	# Generate selection menu only if there is indeed more than 1 NIC
	$NICindex = $NICs.count
	$SelectIndex = 0
	if ($NICindex -gt 1){
		Write-Host "$nl Selection for " $Computer.ToUpper() ": $nl"
		For ($i=0;$i -lt $NICindex; $i++) {
			Write-Host -ForegroundColor Green $i --> $($NICs[$i].Description)
			}
		Write-Host -ForegroundColor Green q --> Quit
		Write-host $nl
		# Wait for user selection input
		Do {
			$SelectIndex = Read-Host "Select connection (default = $SelectIndex) or 'q' to quit"
			If ($SelectIndex -NotLike "q*"){$SelectIndex = $SelectIndex -as [int]}
		}
		Until (($SelectIndex -lt $NICindex -AND $SelectIndex -match "\d") -OR $SelectIndex -Like "q*")
		If ($SelectIndex -Like "q*"){continue}
	}
	# Show selected network card name + current values
	Write-Host "$nl IP settings on:"$Computer.ToUpper() "$nl $nl for " $NICs[$SelectIndex].Description ":"
	Write-host "$nl     ====BEFORE====$nl $nl"
	Write-Host $(ShowDetails $NICs[$SelectIndex]) $nl
	# Change settings for selected network card if option is true and show updated values
	If ($ChangeSettings){
		ChangeIPConfig $NICs[$SelectIndex]
		Write-Host "$nl IP settings on:"$Computer.ToUpper() "$nl $nl for " $NICs[$SelectIndex].Description ":"
		Write-host "$nl    ====AFTER====$nl $nl"
		Write-Host $(NewNICDetails $NICs[$SelectIndex] $Computer) $nl
		}
	}
}