c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR01
DNGATAMR02
DNGATAMR03
DNGATAMR04
DNGATAMR05
DNGATAMR06
DNGATAMR07
DNGATAMR08
DNGATAMR09
DNGATAMR10
DNGATAMR11
DNGATAMR12
DNGATAMR13
DNGATAMR14
DNGATAMR15
DNGATAMR16
DNGATAMR17
DNGATAMR18
DNGATAMR19
DNGATAMR20
DNGATEUR01
DNGATEUR02
DNGATEUR03
DNGATEUR04
DNGATEUR05
DNGATEUR06
DNGATEUR07
DNGATEUR08
DNGATEUR09
DNGATEUR10
DNGATEUR11
DNGATEUR12
DNGATAMRCT01
DNGATAMRCT02
) do regini -m \\%%i \\dnfil01\ops\scripts\ReleaseScripts\Notsp_LISP\LISP_ON.ini
