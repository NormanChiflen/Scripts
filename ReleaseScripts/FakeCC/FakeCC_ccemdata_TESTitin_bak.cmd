c:\localbin\choice /t:n,10 Are you sure you want to copy the test ccemdata file?
if errorlevel 2 goto :EOF

for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do copy /y \\%%i\c$\travbin\server\ccemdataspoof.xml \\%%i\c$\travbin\server\ccemdata.xml 
for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do sc \\%%i stop travccsp 

echo sleeping 90 seconds
sleep 90

for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do sc \\%%i start travccsp
echo sleeping for 90 seconds
sleep 90

for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do sc \\%%i query travccsp
sleep 20

for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do sc \\%%i query travccsp
sleep 20

for /F %%i in (\\dnfil01\ServerLists\FAKECC_TEST_TVx_01s.txt) do sc \\%%i query travccsp
sleep 20