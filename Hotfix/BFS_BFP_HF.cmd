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
net stop AVSMGR
net stop CSTMGR
net stop CVRMGR
net stop DEDMGR
net stop BFSDIAGMGR
net stop DMDMGR
net stop DRTMGR
net stop FRSMGR
net stop WCSWAP
net stop ITDMGR
net stop MCTMGR
net stop OAGLOCMGR
net stop OAGMGR
net stop PFCMGR
net stop SCHCHKMGR
net stop SCHMGR
net stop SCHPRIMEMGR
net stop UKDMGR
sleep 10

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

net start AVSMGR
net start CSTMGR
net start CVRMGR
net start DEDMGR
net start BFSDIAGMGR
net start DMDMGR
net start DRTMGR
net start FRSMGR
net start WCSWAP
net start ITDMGR
net start MCTMGR
net start OAGLOCMGR
net start OAGMGR
net start PFCMGR
net start SCHCHKMGR
net start SCHMGR
net start SCHPRIMEMGR
net start UKDMGR
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