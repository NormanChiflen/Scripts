net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

#del c:\*.old /s

md \\dncrs01\d$\opsscripts\hotfixed\%1

net stop snmp /y
net stop remoteregistry
net stop winmgmt
net stop fcastclt
net stop genbot
net stop hnotbot
net stop regionhotbot
net stop mmbot
net stop ptqbot
sleep 10



c:\localbin\robocopy c:\travbin\sys d:\travbin.old\sys /e /eta /r:1 /w:1
c:\localbin\robocopy c:\travbin\server d:\travbin.old\server /e /eta /r:1 /w:1

net name > \\dncrs01\d$\opsscripts\hotfixed\%1\%computername%.txt

c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\server c:\travbin\server /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19Source\Extracted\travbin\redist c:\travbin\redist /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\sys c:\travbin\sys /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\sys\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\redist\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt

Sleep 5

net start snmp /y
net start remoteregistry
net start winmgmt
net start fcastclt
net start genbot
net start hnotbot
net start regionhotbot
net start mmbot
net start ptqbot

dir /s c:\travbin > \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt

net use \\dnfil01 /delete
net use \\dncrs01 /delete