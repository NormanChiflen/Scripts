c:\localbin\choice /t:n,10 Are you sure you want to UNSHUNT ODD NA Servers?
if errorlevel 2 goto :EOF

for %%i in (
DNWBAAMRFC01
DNWBMAMRCA01
DNWBMAMRCA03
DNWBMAMRCA05
DNWBMAMRCA07
DNWBMAMRCT01
DNWBMAMRCT03
DNWBMAMRNC01
DNWBMAMRNC03
DNWBMAMRNC05
DNWBMAMRUS01
DNWBMAMRUS03
DNWBMAMRUS05
DNWBMAMRUS07
DNWBMAMRUS09
DNWBMAMRUS11
DNWBMAMRUS13
DNWBMAMRUS15
DNWBMAMRUS17
DNWBMAMRUS19
DNWBMAMRUS21
DNWBMAMRUS23
DNWBMAMRUS25
DNWBMAMRUS27
DNWBMAMRUS29
DNWBMAMRUS31
DNWBMAMRUS33
DNWBMAMRUS35
DNWBMAMRUS37
DNWBMAMRUS39
DNWBMAMRUS41
DNWBMAMRUS43
DNWBMAMRUS45
DNWBMAMRUS47
DNWBMAMRUS49
DNWBMAMRUS51
DNWBMAMRUS53
DNWBMAMRUS55
DNWBMAMRUS57
DNWBMAMRUS59
DNWBMOPI01
DNWBMOPI03
DNWBOAMR01
DNWBOAMR03

) do (
regini -m \\%%i \\dnfil01\ops\Scripts\ReleaseScripts\Shunt\WSShuntoff.ini)
