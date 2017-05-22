@echo off

setlocal

set mydate=%date:~4%
set mytime=%time::=%

set mydate=%mydate: =%
set mytime=%mytime: =%

rem --- Location of Convoy, Plugins and Perl --------------------------------
set CONVOY_HOME=\\karmalab.net\builds\Depreps\release\convoy\convoy-0.5.1
set PLUGINS_HOME=\\karmalab.net\builds\depreps\releasecandidate\convoy-plugins\convoy-plugins-0.8.23
set PERL_HOME=\\karmalab.net\builds\Depreps\thirdparty\perl\MSWin32\5.8.8

rem --- Add bin to path -----------------------------------------------------
set PATH=%PERL_HOME%\bin;%CONVOY_HOME%\bin;%PLUGINS_HOME%\bin;%PATH%
set PERL5LIB=%CONVOY_HOME%\lib;%CONVOY_HOME%\lib\ext;%PLUGINS_HOME%\lib;%PLUGINS_HOME%\lib\ext
set PERLLIB=

rem --- Run Convoy ----------------------------------------------------------
perl %CONVOY_HOME%\bin\convoy.pl %* 

endlocal

exit /B %ERRORLEVEL%


