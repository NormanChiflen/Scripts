@echo off

type \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\HTL\Set_All_In_Rotation\readme.txt

c:\localbin\choice /t:n,10 Would you like to view\modify the server list file?

if errorlevel 2 goto :Reg

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\HTL\Set_All_In_Rotation\netview.txt


:Reg
c:\localbin\choice /t:n,10 Would you like to view\modify the registry INI file?

if errorlevel 2 goto :Run

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\HTL\Set_All_In_Rotation\htl.ini


:Run

c:\localbin\choice /t:n,10 Are you sure you continue with this Travel Server Rotation?

if errorlevel 2 goto :EOF

for /f %%i in (\\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\HTL\Set_All_In_Rotation\netview.txt) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\HTL\Set_All_In_Rotation\htl.ini
