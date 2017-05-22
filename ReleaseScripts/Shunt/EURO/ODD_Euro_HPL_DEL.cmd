c:\localbin\choice /t:n,10 Are you sure you want to SHUNT the ODD Euro Webs?
if errorlevel 2 goto :EOF

for %%i in (
DNWBMEURDE01
DNWBMEURDE03
DNWBMEURDE05
DNWBMEURDE07
DNWBMEUREU01
DNWBMEUREU03
DNWBMEUREU05
DNWBMEURFR01
DNWBMEURFR03
DNWBMEURFR05
DNWBMEURFR07
DNWBMEURUK01
DNWBMEURUK03
DNWBMEURUK05
DNWBMEURUK07
DNWBMEURUK09
DNWBMEURUK11
DNWBMEURUK13
DNWBOEUR01
DNWBOEUR03

) do (
soon 130 \\%%i\c$\bin\hotfix\kill.cmd inetinfo
sc \\%%i stop gralog
sc \\%%i stop ablog
sleep 185
del \\%%i\c$\winnt\temp*.hpl)