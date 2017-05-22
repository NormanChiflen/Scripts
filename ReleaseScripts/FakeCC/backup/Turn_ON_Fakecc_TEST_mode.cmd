c:\localbin\choice /t:n,10 Are you sure you want to allow fake CC processing?
if errorlevel 2 goto :EOF

call enable_web_fakecc_reg.cmd

call fakecc_ccemdata_test.cmd