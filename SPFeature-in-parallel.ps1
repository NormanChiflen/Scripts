workflow Enable-SPFeatureInParallel {
    param(
        [string[]]$urls,
        [string]$feature
    )
 
    foreach -parallel($url in $urls) {
        InlineScript {
            # Write-Host doesn't work within a workflow
            Write-Output "BEGIN: $(Get-Date) Processing $($using:url)..."
 
            # We're in a new process so load the snap-in
            Add-PSSnapin Microsoft.SharePoint.PowerShell
 
            # Enable the custom feature
            Enable-SPFeature -Identity $using:feature -Url $using:url
            
            Write-Output "END: $(Get-Date) Processing $($using:url)."
        }
    }
}
Enable-SPFeatureInParallel (Get-SPSite -Limit All).Url "MyCustomFeature"