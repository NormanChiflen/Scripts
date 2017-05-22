%WINDIR%\System32\cscript.exe //Nologo //S
mkdir %systemdrive%\temp
call \\chc-filidx\glappeng\jegilbert\BuildScripts\localbin_PROD.cmd
call \\chc-filidx\glappeng\jegilbert\BuildScripts\emainpath_PROD.cmd
call \\chc-filidx\glappeng\jegilbert\BuildScripts\regACL_PROD.cmd


notepad c:\temp\%COMPUTERNAME%_SERVERBUILD.txt
choice /t 5 /D n /M "Server build is complete. Would you like to reboot?"
if %errorlevel%==2 goto eof

%systemdrive%\localbin\reboot.exe /L /R /T:30

choice /t 20 /D n /M "Do you want to ABORT thr Reboot?"
if %errorlevel%==1 goto abort


:abort
%systemdrive%\localbin\reboot.exe /A
goto eof

:eof
exit

