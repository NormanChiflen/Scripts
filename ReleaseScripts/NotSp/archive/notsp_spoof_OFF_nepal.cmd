c:\localbin\choice /t:n,10 Are you sure you want to UnSpoof NotSP (Production Mode)?
if errorlevel 2 goto :EOF

for %%i in (
DNTVHHTL01
DNTVHHTL02
DNTVHHTL03
DNTVHHTL04
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\NotSp\notsp_spoof_off.ini)

echo Now restarting NOTSP on all GATEWAY servers
sleep 5
