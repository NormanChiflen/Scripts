@REM Created 5/13/05 by John McAfee -  johnmca@expedia.com
@REM 
@REM 
@REM This script is to be used when a server is to be decommishioned replaced
@REM 
@REM This script will capture server information ipconfig, srvinfo and remove server from the Domain
@REM All information will be logged to \\DNFIL01\Ops\Decomm_Server_Info


mkdir \\DNFIL01\Ops\Decomm_Server_Info\%computername%

ipconfig /all > \\dnfil01\ops\Decomm_server_info\%computername%\%computername%_ipconfig.txt
srvinfo \\%computername% > \\dnfil01\ops\Decomm_server_info\%computername%\%computername%_srvinfo.txt

if exist c:\compaq\survey\survey.txt (
copy c:\compaq\survey\survey.txt \\dnfil01\ops\Decomm_server_info\%computername%\survey.txt) ELSE (copy c:\compaq\hpdiags\survey*.xml \\dnfil01\ops\Decomm_server_info\%computername%\)

copy %systemroot%\system32\drivers\etc\hosts \\dnfil01\ops\Decomm_server_info\%computername%\hosts
copy %systemroot%\system32\drivers\etc\hosts \\dnfil01\ops\Decomm_server_info\%computername%\lmhosts
route print > copy %systemroot%\system32\drivers\etc\hosts \\dnfil01\ops\Decomm_server_info\%computername%\routeprint.txt
regdmp -m \\%computername% hkey_local_machine\software\expedia >  \\dnfil01\ops\Decomm_server_info\%computername%\expedia_regkey.ini

