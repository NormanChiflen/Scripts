c:\localbin\choice /t:n,10 Are you sure you want to Spoof NOTSP on ALL Gateway Servers (Test Mode)?
if errorlevel 2 goto :EOF

for %%i in (
DNTVHEUR03
DNTVMEUR04
DNTVHAMR03
DNTVMBTA03
DNTVMECT02
DNTVHECT02
DNTVHHTL01
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\NotSp\notsp_spoof_on.ini)

echo Now restarting NOTSP on all GATEWAY servers
echo sleep 5
remcall restart_notsp.cmd