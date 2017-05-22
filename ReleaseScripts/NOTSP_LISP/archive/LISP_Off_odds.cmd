c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR01
DNGATAMR03
DNGATAMR05
DNGATAMR07
DNGATAMR09
DNGATAMR11
DNGATAMR13
DNGATAMR15
DNGATAMR17
DNGATAMR19
DNGATEUR01
DNGATEUR03
DNGATEUR05
DNGATEUR07
DNGATEUR09
DNGATEUR11
DNGATAMRCT01
) do regini -m \\%%i \\dnfil01\ops\scripts\ReleaseScripts\NOTSP_LISP\lisp_off.ini
