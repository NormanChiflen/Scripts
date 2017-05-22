c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR01
DNGATAMR03
DNTVMAMR01
DNTVMAMR03
DNTVMAMR05
DNTVMAMR07
DNTVMAMR09
DNTVMAMR11
DNTVMAMR13
DNTVHAMR01
DNTVMECT01
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_off.ini