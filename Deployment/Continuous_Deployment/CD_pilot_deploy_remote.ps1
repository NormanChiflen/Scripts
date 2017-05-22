## how to sign the script: 
## dir cd*|%{Set-AuthenticodeSignature $_ $(dir cert:\ -Recurse -CodeSigningCert)}

##Automated deployment
##pushd \\chelappsbx001\DeploymentAutomation_dogfood\Voyager_IIS\Deployment
param([string]$target_environment="INT5",$deploy_services="true")

if($(Get-ExecutionPolicy) -ne "bypass"){Set-ExecutionPolicy bypass -force}

## Hardcoding the environment.
##$target_environment="int5"
##$target_version="develop"


## Going forward: 
## The parent script will query the netscaler for SG and pull out servers.
## Another parent script will take servers out of rotation
## Then this script will get a list of servers and perform deployment - EXPECTED FQDN format


## Getting Variables for the Environment 
$csv= import-csv \\chelappsbx001\DeploymentAutomation_dogfood\Voyager_IIS\Deployment\environments.csv | where {$_.environment -eq $target_environment}
## Getting UI boxes
## - old hard coded - $UIServers="CHELWEBCCT008.karmalab.net","CHELWEBCCT010.karmalab.net"
## - old - $UIServers=$csv.Servers_in_Environment.Split(";")
$UIServers=$csv.Servers_in_Environment.Split(";") |%{if($_ -notmatch "karmalab"){$_ + ".karmalab.net"}}

## Getting Linux properties from Environment CSV
($working_linux_env =  $csv.LINUX_Servers.split(";"))
($tomcats=$csv.Tomcat_Instance.split(";"))
($endpoint = $csv.LINUX_endpoint)



## Getting Credentials for the current user from previously generated password file
Import-Module \\chelappsbx001\deploymentautomation\lib\Functions_common.psm1 -function Import-PSCredential  -force -passthru
Import-PSCredential


##Getting build deployment info from Barrys file
#$working_version=$source_file.BuildEvents.Build|?{$_.majorversion -like 'voyager' -and $_.minorversion -like $target_version}

##Getting build deployment info from Barrys file
[xml]$source_file=gc "d:\BuildVersionExtract\BuildVersionExtract.xml"
$max_major_versions=($source_file.BuildEvents.Build | %{$_.MajorVersion} | ?{$_ -match "^[\d\.]+$"} | measure -maximum).maximum
$max_minor_versions=($source_file.BuildEvents.Build | ?{$_.MajorVersion -eq $max_major_versions} | %{$_.MinorVersion} |  measure -maximum).maximum
$working_version=$source_file.BuildEvents.Build|where{$_.majorversion -like $max_major_versions -and $_.minorversion -like $max_minor_versions}

## Temporary workaround for a bug that returns latest minor version regardless of the actual version
## $working_version = $working_version[0]


$UI_Version_path=$working_version.VoyagerClient.PackagePath
($UI_version = Split-Path $UI_Version_path -leaf)

$SVC_Version_full=$working_version.VoyagerService.Package
($SVC_Version=$SVC_Version_full.replace("com.expedia.ngat.service-","").replace(".war",""))



##Running Services Deployment

if($deploy_services){
	foreach ($server in $working_linux_env){
		foreach ($tomcat in $tomcats){
		$exec_string = "sudo su tomcat -c `'/ops/bin/deploy-lab -i $tomcat -v $SVC_Version -t service -e $endpoint`'"

		##\\chelappsbx001\DeploymentAutomation_dogfood\bin\plink
		c:\cct_ops\plink.exe -i C:\cct_ops\putty_priv_key.ppk avinyar@$server $exec_string
		#plink -l avinyar -pw "*********" $server $exec_string
		}
	}
}


##Running  UI  deployment
$UIServers | foreach {Invoke-Command  -ComputerName $_ -Credential $Credential -Authentication Credssp  -ScriptBlock {param($target_environment,$UI_version) set-executionpolicy bypass -force;pushd \\chelappsbx001\DeploymentAutomation_dogfood\Voyager_IIS\Deployment;.\Voyager_upgrade_IIS_only.ps1 $target_environment $UI_version} -ArgumentList $target_environment,$UI_version}


##Kick off lab run - old way
#\\chelwebtfx02\Apps\LabRunCreator\LabRunCreator.exe /tempId 12575 /branch main /email "v-bschrag@expedia.com,avinyar@expedia.com,jaelee@expedia.com,jchoosakul@expedia.com,suvendud@expedia.com,nstark@expedia.com" /env VOY_$target_environment


##Kick off lab run - New way to enable parsing.
$executable = "\\chelwebtfx02\Apps\LabRunCreator\LabRunCreator.exe"
$param = '/tempId 12575 /branch main /email "v-bschrag@expedia.com,avinyar@expedia.com,jaelee@expedia.com,jchoosakul@expedia.com,suvendud@expedia.com,nstark@expedia.com" /env '+"VOY_$target_environment"
$lrm_output='c:\cct_ops\lrm_out.txt'
Start-Process $executable $param -NoNewWindow -PassThru -RedirectStandardOutput $lrm_output -wait
$lrm_id = (gc $lrm_output) -match 'starting labrun' -replace '\D'

## Running JJ tool for trending
\\PHELCCTTEST001\test\lrmResult\LRMSvc.exe $(Get-Date -Format yyyy-MM-dd) $lrm_id bvt

## Results can be seen here:
## http://phelccttest001:8080/cctTestApp/showCIStatus.jsp 


# SIG # Begin signature block
# MIIGBwYJKoZIhvcNAQcCoIIF+DCCBfQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUInPMVOHqdNurXsfWLxCVf+1G
# NRugggQpMIIEJTCCA46gAwIBAgIQZYCiv3KRDoNH6gz2dQW5izANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFK11q12jwk2x6LKC
# vz7sbfN98ZoVMA0GCSqGSIb3DQEBAQUABIGAxu56tu8y1eLMoek/BSnmtsn5tL/x
# nur50Nkt1D43RrkVTtBYz3PHo6bUCxISAIzGLQxwuXW19VIfiFXMVoxk7D9Ox8Jg
# hh25LfP0t4+nmlvM2SDElS+sGlWOz1+HCDzrSM1hRhGP3pJo8kUqX74erDA5rBk2
# KCPOGcO7jw59eoc=
# SIG # End signature block
