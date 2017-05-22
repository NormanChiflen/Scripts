net use \\dncrs01 %2 /U:EXPESO\%1

mkdir d:\setup
mkdir d:\setup\R19
mkdir d:\setup\R19\14_0
mkdir d:\setup\R19\14_0\mtt

robocopy \\dncrs01\R19Source\Setup\14_0\mtt\ d:\setup\R19\14_0\mtt /MIR /LOG:d:\setup\%computername%.log
copy /Y d:\setup\%computername%.log \\dncrs01\copybitslogs\