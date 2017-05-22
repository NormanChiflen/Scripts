“.cmd” extension and change as appropriate:
:setvar NUMBEROFROWS 15
GOTO startofpolyglotsqlbatch /*
:startofpolyglotsqlbatch
@echo off
sqlcmd.exe -S MySqlServer -E -e -i “%~f0? -o “%~f0.log”
more “%~f0.log”
goto endofpolyglotsqlbatch
:: */
startofpolyglotsqlbatch:
USE MyDb;
GO
SELECT TOP $(NUMBEROFROWS) * FROM MyTable;
GO
/*
:endofpolyglotsqlbatch
:: */