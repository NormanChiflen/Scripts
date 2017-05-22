net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

md \\dnfil01\ops\hotfixed\%1

net stop snmp /y
net stop remoteregistry
net stop winmgmt
net stop fcastclt
net stop notbot
net stop cbot2
net stop hnotbot
net stop mmbot
net stop RuleBot
net stop regionhotbot
net stop ipap
net stop cbot2
net stop notbot
net stop fraudbot
net stop paybot
net stop w3svc

kill -f qslog
sleep 2
kill -f inetinfo
sleep 7
kill -f drwtsn32

c:\localbin\robocopy c:\travbin\server d:\travbin.old\server /e /eta /r:1 /w:1
c:\localbin\robocopy c:\travbin\sys d:\travbin.old\sys /e /eta /r:1 /w:1
c:\localbin\robocopy e:\webroot\pub d:\webroot.old\pub /e /eta /r:1 /w:1

net name > \\dnfil01\ops\hotfixed\%1\%computername%.txt

c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\server c:\travbin\server /e /XX /xo /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19Source\Extracted\travbin\redist c:\travbin\redist /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\travbin\sys c:\travbin\sys /e /XX /xo /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy \\dncrs01\r19source\extracted\webroot\pub e:\webroot\pub /e /XX /xo /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\sys\ c:\winnt\system32\ /e /XX /xo /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt
c:\localbin\robocopy c:\travbin\redist\ c:\winnt\system32\ /e /XX /XO /r:1 /w:1 >> \\dnfil01\ops\hotfixed\%1\%computername%.txt



sleep 5

net start notbot
net start cbot2
net start paybot
net start hnotbot
net start mmbot
net start RuleBot
net start regionhotbot
net start ipap
net start cbot2
net start notbot
net start w3svc
net start msftpsvc
net start fcastclt
net start snmp
net start winmgmt
net start cqmghost
net start cpqwmgmt
net start remoteregistry
net start smtpsvc

dir /s c:\travbin > \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt
dir /s e:\webroot\pub >> \\dnfil01\ops\hotfixout\%1-POST-%computername%-timestamp.txt

net use \\dnfil01 /delete
net use \\dncrs01 /delete