c:\localbin\choice /t:n,10 Are you sure you want to turn on enotification?
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
DNGATAMRCT01
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Enotification\enotification_on.ini