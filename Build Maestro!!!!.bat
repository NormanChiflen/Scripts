###############################################################################
:: Project        :  Multipurpose Compilation Scripts.
::
:: Copyright 2010 Frazer-Nash UK Integrated Systems (Frazer-NashUK Proprietary)
::
:: Name           : Component_References
::
:: Date						: 02/04/2010
:: Classification : UKR
::
:: Description    :
:: TODO: Add Class/Package Description
::
:: Author         : Norman Fletcher
::
###############################################################################--------------------------------------------------------------------------------


GOTO Glossary

#DEFUNCT
:: <Current_Int> =I300.xx   ::	Current_Int = I300.xx   ::	promoteVers = int03.00.00.xx   
::	<previous_Build> = int03.00.00.(## - 1)    ::	<promote_form> = *.csv

:Glossary




:: Setting parameters - local environment variable
setlocal
set Current_Int=I300.xx
set promoteVers=Int03.00.00.xx
set previous_Build= I300.YY

:: Makes sure the Q: drive is mapped
net use Q: \\SDEADM01\BUILDSHARE

pause
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


# 1. Tag/assign Labels to all relevant files in VM ----------------------------------------------------------------------------

:: Check in a workfile put		::Check in a workfile even if it is unchanged put -f
::Check the workfile in and immediately out with a lock put -l
::Assign a revision number put -r			::Assign a version label put -v
::Specify a change description put -m 		::Specify a workfile description put -t
::Check the workfile in and immediately out without a lock put -u

:: pcli put -prY:\\R3 -idrli<>:<> -vint03.00.00.xx -z /Taxi/C_Component/ -rInt03.00.00.YY
::pause




# 2. Demote files (first tag all files) from VM -------------------------------------------------------------------------------
:: pcli DeleteLabel -prY:\\R3 -idrli<username>:<password> -vInt03.00.00.xx -z /Taxi/C_Component/File/ -rInt03.00.00.YY",
::pause



# 3.	Creates all folders needed for the build process--------------------------------------------------------------------------

MD Q:\Promote\%promoteVers%
MD Q:\Promote\%promoteVers%\Common
MD Q:\Promote\%promoteVers%\Saga
MD Q:\Promote\%promoteVers%\Taxi
MD Q:\Int\%Current_Int%
MD Q:\Int\%Current_Int%\Windows_Build

pause


# 4.	Moves the promotes form once promoted to the batch file ------------------------------------------------------------------

move "Q:\Promote\<promote_form>" "Q:\Promote\%promoteVers%\"

pause



# 5. Get all requisite files from VM to the right folder location -------------------------------------------------------------------
:: pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\I300.xx\ -vI300.xx -z -pp/ Saga (RELACEMENT FOR BELOW IF NON-FUNCTIONAL)

pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\ -v%Current_Int% -z -pp/ Saga
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\ -v%Current_Int% -z -pp/ Taxi
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\ -vintwin -z -pp/ Windows_Code
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\SRS -v%Current_Int% -z -pp/ SRS_Taxiort
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\Common -v%Current_Int% -z -pp/ Common
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\Taxilementation_Interfaces -v%Current_Int% -z -pp/ Taxilementation_Interfaces
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\Windows_Build -vintwin -z -pp/ Windows_Build
pcli run -q get -prY:\R3 -idrli<username>:<password> -aQ:\Int\%Current_Int%\Int_Build -v%Current_Int% -z -pp/ Integrity_Build
pause


# 6. copy all requisite start-up /Exora /Database - -------------------------------------------------------------------------
copy "Q:\Int\%previous_Build%\Windows_Build\generate_controller_ini.bat" "Q:\Int\%Current_Int%\Windows_Build\generate_controller_ini.bat"
copy "Q:\Int\%previous_Build%\Windows_Build\controller_default.ini" "Q:\Int\%Current_Int%\Windows_Build\controller_default.ini"
copy "Q:\Int\%previous_Build%\Windows_Build\Start_TMC.lnk" "Q:\Int\%Current_Int%\Windows_Build\Start_TMC.lnk"

# copy across necessary Exora source codes.
Xcopy "Q:\Int\%previous_Build%\Exora" "Q:\Int\%Current_Int%\Exora" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\Exora_Common" "Q:\Int\%Current_Int%\Exora_Common" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\C_Coop_Tacnav" "Q:\Int\%Current_Int%\C_Coop_TacNav" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\C_FlyTo_Tacnav" "Q:\Int\%Current_Int%\C_FlyTo_TacNav" /E /C /R /I /K /Y

# copy the database folders.
Xcopy "Q:\Int\%previous_Build%\Windows_Build\C_Tactical_Database\Database" "Q:\Int\%Current_Int%\Windows_Build\C_Tactical_Database\Database" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\Windows_Build\C_Tactical_Database\Taxi" "Q:\Int\%Current_Int%\Windows_Build\C_Tactical_Database\Taxi" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\Windows_Build\C_Tactical_Database_Replica\Database" "Q:\Int\%Current_Int%\Windows_Build\C_Tactical_Database_Replica\Database" /E /C /R /I /K /Y
Xcopy "Q:\Int\%previous_Build%\Windows_Build\C_Tactical_Database_Replica\Taxi" "Q:\Int\%Current_Int%\Windows_Build\C_Tactical_Database_Replica\Taxi" /E /C /R /I /K /Y

::pause


# 7. Create a text file that creates the PTR list --------------------------------------------------------------------------

ECHO Common >Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log
dir Q:\Promote\%VERSION%\Common /b /s >>Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log
ECHO Taxi >>Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log
dir Q:\Promote\%VERSION%\Taxi /b /s >>Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log
ECHO Saga >>Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log
dir Q:\Promote\%VERSION%\Saga /b /s >>Q:\Promote\%VERSION%\PTRs_in_Promote_Int0x.xx.log

pause


# 8. Copies all the BAE files from the latest delivery to the current folder -----------------------------------------------

Xmove "Q:\Int\BAE_Delivery\Exora" "Q:\Int\%Current_Int%" /E /C /R /I /K /Y

pause



# 9. move all BAE delivery to current directory -------------------------------------------------------------------------
MOVE Q:\Int\BAE_Delivery\Source\Exora_Common "Q:\Int\%Current_Int%"
MOVE Q:\Int\BAE_Delivery\Exora "Q:\Int\%Current_Int%"
MOVE Q:\Int\BAE_Delivery\Exora.ofa "Q:\Int\%Current_Int%\Int_Build\Exora\Exora.ofa"
pause





# 9. THE BUILDER/COMPILATION -----------------------------------------------------------------------------

REM Build
REM cscript Q:\scripts\Build.vbs -group -d Q:\Int\I210.04 All > All.log
REM cscript Q:\scripts\Build.vbs -group -win -d Q:\Int\I210.04 All > Win_All.log
REM cscript Q:\scripts\Build.vbs -win -d Q:\Int\I210.04 CL C_Dummy_Host_Controller > Win_Dummy.log


REM cscript Q:\scripts\Build.vbs -d q:\int\r3_s -g 3 Taxi > int_Taxi.log
REM cscript Q:\scripts\Build.vbs -d q:\int\r3_s -g 3 -win Saga > win_Saga.log
REM cscript Q:\scripts\Build.vbs -d q:\int\r3_s -g 3 -rel Taxi > rel_Taxi.log
REM cscript Q:\scripts\Build.vbs -d q:\int\r3_s -g 3 -dev Taxi > dev_Taxi.log
REM cscript Q:\scripts\Build.vbs -d q:\int\r3_s -g 3 -stub Taxi >stub_Taxi.log
REM pause





# 10. REPORT WARNINGS-------------------------------------------------------------------------------------------


:: dir "Q:\Int\I2.0.22" /s /ta /a-d | findstr /s -n warning *.* > Allwarning.log

:: dir "Q:\Int\I2.0.22\Integrity_Build\" /s /ta /a-d | findstr /s -n warning *.* > IntegrityWarning.log

:: dir "Q:\Int\I2.0.22\Windows_Build" /s /ta /a-d | findstr /s -n warning *.* > WindowsWarning.log

REM move Q:\Int\I2.0.22\Windows_Build\WindowsWarning.log   Q:\Int\Build Scripts\BuildWarning\WindowsWarning.log

REM move Q:\Int\I2.0.22\Integrity_Build\IntegrityWarning.log   Q:\Int\Build Scripts\BuildWarning\IntegrityWarning.log

REM move Q:\Int\I2.0.22\Allwarning.log   Q:\Int\Build Scripts\BuildWarning\SourceCodewarning.log
::pause





# 11. REPORT COMPONENTS THAT FAILED -------------------------------------------------------------------------
::Q:

# Windows_Build check
::cd Q:\Int\%Current_Int%\Windows_Build

::findstr /s /n /e  failed  *.* build.out > CheckFailed.txt 2>&1


#Integrity_Build check
::cd Q:\Int\%Current_Int%\Int_Build
::findstr /s /n /e  failed  *.* build.out

REM findstr /s /n /E /C /R /I /K /Y failed *.* build.out > CheckFailed.txt 2>&1
 ::pause




# 12. COMPARE .OFAS & .elfs FOR RELEASE PTA BUILD--------------------------------------------------------
::c:
::cd \GHS\PPC423
::ECHO "update window properties to Screen Buffer Size Width 110 Height 200 and Window Size Width 110 Height 80"
::pause
::REM gbincmp -nodebug -v Q:\Simon\I212.03\Int_Build\Taxi\Taxi.elf Q:\Int\I212.03\Int_Build\Taxi\Taxi.elf
::gbincmp -nodebug -v Q:\Rel\R2.1.1\Int_Build\Taxi\Taxi.elf Q:\Rel\R2.1.1\Images\Taxi.elf
::pause
::REM gbincmp -nodebug -v Q:\Simon\I212.03\Int_Build\Saga\Saga.elf Q:\Int\I212.03\Int_Build\Saga\Saga.elf
::gbincmp -nodebug -v Q:\Rel\R2.1.1\Int_Build\Saga\Saga.elf Q:\Rel\R2.1.1\Images\Saga.elf 
::pause