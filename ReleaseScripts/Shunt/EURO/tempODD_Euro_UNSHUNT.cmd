c:\localbin\choice /t:n,10 Are you sure you want to shunt the odd Euro Webs?
if errorlevel 2 goto :EOF

for %%i in (

DNWBMEUREU01
DNWBMEUREU03
DNWBMEUREU05

) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Shunt\WSShuntOff.ini)