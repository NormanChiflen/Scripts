set errorlog= c:\winnt\temp\sherpaerr.tmp

for %%a in (1) do sclist \\dnbottpa0%%a|grep -i migrationbot > %errorlog%
for /f "eol= tokens=1,2,3,4,5,6,7* delims= " %%i in (%errorlog%) do echo %%j is %%i|if {%%i}=={stopped} echo %%j seems to be %%i Please check it.