c:\localbin\choice /t:n,10 Are you sure you want to allow fake CC processing?
if errorlevel 2 goto :EOF

call \\dnfil01\ops\scripts\releasescripts\fakecc\fakecc_ccemdata_test.cmd