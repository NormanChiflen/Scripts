$jobThreshold = 10

foreach ($site in (Get-SPSite -Limit All)) {
    # Get all running jobs
    $running = @(Get-Job | where { $_.JobStateInfo.State -eq "Running" })

    # Loop as long as our running job count is >= threshold
    while ($running.Count -ge $jobThreshold) {
        # Block until we get at least one job complete
        $running | Wait-Job -Any | Out-Null
        # Refresh the running job list
        $running = @(Get-Job | where { $_.JobStateInfo.State -eq "Running" })
    }

    Start-Job -InputObject $site.Url {
        $url = $input | %{$_}
        Write-Host "BEGIN: $(Get-Date) Processing $url..."

        # We're in a new process so load the snap-in
        Add-PSSnapin Microsoft.SharePoint.PowerShell

        # Enable the custom feature
        Enable-SPFeature -Url $url -Identity MyCustomFeature

        Write-Host "END: $(Get-Date) Processing $url."
    }
    # Dump the results of any completed jobs
    Get-Job | where { $_.JobStateInfo.State -eq "Completed" } | Receive-Job

    # Remove completed jobs so we don't see their results again
    Get-Job | where { $_.JobStateInfo.State -eq "Completed" } | Remove-Job
}