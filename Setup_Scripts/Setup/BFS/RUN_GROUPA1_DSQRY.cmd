#Rem Syntax 1 - system roll 2 - username 3 - password

for /F %%a in (\\dnfil01\ops\Scripts\ReleaseScripts\Setup\BFS\groupA1_DSQRY.txt) do start psexec \\%%a -u expeso\%2 -p %3 c:\bin\hotfix\setup.cmd  %1 %2 %3