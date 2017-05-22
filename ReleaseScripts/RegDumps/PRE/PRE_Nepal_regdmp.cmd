c:\localbin\choice /t:n,10 Are you sure you want to run reg dumps?
if errorlevel 2 goto :EOF

for %%i in (
dnwbqhtl01
dnwbqhtl02
dnwbqhtl03
dnwbqhtl04
dnwbohtl01
dnwbohtl02
dntvhhtl01
dntvhhtl02
dntvhhtl03
dntvhhtl04
dnbothtl01
dnfdshtl01
) do (
regdmp -m \\%%i hkey_local_Machine\software\expedia > \\expcpfs01\Releases\R18\Dumps\Reg_Dumps\Pre\%%i_2_11_reg.txt)
