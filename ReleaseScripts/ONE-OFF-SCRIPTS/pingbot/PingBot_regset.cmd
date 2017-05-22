path= C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;C:\MICROSOFT SITE SERVER\BIN;C:\CRS30\BIN;C:\Program Files\Microsoft SQL Server\80\Tools\BINN;C:\Program  Files\SecureCRT\;C:\PROGRA~1\SecureFX;C:\ResKit\;C:\PROGRA~1\CA\Common\SCANEN~1;C:\PROGRA~1\CA\eTrust\ANTIVI~1;c:\devtools;C:\Perl\bin\;"
sc \\dnbotamr01 stop pingbot
for %%i in (1 2) do regini -m \\dnbotamr0%%i c:\pingbot.txt
sleep 10
sc \\dnbotamr01 start pingbot