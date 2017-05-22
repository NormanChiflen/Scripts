net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

del c:\*.old /s

md \\dnfil01\ops\hotfixed\%1
net stop mstravob
net stop snmp /y
net stop remoteregistry
net stop winmgmt
net stop fcastclt
net stop ablog
kill -f mstravob
kill -f *sp.exe





c:\localbin\robocopy c:\travbin\sys c:\travbin.old\sys /e /eta /r:1 /w:1
c:\localbin\robocopy c:\travbin\server c:\travbin.old\server /e /eta /r:1 /w:1

net name > d:\opsscripts\hotfixed\%1\%computername%.txt

c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\server c:\travbin\server /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\Extracted\travbin\redist c:\travbin\redist /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\sys c:\travbin\sys /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\sys\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\redist\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
copy /y c:\travbin\server\ccemdataprod.xml c:\travbin\server\ccemdata.xml

Sleep 5



net start fcastclt
net start snmp
net start winmgmt
net start cqmghost
net start cpqwmgmt
net start remoteregistry
net start mstravob
net start ablog

dir /s c:\travbin > \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt

net use \\dnfil01 /delete
net use \\dncrs01 /delete