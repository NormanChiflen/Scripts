#Install and run BGInfo at startup using registry method as described here:
#http://forum.sysinternals.com/bginfo-at-startup_topic2081.html
#Setup 
#1. Download BgInfo http://technet.microsoft.com/en-us/sysinternals/bb897557
#2. Create a bginfo folder and copy bginfo.exe
#3. Create a bginfo.bgi file by running bginfo.exe and saving a bginfo.bgi file and placing in same directory as bginfo

if (Test-Path "C:\WINDOWS\system32\bginfo")
{ remove-item -path "C:\WINDOWS\system32\bginfo" -Recurse }

#Change \\Z001\d$\sw\bginfo to your SW distrib share
copy-item \\Z001\d$\sw\bginfo -Destination C:\Windows\system32 -Recurse

Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -name "BgInfo" -value  "C:\WINDOWS\system32\bginfo\Bginfo.exe C:\WINDOWS\system32\bginfo\bginfo.bgi /TIMER:0 /NOLICPROMPT"