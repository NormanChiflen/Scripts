<#
.SYNOPSIS
   TestBackupThreads.ps1
   
.DESCRIPTION
   This script is used to conduct and time a series of backups using different thread counts.
   The output can then be used to make an educated decision on the number of backup threads to
   assign for use in farm-level backups.
.NOTES
   Author: Sean McDonough
   Last Revision: 25-July-2012
.PARAMETER TestLocation
   A UNC path to a location that can be used to create test backup sets
.EXAMPLE
   TestBackupThreads \\FileShare\TestLocation
#   http://sharepointinterface.com/tag/powershell/
#>
param 
(
	[string]$TestLocation = "$(Read-Host 'UNC path to test backup location [e.g. \\FileShare\TestLocation]')"
)

function TestThreads($backupLocation)
{
	# Ensure that the SharePoint cmdlets are loaded before continuing
	$spCmdlets = Get-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction silentlycontinue
	if ($spCmdlets -eq $Null)
	{ Add-PSSnapin Microsoft.SharePoint.PowerShell }
	
	# Setup some variables we'll need for execution.
	$threadTimes = @{}									# Hash table to hold timing results
	$backupItems = Join-Path $backupLocation "spbr*"	# Used to delete temp backup files
	
	# We need to execute a full farm backup for each thread count 1 through 10
	Clear-Host
	Write-Host "`nBackup thread count testing process beginning."
	for ($threads = 1; $threads -lt 11; $threads++)
	{
		# Clean out any backup contents from the test location
		Remove-Item $backupItems -recurse

		# Grab the starting date/time (for later comparison), kick-off a farm backup, and then
		# grab the stop date/time.
		Write-Host "`nInitiating a backup with $threads thread(s) ..."
		$startPoint = Get-Date
		Backup-SPFarm -BackupMethod Full -Directory $backupLocation -BackupThreads $threads
		$stopPoint = Get-Date

		# Store and report results
		$keyName = "Backup with {0} thread(s)" -f $threads
		$elapsedSeconds = "{0:N0}" -f ($stopPoint - $startPoint).TotalSeconds
		$threadTimes[$keyName] = $elapsedSeconds
		Write-Host "Backup with $threads thread(s) complete"
		Write-Host ("- time to complete (in seconds): {0}" -f $elapsedSeconds)
	}
	
	# Do a final sweep of the test backup location to clean out backup items
	Remove-Item $backupItems -recurse

	# Dump the results sorted in order of quickest to longest
	Write-Host "`nBackup thread count testing process complete."
	$threadTimes.GetEnumerator() | Sort-Object Value

	# Abort script processing in the event an exception occurs.
	trap
	{
		Write-Warning "`n*** Script execution aborting. See below for problem encountered during execution. ***"
		$_.Message
		break
	}
}

# Launch script
TestThreads $TestLocation
