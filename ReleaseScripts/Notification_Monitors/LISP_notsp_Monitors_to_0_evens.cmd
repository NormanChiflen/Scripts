c:\localbin\choice /t:n,10 Are you sure you want to set lisp notsp values to 0 on evens?
if errorlevel 2 goto :EOF

for %%i in (
DNTVMAMR02
DNTVMAMR04
DNTVMAMR06
DNTVMAMR08
DNTVMAMR10
DNTVMAMR12
DNTVMAMR14
DNTVHAMR02
DNTVHAMR04
DNTVHAMR06
DNTVHAMR08
DNTVHAMR10
DNTVHAMR12
DNTVHAMR14
DNTVMECT02
DNTVHECT02
DNTVMEUR02
DNTVMEUR04
DNTVMEUR06
DNTVHEUR02
DNTVHEUR04
DNTVHEUR06
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Notification_Monitors\lisp_notsp_to_0.ini
