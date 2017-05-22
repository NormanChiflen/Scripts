###########################################################################
#
# NAME: 
#
# AUTHOR:  nfletcher
#
# COMMENT: 
#
# VERSION HISTORY:
# 1.0 05/03/2014 - Initial release
#
###########################################################################
(Get-Content C:\chef\client.rb) | 
Foreach-Object {$_ -replace "10.0.16.46", "chef.ewetest.expedia.com" } |
Foreach-Object {$_ -replace "chef.aws.sb.karmalab.net", "chef.ewetest.expedia.com" } | 
Foreach-Object {$_ -replace "internal-chef-ewetest-363603259.us-east-1.elb.amazonaws.com", "chef.ewetest.expedia.com"} |
Set-Content C:\chef\client.rb

