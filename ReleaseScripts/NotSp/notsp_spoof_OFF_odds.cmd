c:\localbin\choice /t:n,10 Are you sure you want to UnSpoof NotSP (Production Mode)?
if errorlevel 2 goto :EOF

echo Now stopping NOTSP on all GATEWAY and travel servers
sleep 5

for %%i in (
DNGATAMR01
DNGATAMR03
DNGATAMR05
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
DNTVHECT01
DNGATEUR01
DNGATEUR03
DNTVMEUR01
DNTVMEUR03
DNTVMEUR05
DNTVHEUR01
DNTVHEUR03
DNTVHEUR05
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\NotSp\notsp_spoof_off.ini)
