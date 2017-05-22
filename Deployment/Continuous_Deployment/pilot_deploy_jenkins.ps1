break

---- SCRIPT IS DISABLED ------

# determining latest version
$UIBuildstorage		= "\\karmalab.net\builds\directedbuilds\sait\CRM\products\ngat"
$UIBuildversion		= "V2.2_voystb"
$SVCBuildstorage1	= "\\chelfilrtt02.karmalab.net\ivyreps\directedbuilds\com.expedia.ngat.service"
$SVCBuildstorage2	= "\\karmalab.net\builds\ivyreps\directedbuilds\com.expedia.ngat.service"
$SVCBuildversion	= "5.0.0"


if(!(test-path $UIBuildstorage\$UIBuildversion*)){
	write-host "Path not found, please make sure $buildstorage\$buildversion exists"
	break
		}else{
		# work around against network hickups.
		$r=1..3;$r|foreach{
			write-host "Searching for the latest build..."
			$buildpath = gci $buildstorage\$buildversion* | sort -property lastwritetime | select -last 1
			start-sleep 1
		}
	write-host "build path: $buildpath"
	$buildNum = $buildpath.name
	}


#Deploy UI
pushd \\chelappsbx001.karmalab.net\DeploymentAutomation_dogfood\Voyager_IIS\Deployment
# hard coding file for now gc remoteInstall -replace ##env## $buildNum
cmd.exe /k psexec.exe \\CHELWBANGAT19.karmalab.net -u SEA\avinyar -p "*********" -h -f -c .\remoteInstall.bat -w c:\cct_ops "cmd /C remoteInstall.bat"



#Deploy Service
pushd C:\Users\avinyar\AppData\Local\Temp
plink -l avinyar -pw "*********" CHELAPPNGAT08.karmalab.net "sudo su tomcat -c '/ops/bin/deploy-lab -i VOY01 -v 5.0.0.2 -t service -e maui'"


#Kick off Labrun
#Labrun template ID = 12324 or this one: 12274
\\chelwebtfx02\Apps\LabRunCreator\LabRunCreator.exe -tempId 12274 -branch PS_DVT -email SEA\avinyar -env GPTCD


