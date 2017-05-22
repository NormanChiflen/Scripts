c:\localbin\choice /t:n,10 Are you sure you want to turn on enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR02
DNGATAMR04
DNTVMAMR02
DNTVMAMR04
DNTVMAMR06
DNTVMAMR08
DNTVMAMR10
DNTVMAMR12
DNTVMAMR14
DNTVHAMR02
DNTVHECT02
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_on.ini