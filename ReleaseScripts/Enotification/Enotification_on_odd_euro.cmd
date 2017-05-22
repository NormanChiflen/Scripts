c:\localbin\choice /t:n,10 Are you sure you want to turn on enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATEUR01
DNGATEUR03
DNTVMEUR01
DNTVMEUR03
DNTVMEUR05
DNTVHEUR01
DNTVMECT01
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_on.ini