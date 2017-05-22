param($serverlistpath, $version, $source, $destdir)

$retHash = @{}

Foreach ($server in (Get-Content $serverlistpath))
{
	& ".\PreCopy.ps1" $version $source \\$server\$destdir
	$retHash[$server] = $LastExitCode
}

Foreach ($server in (Get-Content $serverlistpath))
{
	if ($retHash[$server] -eq 0)
	{
		write-host $server precopy successful.
	}
	else
	{
		write-host -foregroundcolor Red $server precopy failed.
	}
}