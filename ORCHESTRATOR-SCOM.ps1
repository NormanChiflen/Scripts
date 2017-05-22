#http://www.systemcentercentral.com/scorch-automatically-reset-unhealthy-unit-monitors-closed-in-error-by-a-human/


# Import Operations Manager Module and create Connection
Import-Module OperationsManager
New-SCOMManagementGroupConnection ms1.contoso.com

#Retrieve alert maching criteria
 $AlertId=”{ID from “Monitor Alert”}“ 
$alerts = Get-SCOMAlert | where { $_.id -eq $AlertId}

#Loop through the trigger alerts (should really only be one)

foreach ($alert in $alerts)

{

 # Retrieve IDs of the monitor, target class and instance
$MonitorID = $alert.monitoringruleid
$TargetClassID = $alert.monitoringclassid
$ObjectID = $alert.monitoringobjectid

#Retrieve the monitor, target class and instance
$monitor = Get-SCOMMonitor | where {$_.id -eq $MonitorID}
$monitoringclass = Get-SCOMClass | where {$_.id -eq $TargetClassID}
$monitoringobject = Get-SCOMMonitoringobject -class $monitoringclass | where {$_.id -eq $ObjectID}

#Reset Monitor
$monitoringobject | foreach{$_.ResetMonitoringState($monitor)}

}