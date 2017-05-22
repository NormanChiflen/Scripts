c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
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
DNGATAMR18
DNGATAMR20
DNGATEUR02
DNGATEUR04
DNGATEUR06
DNGATEUR08
DNGATEUR10
DNGATEUR12
DNGATAMRCT02
) do regini -m \\%%i \\dnfil01\ops\scripts\ReleaseScripts\NOTSP_LISP\lisp_off.ini
