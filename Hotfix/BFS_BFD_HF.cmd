net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

del c:\*.old /s

md \\dnfil01\ops\hotfixed\%1

net stop snmp /y
net stop remoteregistry
net stop winmgmt
net stop fcastclt
net stop twgipc
net stop top 
net stop bfsdis
net stop bfsdiagmgr
net stop bfsdsvcmgr
sleep 60
kill -f bfs*
kill -f top
sleep 5

del c:\travbin.old /y
c:\localbin\robocopy c:\travbin c:\travbin.old /e /eta /r:1 /w:1

net name > \\dnfil01\ops\hotfixed\%1\%computername%.txt

c:\localbin\robocopy \\dncrs01\r18source\extracted\travbin\bfs c:\travbin\bfs /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r18source\extracted\travbin\bfsps c:\travbin\bfsps /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r18source\extracted\travbin\sys c:\travbin\sys /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r18Source\Extracted\travbin\redist c:\travbin\redist /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\sys\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\redist\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt

net start bfsdis
net start bfsdiagmgr
net start bfsdsvcmgr
net start fcastclt
net start twgipc
net start snmp
net start winmgmt
net start cqmghost
net start cpqwmgmt
net start remoteregistry

dir /s c:\travbin > \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt
net use \\dnfil01 /delete
net use \\dncrs01 /delete