c:\localbin\choice /t:n,10 Are you sure you want to fix the x25comm\wssmsocketserver reg setting?
if errorlevel 2 goto :EOF
for %%i in (
DNTVMAMR02
DNTVMAMR04
DNTVMAMR06
DNTVMAMR08
DNTVMAMR10
DNTVMAMR12
DNTVMAMR14
DNTVHAMR02
DNTVHAMR04
DNTVHAMR06
DNTVHAMR08
DNTVHAMR10
DNTVHAMR12
DNTVHAMR14
DNTVMECT02
DNTVHECT02
DNTVHHTL02
DNTVHHTL04
DNGATAMR02
DNGATAMR04
DNGATAMR06
) do regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\x25comm_TVx\x25comm.ini