c:\localbin\choice /t:n,10 Are you sure you want to copy to the test ccemdata file?
if errorlevel 2 goto :EOF

for /F %%i in (Gat_list.txt) do copy /y \\%%i\c$\travbin\server\ccemdataspoof.xml \\%%i\c$\travbin\server\ccemdata.xml 
for /F %%i in (Gat_list.txt) do sc \\%%i stop travccsp 

echo sleeping 90 seconds
sleep 90

for /F %%i in (Gat_list.txt) do sc \\%%i start travccsp
echo sleeping for 90 seconds
sleep 90

for /F %%i in (Gat_list.txt) do sc \\%%i query travccsp
sleep 20

for /F %%i in (Gat_list.txt) do sc \\%%i query travccsp
sleep 20

for /F %%i in (Gat_list.txt) do sc \\%%i query travccsp
sleep 20