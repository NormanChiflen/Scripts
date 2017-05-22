SET LOCAL_PATH="C:\Users\swr\AppData\Local\QlikTech\QlikView\Extensions\Objects\SwitchOnOff\"
SET SERVER_PATH="D:\QV-Server\v11\Extensions\Objects\SwitchOnOff\"

REM ****************************************************************************************************************
REM COPY TO LOCAL
REM ****************************************************************************************************************
Rem Create target directory if not exists
IF NOT EXIST "%LOCAL_PATH%" (
	ECHO "Create local path: %LOCAL_PATH%"
	MKDIR "%LOCAL_PATH%"
)
REM Remove remaining files from old builds, so delete everything
DEL "%LOCAL_PATH%*.*" /S /F /Q /EXCLUDE:DynProperties.qvpp
XCOPY "$(TargetDir)*.*" "%LOCAL_PATH%" /Y /E /I

REM Delete .dll and .pdb
DEL "%LOCAL_PATH%"$(TargetFileName)
DEL "%LOCAL_PATH%"$(TargetName).pdb

REM ****************************************************************************************************************
REM COPY TO SERVER
REM ****************************************************************************************************************
REM Create target directory if not exists
IF NOT EXIST "%SERVER_PATH%" (
	ECHO "Create server path: %SERVER_PATH%"
	MKDIR %SERVER_PATH%
)
REM Remove remaining files from old builds, so delete everything
DEL "%SERVER_PATH%*.*" /S /F /Q /EXCLUDE:DynProperties.qvpp
XCOPY "$(TargetDir)*.*" "%SERVER_PATH%" /Y /E /I

REM Delete .dll and .pdb
DEL "%SERVER_PATH%"$(TargetFileName)
DEL "%SERVER_PATH%"$(TargetName).pdb
