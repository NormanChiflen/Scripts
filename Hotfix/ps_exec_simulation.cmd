REM %1 is Username, %2 is Password
path=C:\WINNT\SYSTEM32;C:\WINNT;C:\WINNT\SYSTEM32\WBEM;C:\LOCALBIN;C:\ResKit\;c:\devtools
start psexec \\DNBOTAMR01 -u expeso\%1 -p %2 -p %2 c:\bin\hotfix\setupsim.cmd AMR-BOT %1 %2 
start psexec \\DNBOTCT01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd CORP-BOT %1 %2 

REM ************* added 01 to the end of AMR-FDS 1/17/05 nluong
REM start psexec \\DNFDSAMR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-FDS %1 %2
start psexec \\DNFDSAMR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-FDS-01 %1 %2
start psexec \\DNFDSAMR02 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-FDS-02 %1 %2



start psexec \\DNGATAMR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-GAT-PCLSVC %1 %2
start psexec \\DNWBAAMRFC01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBA-FC1 %1 %2
start psexec \\DNWBMAMRCA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBM-CA %1 %2
start psexec \\DNWBMAMRCT01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBM-CT %1 %2
start psexec \\DNWBMAMRNC01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBM-NC %1 %2
start psexec \\DNWBMAMRUS01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBM-US %1 %2
start psexec \\DNWBOAMR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBO-Paybot %1 %2

start psexec \\DNDIRBFS01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd BFS-DIR %1 %2
start psexec \\DNBFD03 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd BFS-DST %1 %2
start psexec \\DNPREBFS01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd BFS-PRE %1 %2
start psexec \\DNBFQFA0103 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd BFS-QRY-FA %1 %2
start psexec \\DNBFQFB0103 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd BFS-QRY-FB %1 %2

start psexec \\DNBOTEUR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-BOT %1 %2

REM ********** removed from sim runs 3/24/05 aaronb)
REM start psexec \\DNCABEURDE01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-CAB-DE %1 %2

REM ********** removed from sim runs 5/4/04 johnmca)
REM start psexec \\DNCABEURUK01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-CAB-UK %1 %2
REM
REM *************** added 01 and 02 to the end of AMR-EUR 1/18/05 nluong ***
start psexec \\DNFDSEUR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-EUR-01 %1 %2
start psexec \\DNFDSEUR02 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-EUR-02 %1 %2

start psexec \\DNGATEUR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-GAT-PCLSVC %1 %2
start psexec \\DNWBMEURDE01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-WBM-DE %1 %2
start psexec \\DNWBMEUREU01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-WBM-EU %1 %2
start psexec \\DNWBMEURFR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-WBM-FR %1 %2
start psexec \\DNWBMEURUK01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-WBM-UK %1 %2
start psexec \\DNWBOEUR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-WBO %1 %2

start psexec \\DNWBMOPI01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd OPI-WBM %1 %2
start psexec \\DNUTLPER01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd PER-UTL %1 %2
start psexec \\DNYDC01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd YDC %1 %2

REM  ************* added from sim runs 1/17/05 nluong
start psexec \\DNTVMAMR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVM-ODD %1 %2
start psexec \\DNTVHEUR01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-TVH %1 %2

start psexec \\DNTVHEUR03 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-TVH %1 %2
start psexec \\DNTVMEUR04 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd EUR-TVM %1 %2

start psexec \\DNTVHAMR03 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVH %1 %2


start psexec \\DNTVMECT02 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVM-ECT-EVEN %1 %2
start psexec \\DNTVHECT01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVH-ECT %1 %2

REM **************Nepal Servers************************
start psexec \\DNTVHHTL01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVH-HTL %1 %2
start psexec \\DNWBOHTL01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBO-HTL %1 %2
start psexec \\DNWBQHTL02 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBQ %1 %2
start psexec \\DNBOTHTL01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd HTL-BOT %1 %2
start psexec \\DNFDSHTL01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd HTL-FDS %1 %2

REM **************Sherpa Servers************************
start psexec \\DNTVHTPA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-TVH-HTL %1 %2
start psexec \\DNWBOTPA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBO-HTL %1 %2
start psexec \\DNWBWTPA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd AMR-WBQ %1 %2
start psexec \\DNBOTTPA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd HTL-BOT %1 %2
start psexec \\DNFDSTPA01 -u expeso\%1 -p %2 c:\bin\hotfix\setupsim.cmd HTL-FDS %1 %2
