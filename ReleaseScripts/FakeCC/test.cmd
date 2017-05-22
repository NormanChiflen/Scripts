c:\localbin\choice /t:n,10 Are you sure you want to copy to the production ccemdata file?
if errorlevel 2 goto :EOF

for /F %%i in (\\dnfil01\ServerLists\DNTVx_EUR_ODD.txt) do copy /y \\%%i\c$\travbin\server\ccemdataprod.xml \\%%i\c$\travbin\server\ccemdata.xml 
for /F %%i in (\\dnfil01\ServerLists\DNTVx_EUR_ODD.txt) do sc \\%%i stop travccsp 

echo sleeping 30 seconds
sleep 30

for /F %%i in (\\dnfil01\ServerLists\DNTVx_EUR_ODD.txt) do sc \\%%i start travccsp
echo sleeping for 30 seconds
sleep 30

for /F %%i in (\\dnfil01\ServerLists\DNTVx_EUR_ODD.txt) do sc \\%%i query travccsp