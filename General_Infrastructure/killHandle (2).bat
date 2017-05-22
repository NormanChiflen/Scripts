@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

if "%1" equ "" @echo Pass EXE name of process to kill && goto :eof
for /f "tokens=3,4skip=5" %%i in ('handle.exe %1') do (
  set pd=%%i 
  set c=%%j
  set c=!c:~0,-1!
  
  @echo c = !c!
  handle.exe -p %pd% -c !c! -y
  )
  
 @echo on