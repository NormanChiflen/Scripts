## deploy a build based on increase in version on VOY
## Babisitty barrys XML build version output from Database.

param($target_environment="INT5",[string]$major_version="13",[string]$minor_version="max")

## logging setup
$Logfile_last="c:\cct_ops\last_deployment.log"
$Logfile_all ="c:\cct_ops\last_deployment_all.log"

"----starting--- $(get-date) ---" | out-file $Logfile_last
function lastlog($in){out-file -filepath $Logfile_last -InputObject $in -append}



## getting versions and some overblown error checking.
$source_of_truth = "C:\cct_ops\latest_voy_from_barry.txt"

if (!(Test-Path $source_of_truth) -or ([array]$(gc $source_of_truth)).length -lt 2) {
		($current_ui  = 0) |out-file $source_of_truth
		($current_svc = 0) |out-file $source_of_truth -append
	}else{
		$current_ui  = (gc $source_of_truth)[0]
		$current_svc = (gc $source_of_truth)[1]
	}




##Getting build deployment info from Barrys file
[xml]$source_file=gc "d:\BuildVersionExtract\BuildVersionExtract.xml"
$max_major_versions=($source_file.BuildEvents.Build | %{$_.MajorVersion} | ?{$_ -match "^[\d\.]+$"} | measure -maximum).maximum
$max_minor_versions=($source_file.BuildEvents.Build | ?{$_.MajorVersion -eq $max_major_versions} | %{$_.MinorVersion} |  measure -maximum).maximum
$working_version=$source_file.BuildEvents.Build|where{$_.majorversion -like $max_major_versions -and $_.minorversion -like $max_minor_versions}

## Temporary workaround for a bug that returns latest minor version regardless of the actual version
## $working_version = $working_version[0]


## error checking / logging


$UI_Version_path=$working_version.VoyagerClient.PackagePath
($latest_UI_version = Split-Path $UI_Version_path -leaf)

## going forward we want to not have to extract the version number but instead pass the whole file to the installer.
$SVC_package_full=$working_version.VoyagerService.Package
($latest_SVC_Version=$SVC_package_full.replace("com.expedia.ngat.service-","").replace(".war",""))

"current_ui = $current_ui"
"latest_UI_version = $latest_UI_version"
"current_svc = $current_svc"
"latest_SVC_Version = $latest_SVC_Version"

## Deployment is executed if UI or Services changed.
## Take a look at Barrys URL
if ($current_ui -ne $latest_UI_version -or $current_svc -ne $latest_SVC_Version){
	#kick off voy build
	\\chelappsbx001\deploymentautomation_dogfood\Voyager_IIS\Deployment\Continuous_Deployment\CD_pilot_deploy_remote.ps1 -target_environment $target_environment
	$latest_UI_version | Out-File $source_of_truth
	$latest_SVC_Version | Out-File $source_of_truth -Append
	}else{
	## log that nothing happened and that versions were checked
	}




# SIG # Begin signature block
# MIIGBwYJKoZIhvcNAQcCoIIF+DCCBfQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhpN2FhDqepmo2uEykC8JVJRZ
# 3D2gggQpMIIEJTCCA46gAwIBAgIQZYCiv3KRDoNH6gz2dQW5izANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNEO9wwGBTV4KMr2
# 47pSbngY9nv7MA0GCSqGSIb3DQEBAQUABIGAD9iv8GaEJatEyT4p+hSp9/dV+pPn
# ggDMnLTysO/GbcK+PQPcFEJIWpRrqVj00lcI4bGQXFV9hvgIXAxO6GUN/gjyEnY1
# 8MwXs0y7PcTLEO5hJsuR0gtxdfey69Mz9vGjebhx+vzThCUU8RXnOdVFDj8DIioj
# LCZeb5jDUCPS3v8=
# SIG # End signature block
