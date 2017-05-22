# Dev deployer - wrapper for standard Voyager_IIS deployment script
# version 1 

importsystemmodules
$available_web = get-website DEV* 

"";""
write-host -f green  "Current configuration"
write-host ""
write-host -f Yellow "physicalpath          Instance Name      Current Version      Current endpoint"
foreach ($web in $available_web ) {
	[string]$temppath=$web.physicalpath 
	if(test-path $temppath\version.txt){
		[string]$OldVersion=(gc $temppath\version.txt) -match '([v]\d{1}\..{1,10})$'
		$OldVersion=($OldVersion -split("to "))[1]
		}ELSE{$OldVersion="version.txt not found"
	}
	if(test-path $temppath\web.config){
		[xml]$endpoint=gc $temppath\web.config
		$srvendpoint = $endpoint.SelectNodes("/configuration/system.serviceModel/client/endpoint") | 
			where {$_.bindingConfiguration -like "lodgingSupplyBinding"}
		}ELSE{$srvendpoint="web.config not found"
	}
	$web.physicalpath + "     " + $web.name +  "     " + $OldVersion + "      " + $srvendpoint.address
	}

write-host ""
write-host "UI entry point is: <instance name>.sb.karmalab.net"
write-host "Example:   https://$($web.name).sb.karmalab.net"

"";""

$version = read-host -prompt "Please enter version number: Example v1.Main.0.311      :"
$environment = read-host -prompt "Please enter environment you'd like to deploy to    :"

pushd \\chelappsbx001\deploymentautomation_dogfood\Voyager_IIS\Deployment
.\Voyager_upgrade_IIS_only.ps1 -environment $environment -buildversion $version

$prompt = read-host -prompt "If you want to Change[C] the endpoint enter C, otherwise press Enter"


if($prompt -eq "C" -or $prompt -eq "Change"){
	write-host -f yellow "Example of custom endpoint = John_Dragon.sb.karmalab.net:8084"
	write-host            "            Available dev workstation endpoints"
	write-host -f darkgreen "Ty_Lam.sb.karmalab.net"
	write-host -f darkgreen "Waclaw_Antosz.sb.karmalab.net"
	write-host -f darkgreen "Dinesh_Dhamija.sb.karmalab.net"
	write-host -f darkgreen "John_Beaver_win.sb.karmalab.net"
	write-host -f darkgreen "John_Beaver_mac.sb.karmalab.net"
	write-host -f darkgreen "Travis_Redfield.sb.karmalab.net"

	$New_endpoint = read-host -prompt "Please enter the ROOT of new endpoint you would like to use :"
	[string]$webroot_path = ($available_web | ?{$_.name -like $environment}).physicalPath
	$webconfig_path = "$webroot_path\web.config"
	
	[xml]$xml_change_only=(gc $webconfig_path)
	$xml_change_only.SelectNodes("/configuration/system.serviceModel/client/endpoint") | 
		where {$_.bindingConfiguration -like "lodgingSupplyBinding" -or $_.bindingConfiguration -like "voyagerRefDataBinding"}| 
			foreach {$_.address = $_.address -replace '\w*\:.*?\:[0-9]{4,}', $New_endpoint
		}
	$xml_change_only.Save($webconfig_path)
	}

Write-host -f yellow "Deployment finished"
