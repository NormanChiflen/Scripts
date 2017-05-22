## Monitoring target jenkins instance, and kick off another instance depending on vestion change.

param([string]$Jenkins_instance_monitoring="voy_ci",$Jenkins_instance_starting="voy")


## logging
$Logfile_last="c:\cct_ops\last_deployment.log"
$Logfile_all ="c:\cct_ops\last_deployment_all.log"

"----starting--- $(get-date) ---" | out-file $Logfile_last
function lastlog($in){out-file -filepath $Logfile_last -InputObject $in -append}


## Setting up Environment variables
$current_build = gc C:\cct_ops\latest_$Jenkins_instance_monitoring.txt
[int32]$current_build = $current_build -replace '\s' -replace '\D'
#logging
lastlog "Current version of $Jenkins_instance_monitoring = $current_build"


## Getting RSS Feed from Jenkins as XML
$client = new-object System.Net.WebClient
$jenkins_temp="c:\cct_ops\jenkins_$Jenkins_instance_monitoring.xml"
$client.DownloadFile("http://chelwbangat22:8080/job/$Jenkins_instance_monitoring/rssAll", $jenkins_temp)
#logging
if ($?){lastlog "RSS Downloaded successfully from $Jenkins_instance_monitoring/rssAll"}


## via wget	
#wget http://chelwbangat22:8080/job/$Jenkins_instance_monitoring/rssAll --output-document=c:\cct_ops\jenkins_$Jenkins_instance_monitoring.xml


## Parsing XML feed
[xml]$a=gc $jenkins_temp
$b=$a.feed.entry | select -First 1
if($b.title -like "*(stable)" -or $b.title -like "*(back to normal)"){
		[int32]$latest_build=$b.title.Replace("$Jenkins_instance_monitoring #","") -replace '\D'
		#logging
		lastlog "RSS Output - latest_build = $latest_build"
	}else{
		#Logging
		lastlog "RSS Output - no good build found."
		lastlog "latest_build = $($b.title) (current_build = $current_build)"
	}


## To build or not to Build.
if ($current_build -lt $latest_build){
	#kick off $Jenkins_instance_starting build via powershell
	$client = new-object System.Net.WebClient
	#logging
	lastlog "Attempting to Kick off build because $current_build < $latest_build"
	$client.DownloadString("http://chelwbangat22:8080/job/$Jenkins_instance_starting/build?token=$Jenkins_instance_starting")
	#logging
	lastlog "Executing jenkins build through URL - string result : $?"
	lastlog "Writing Latest version ($latest_build) to latest_$Jenkins_instance_monitoring.txt"
	$latest_build|Out-File C:\cct_ops\latest_$Jenkins_instance_monitoring.txt
	
	
	#kick off $Jenkins_instance_starting build via wget
	#wget http://chelwbangat22:8080/job/$Jenkins_instance_starting/build?token=$Jenkins_instance_starting
	
	}

#Log ending
gc $Logfile_last | out-file $Logfile_all -append

# SIG # Begin signature block
# MIIGBwYJKoZIhvcNAQcCoIIF+DCCBfQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCo/rwW2Su2fwe71kDsv5RGps
# e/6gggQpMIIEJTCCA46gAwIBAgIQZYCiv3KRDoNH6gz2dQW5izANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKmqnccb/rDbaYc4
# eGKRkPBX4OyKMA0GCSqGSIb3DQEBAQUABIGAEOu7joXtF6X3/ymAMwAsk3FmGB1o
# 1yxZKsWnfEcSy3WeditpE1ouGBH/tD2JQeVicY2PIpvtFUQ6WsunMnKbPUXpBbRA
# oxd09LbxVKyJLj9/YnrzQ2Lv8E7fiOt9rN8+kz6NAxuxUvSmxeMg9jiMvL53eEQ4
# m509eng2J5w3rHk=
# SIG # End signature block
