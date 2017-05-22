path=C:\Perl\bin\;C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;c:\devtools

for /f %%i in (\\dnfil01\ServerLists\DNWBMEURUKxx_ODD.txt) do start psexec \\%%i -u expeso\%1 -p %2 c:\bin\hotfix\setup.cmd AMR-WBM-US %1 %2