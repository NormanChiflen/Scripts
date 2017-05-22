c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATEUR02
DNGATEUR04
DNTVMEUR02
DNTVMEUR04
DNTVMEUR06
DNTVHEUR02
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_off.ini