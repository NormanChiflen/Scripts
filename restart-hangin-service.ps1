Start-Job -ScriptBlock {Restart-Service -Name "ColdFusion 9 ODBC Server" -Force }

#give it 5 seconds to stop
Start-Sleep -Seconds 10

$SERVICESTATE = (Get-Service | where{$_.Name -eq "ColdFusion 9 ODBC Server"}).Status
if( $SERVICESTATE -eq "Stopping" -or $SERVICESTATE -eq "StopPending")
{
    # still stopping so force process stop
    Stop-Process -Name "swsoc" -Force
} 

#give it 5 seconds to start before we try it again
Start-Sleep -Seconds 5

$SERVICESTATE = (Get-Service | where{$_.Name -eq "ColdFusion 9 ODBC Server"}).Status
if( $SERVICESTATE -eq "Stopped" )
{
    Start-Service -Name "ColdFusion 9 ODBC Server" -Force
}
 
# Save it as a .ps1 file. Make sure PowerShell allows execution of local scripts (in PowerShell, run “set-executionpolicy remotesigned”).
 
# To schedule this to run, create a new scheduled task:
 # » Triggered daily at a particular time, repeat every hour for 1 day.
 # » Action is to run a program: 
# “C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe”
 # » Arguments contain the script name: “-File c:\Path\To\Script.ps1?
 # » Set to run as Administrator, with highest permissions
# http://walt.therices.org/index.php/2012/11/scripted-restart-of-a-hanging-windows-service/
#http://www.powershellcommunity.org/Forums/tabid/54/aft/5243/Default.aspx
 