c:\localbin\choice /t:n,10 Are you sure you want to UnSpoof NotSP (Production Mode)?
if errorlevel 2 goto :EOF

for %%i in (
DNGATAMR01
DNGATAMR02
DNGATAMR03
DNGATAMR04
DNGATAMR05
DNGATAMR06
DNGATAMR07
DNGATAMR08
DNGATAMR09
DNGATAMR10
DNGATAMR11
DNGATAMR12

) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\one-off\pcl_notsp.ini)

