for /F %%a in (\\dnfil01\ops\Scripts\ReleaseScripts\Setup\BFS\groupUKB1_QRY.txt) do start psexec \\%%a -u expeso\%2 -p %3 c:\bin\hotfix\setup.cmd  %1 %2 %3