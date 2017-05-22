Echo syntax = delgra.cmd username password

for /f %%i in (\\dnfil01\serverlists\even_webs.txt) do start psexec  \\%%i -u expeso\%1 -p %2 c:\bin\hotfix\delgralog.cmd