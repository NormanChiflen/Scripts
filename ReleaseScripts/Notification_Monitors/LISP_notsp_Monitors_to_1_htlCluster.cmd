c:\localbin\choice /t:n,10 Are you sure you want to set lisp notsp values to 1 on evens?
if errorlevel 2 goto :EOF

for %%i in (
DNTVHHTL01
DNTVHHTL02
DNTVHHTL03
DNTVHHTL04
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Notification_Monitors\lisp_notsp_to_1.ini
