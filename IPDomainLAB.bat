@echo off
REM If [%1]==[] Goto Error


ipconfig /release
netsh interface ip set address name="Local Area Connection" static 10.184.52.161 255.255.255.0 10.184.52.1 0
netsh interface ip set dns "Local Area Connection" static 10.184.50.253
netsh interface ip add dns "Local Area Connection" 10.184.50.254
ipconfig /registerdns

rem Joining the domain:
Netdom.exe join %COMPUTERNAME% /d:karmalab.net /ou:OU=LabOps,OU=T2,OU=Win2008,DC=karmalab,DC=net /UserD:karmalab.net\_MSProj /PasswordD:Expedia!1

net localgroup Administrators karmalab\T2TLS /add
net localgroup Administrators karmalab\BuildProp /add
net localgroup Administrators sea\s-msproj /add

goto End

:Error
echo You need to specify the IP for the server
echo.

:End