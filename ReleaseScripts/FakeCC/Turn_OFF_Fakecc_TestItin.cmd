c:\localbin\choice /t:n,10 Are you sure you want to turn off fake CC processing (Production Mode)?
if errorlevel 2 goto :EOF

call disable_web_fakecc_reg.cmd

call fakecc_ccemdata_prod.cmd