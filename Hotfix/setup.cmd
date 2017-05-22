rem parameters are 1, System Role 2, User Name and 3, Password
rem example:
rem setup.cmd AMR-GAT aprice password

net use \\dnfil01 %3 /U:EXPESO\%2
net use \\dncrs01 %3 /U:EXPESO\%2


del c:\winnt\temp\MTTSetupLog*.log

\\dncrs01\R20Source\Setup\10_0\mtt\setup.exe /U /f dn.ini /s %1


sleep 15

copy c:\winnt\temp\MTTSetupLog*.log \\dnfil01\ops\setuplog\%computername%-*.log
del c:\winnt\temp\MTTSetupLog*.log

net use \\dnfil01 /delete
net use \\dncrs01 /delete

