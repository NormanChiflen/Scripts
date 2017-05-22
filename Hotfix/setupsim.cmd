net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2

del c:\winnt\temp\MTTSetupLog*.log

\\dncrs01\SimSetup\10_0\mtt\setup.exe /U /f dn.ini /s %1 /sim



sleep 60

copy c:\winnt\temp\MTTSetupLog*.log \\dnfil01\ops\hotfixed\setupsim\%computername%-*.log
del c:\winnt\temp\MTTSetupLog*.log

net use \\dnfil01 /delete
net use \\dncrs01 /delete