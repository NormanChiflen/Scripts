# //***************************************************************************
# // ***** Script Header *****
# //
# // Solution:  Config Mgr 2007
# // File:      Crate-Maintanance-Window.ps1
# // Author:	Jakob Gottlieb Svendsen, Coretech A/S. http://blog.coretech.dk
# // Purpose:
# //
# //
# // Usage:     .ps1
# //
# //
# // CORETECH A/S History:
# // 1.0.0     JGS 26/09/2011  Created initial version.
# //
# // Customer History:
# //
# // ***** End Header *****
# //***************************************************************************
# //----------------------------------------------------------------------------
#//
#//  Global constant and variable declarations
#/
#//----------------------------------------------------------------------------
cls
#Create maintanance Window
$SCCM_SERVER = "CTSCCM01"
$SCCM_SITECODE = "DK1"
$COLLECTION_ID = "DK1000D1"

#maintanance window info
#read more about the values here
# http://msdn.microsoft.com/en-us/library/cc143300.aspx
$serviceWindowName = "Scorch software update window"
$serviceWindowDescription = "Temporary window for software compliance runbook"
$serviceWindowServiceWindowSchedules = "001A9A7BB8100008" # 00:00:00 - 23:59:00 - Every day
$serviceWindowIsEnabled = $true
$serviceWindowServiceWindowType = 1

#//----------------------------------------------------------------------------
#//  Main routines
#//----------------------------------------------------------------------------

#create splatting package with wmi info.
$SccmWmiInfo = @{
	Namespace = "root\SMS\site_$SCCM_SITECODE"
	ComputerName = $SCCM_SERVER
}

$collsettings = Get-WmiObject @SccmWmiInfo -Query "Select * From SMS_CollectionSettings Where CollectionID = '$COLLECTION_ID'" 

if (!$collsettings)
{
	$collsettings = ([WMIClass] "\\$SCCM_SERVER\root\SMS\site_$($SCCM_SITECODE):SMS_CollectionSettings").CreateInstance()
	$collsettings.CollectionID = $COLLECTION_ID
	$collsettings.Put()
}

#Get lazy properties
$collsettings.Get();

#new service window
$serviceWindow = ([WMIClass] "\\$SCCM_SERVER\root\SMS\site_$($SCCM_SITECODE):SMS_ServiceWindow").CreateInstance()
$serviceWindow.Name = $serviceWindowName
$serviceWindow.Description = $serviceWindowDescription
$serviceWindow.ServiceWindowSchedules = $serviceWindowServiceWindowSchedules
$serviceWindow.IsEnabled = $serviceWindowIsEnabled
$serviceWindow.ServiceWindowType = $serviceWindowServiceWindowType

$collsettings.ServiceWindows += $serviceWindow.psobject.baseobject 

$collsettings.Put()

#http://blog.coretech.dk/jgs/powershell-configmgr-2007-create-maintenance-window/

#//----------------------------------------------------------------------------
#//  End Script
#//----------------------------------------------------------------------------
