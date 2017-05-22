rem install Message Queuing
rem %windir%\system32\sysocmgr.exe /i:%windir%\inf\sysoc.inf /u:%temp%\ocm.txt /r /q

powershell set-executionpolicy Unrestricted

cd D:

mkdir D:\Maps

\\CHELBFSUTL25\d$\batch\SCOM\amd64\KARMALAB_install_SCOMAgent-x64.cmd


pause