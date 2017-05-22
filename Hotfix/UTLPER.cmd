net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

md \\dnfil01\ops\hotfixed\%1

net stop snmp /y
net stop remoteregistry
net stop winmgmt
net stop grascore
net stop grawrite

Sleep 2


kill -f drwtsn32

sleep 7



c:\localbin\robocopy c:\travbin\sys d:\travbin.old\sys /e /eta /r:1 /w:1
c:\localbin\robocopy c:\travbin\gra d:\travbin.old\gra /e /eta /r:1 /w:1
c:\localbin\robocopy c:\travbin\redist d:\travbin.old\redist /e /eta /r:1 /w:1


net name > \\dnfil01\ops\hotfixed\%1\%computername%.txt

c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\sys c:\travbin\sys /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\gra c:\travbin\gra /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\redist c:\travbin\redist /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\sys\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\redist\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt


net start snmp
net start winmgmt
net start cqmghost
net start cpqwmgmt
net start remoteregistry
net start grascore
net start grawrite

dir /s c:\travbin > \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt


net use \\dnfil01 /delete
net use \\dncrs01 /delete