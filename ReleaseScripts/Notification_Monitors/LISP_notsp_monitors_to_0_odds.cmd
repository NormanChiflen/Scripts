c:\localbin\choice /t:n,10 Are you sure you want to set lisp notsp values to 0 on Odd Travelservers?
if errorlevel 2 goto :EOF

for %%i in (
DNTVMAMR01
DNTVMAMR03
DNTVMAMR05
DNTVMAMR07
DNTVMAMR09
DNTVMAMR11
DNTVMAMR13
DNTVHAMR01
DNTVHAMR03
DNTVHAMR05
DNTVHAMR07
DNTVHAMR09
DNTVHAMR11
DNTVHAMR13
DNTVMECT01
DNTVHECT01
DNTVMEUR01
DNTVMEUR03
DNTVMEUR05
DNTVHEUR01
DNTVHEUR03
DNTVHEUR05
DNTVHECT01
DNTVMECT01
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Notification_Monitors\lisp_notsp_to_0.ini
