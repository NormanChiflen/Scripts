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
net stop TSBFSQMGR
net stop BFSQAVS
net stop BFSQCST
net stop BFSQCVR
net stop BFSQDED
net stop BFSQDIR
net stop BFSQDMD
net stop BFSQDRT
net stop BFSQFRS
net stop BFSQITD
net stop BFSQMCT
net stop BFSQOAG
net stop BFSQPFC
net stop BFSQTPM
net stop BFSQUKD
net stop BFSCfgSvc
net stop BFSDIAGMGR
net stop dedmgr
sleep 10
kill -f bfs*
kill -f tsbfsqmgr
kill -f tsbfsqmgr
kill -f tsbfsqmgr
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

net start BFSCfgSvc
net start BFSDIAGMGR
net start BFSQAVS
net start BFSQCST
net start BFSQCVR
net start BFSQDED
net start BFSQDIR
net start BFSQDMD
net start BFSQDRT
net start BFSQFRS
net start BFSQITD
net start BFSQMCT
net start BFSQOAG
net start BFSQPFC
net start BFSQTPM
net start BFSQUKD
net start TSBFSQMGR
net start dedmgr
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