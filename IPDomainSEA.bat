@echo off

ipconfig /release
timeout 2
netsh interface ip set address name="Local Area Connection" static 10.184.79.%2 255.255.255.0 10.184.79.1 0
Timeout 2
netsh interface ip set dns "Local Area Connection" static 10.184.77.23
netsh interface ip add dns "Local Area Connection" 10.184.77.24
Timeout 2
ipconfig /registerdns
Timeout 2

rem Joining the domain:
Netdom.exe join %1 /d:sea.corp.expecn.com /ou:OU=CHANDLER,OU=Windoes2008R2,OU=Servers,DC=CORP,DC=EXPECN,DC=com /UserD:sea\%3 /PasswordD:%4

net localgroup Administrators sea\T2OPS /add

pause