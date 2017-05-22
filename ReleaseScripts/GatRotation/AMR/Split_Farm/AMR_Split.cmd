@echo off

type \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\readme.txt

c:\localbin\choice /t:n,10 Would you like to view\modify the server list file?

if errorlevel 2 goto :Reg

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\odd_servers.txt
notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\even_servers.txt


:Reg
c:\localbin\choice /t:n,10 Would you like to view\modify the registry INI file?

if errorlevel 2 goto :Run

notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\odd_amr.ini
notepad \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\even_amr.ini


:Run

c:\localbin\choice /t:n,10 Are you sure you continue with this Travel Server Rotation?

if errorlevel 2 goto :EOF

for /f %%i in (\\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\even_servers.txt) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\EURO\Split_Euro\even_amr.ini
for /f %%i in (\\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\AMR\Split_Farm\odd_servers.txt) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\GatRotation\EURO\Split_Euro\odd_amr.ini
