c:\localbin\choice /t:n,10 Are you sure you want to UN-SHUNT ALL Nepal Servers?
if errorlevel 2 goto :EOF

for %%i in (
dnwbqhtl01
dnwbqhtl02
dnwbqhtl03
dnwbqhtl04
dnwbohtl01
dnwbohtl02
) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Shunt\WSShuntoff.ini)