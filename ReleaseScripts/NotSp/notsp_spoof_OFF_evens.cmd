c:\localbin\choice /t:n,10 Are you sure you want to UnSpoof NotSP (Production Mode)?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR02
DNGATAMR04
DNGATAMR06
DNTVMAMR02
DNTVMAMR04
DNTVMAMR06
DNTVMAMR08
DNTVMAMR10
DNTVMAMR12
DNTVMAMR14
DNTVHAMR02
DNTVHAMR04
DNTVHAMR06
DNTVHAMR08
DNTVHAMR10
DNTVHAMR12
DNTVHAMR14
DNTVHECT02
DNGATEUR02
DNGATEUR04
DNTVMEUR02
DNTVMEUR04
DNTVMEUR06
DNTVHEUR02
DNTVHEUR04
DNTVHEUR06
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\NotSp\notsp_spoof_off.ini)

echo Now restarting NOTSP on all GATEWAY servers
sleep 5
