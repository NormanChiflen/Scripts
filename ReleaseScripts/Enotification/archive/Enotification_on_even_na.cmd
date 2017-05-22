c:\localbin\choice /t:n,10 Are you sure you want to turn on enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR02
DNGATAMR04
DNGATAMR06
DNGATAMR08
DNGATAMR10
DNGATAMR12
DNGATAMR14
DNGATAMR16
DNGATAMRCT02
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_on.ini