c:\localbin\choice /t:n,10 Are you sure you want to UnSpoof NotSP (Production Mode)?
if errorlevel 2 goto :EOF

echo Now stopping NOTSP on all Travel and GATEWAY servers
sleep 5

for %%i in (
DNTVMAMR01
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
dngatamr01
dngatamr03
dngateur01
dngateur03
DNTVHHTL01
DNTVHHTL02
DNTVHHTL03
DNTVHHTL04
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\NotSp\notsp_spoof_off.ini)
