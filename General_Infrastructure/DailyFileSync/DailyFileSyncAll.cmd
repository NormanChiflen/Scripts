for /f "tokens=*" %%a in ('date /t') do (set shortDate=%%a)
set dt=%shortDate:/=%
set dt=%dt: =%
set dt=%dt:~3%

set log=c:\cct_ops\logroot\syncjob\DailyFileSync.%computername%.%dt%.log

if not exist c:\cct_ops\logroot\syncjob\ md c:\cct_ops\logroot\syncjob\

@Echo -- starting filesync -->>%log%


date /t>>%log%
time /t>>%log%
@Echo .. dailyfilesyncna.cmd ..>>%log%
start /wait cmd /c \\chelappsbx001\d$\Public\DailyFilesSync\dailyfilesyncna.cmd %1
sleep 1
time /t>>%log%
@Echo .. dailyfilesynceur.cmd ..>>%log%
start /wait cmd /c \\chelappsbx001\d$\Public\DailyFilesSync\dailyfilesynceur.cmd %1
sleep 1
time /t>>%log%
@Echo .. dailyfilesyncapac.cmd ..>>%log%
start /wait cmd /c \\chelappsbx001\d$\Public\DailyFilesSync\dailyfilesyncapac.cmd %1
time /t>>%log%
@Echo -- Ending -->>%log%
@Echo.>>%log%

:copy
copy %log% \\chelappsbx001\d$\Public\DailyFilesSync\logs /y