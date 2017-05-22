@echo off

type \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\ALL_In\readme.txt

c:\localbin\choice /t:n,10 Would you like to view\modify the server list file?

if errorlevel 2 goto :Reg

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\ALL_In\netview.txt


:Reg
c:\localbin\choice /t:n,10 Would you like to view\modify the registry INI file?

if errorlevel 2 goto :Run

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\ALL_In\amr.ini


:Run

c:\localbin\choice /t:n,10 Are you sure you continue with this Travel Server Rotation?

if errorlevel 2 goto :EOF

rem for /f %%i in (\\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\ALL_In\netview.txt) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\ALL_In\amr.ini
