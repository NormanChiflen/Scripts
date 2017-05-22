@echo off
SETLOCAL

:: Release Scripts Directory

SET StartDir=dnfil01\ops\Scripts\ReleaseScripts\Bedrock_IVR

:: Server Lists Directory

SET SrvListLoc=dnfil01\ServerLists

:: Servers to be shunted are All IVR Web Application servers

SET WebAppServers=ALL_IVR_WEBS.txt

:: Choice Dialog

choice /t:n,10 Are you sure you want to shunt All IVR Nodes 
if errorlevel 2 goto :EOF

:: Overwriting config.xml with Shunt - config.xml

for /f %%i in (\\%SrvListLoc%\%WebAppServers%) do (
attrib -R \\%%i\d$\wwwroot\Advocate\config\config.xml
copy /y \\%%i\d$\wwwroot\Advocate\config\shunt\config.xml \\%%i\d$\wwwroot\Advocate\config\config.xml
attrib +R \\%%i\d$\wwwroot\Advocate\config\config.xml
)

:: Time stamp

now > \\%StartDir%\message.txt

:: Misc messages for log file

echo. >> \\%StartDir%\message.txt

echo All IVR Nodes Shunt completed >> \\%StartDir%\message.txt

echo. >> \\%StartDir%\message.txt

echo Shunt applied to the following servers: >> \\%StartDir%\message.txt

echo. >> \\%StartDir%\message.txt

type \\%SrvListLoc%\%WebAppServers% >> \\%StartDir%\message.txt

echo. >> \\%StartDir%\message.txt
echo. >> \\%StartDir%\message.txt
echo. >> \\%StartDir%\message.txt

echo ********************* >> \\%StartDir%\shunt_unshunt.log

echo. >> \\%StartDir%\shunt_unshunt.log

type \\%StartDir%\message.txt >> \\%StartDir%\shunt_unshunt.log

echo Note: You may close this text file >> \\%StartDir%\message.txt

notepad \\%StartDir%\message.txt

ENDLOCAL