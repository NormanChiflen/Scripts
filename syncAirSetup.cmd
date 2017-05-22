@ECHO OFF
:: This is designed to only run on CHELT2FIL01 in F:\DeployTools\AirSetup

set _P4USERNAME=svc.t2.builder
set _P4PASSWORD=PW4T2Builder

:: Get to the right directory
pushd f:\DeployTools\AirSetup

echo ******************************************************************************
echo Starting Update Process at %date% %time% 
echo ****************************************************************************** 

echo %_P4PASSWORD%| p4.exe -u %_P4USERNAME% -C utf16le-bom -Q winansi -s login

p4.exe -u %_P4USERNAME% -C utf16le-bom -Q winansi -s sync ...

:: End Successfully
echo ****************************************************************************** >> syncCatalyst.log.txt 2>&1
echo Ending Update Process at %date% %time% >> syncCatalyst.log.txt 2>&1
echo ****************************************************************************** >> syncCatalyst.log.txt 2>&1

popd
exit /b 0
