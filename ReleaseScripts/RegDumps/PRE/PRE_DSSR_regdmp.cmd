c:\localbin\choice /t:n,10 Are you sure you want to run reg dumps?
if errorlevel 2 goto :EOF

for %%i in (
DSWBAAMRFC01                                                                                                                  DSWBMAMRCA01                                                                 
DSWBMAMRCT01                                                                 
DSWBMAMRNC01                                                                 
DSWBMAMRUS01                                                                 
DSWBMEURDE01                                                                 
DSWBMEUREU02                                                                 
DSWBMEURFR01                                                                 
DSWBMEURUK01                                                                 
DSWBOAMR01                                                                   
DSWBOEUR01                                                                   
DSWBOHTL01                                                                                                                    DSWBQHTL01   
) do (regdmp -m \\%%i hkey_local_Machine\software\expedia > \\expcpfs01\Releases\R18\Dumps\Reg_Dumps\Pre\%%i_1_21_224_reg.reg)
