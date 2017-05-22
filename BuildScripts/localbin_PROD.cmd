mkdir c:\localbin
%windir%\system32\cscript \\FILEIDX\OpsDepot\Provisioning\software\localBin\localbin.vbs
%systemdrive%\localbin\xcacls.exe c:\localbin /G Administrators:F /Y