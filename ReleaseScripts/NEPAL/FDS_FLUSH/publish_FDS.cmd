c:\localbin\choice /t:n,10 Are you sure you want to Flush ALL FDS Cache Files?
if errorlevel 2 goto :EOF

for /F %%a in (\\dnfil01\ops\Scripts\ReleaseScripts\NEPAL\FDS_FLUSH\speed_publ_FDSServerlist.txt) do regini -m \\%%a \\dnfil01\ops\Scripts\ReleaseScripts\NEPAL\FDS_FLUSH\fds_update_normal.txt