c:\localbin\choice /t:n,10 Are you sure you want to turn off enotification?
if errorlevel 2 goto :EOF

for /F %%i in (web_list.txt)  do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\FakeCC\EnableCC.ini