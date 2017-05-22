param($serverlistpath,$action,$bfstravbin,$newtravbin,$user,$pwd,$logfile)

$agentmmpath = "D:\agentmm.exe"

if ($action -eq 'checklogons')
{
	Foreach ($server in (Get-Content $serverlistpath))
	{
		$queryResults = (qwinsta /SERVER:$server | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)

		foreach ($queryResult in $queryResults)
		{
			if (($queryResult.ID -ne "Conn") -and ($queryResult.ID -ne "Listen"))
			{
				Write-Host $server $queryResult
			}
		} 
	}
}
elseif ($action -eq 'stopdlmgrs')
{
	Foreach ($server in (Get-Content $serverlistpath))
	{
		Write-Host "Setting $server in maintenance mode for 30 minutes"
		# & $agentmmpath -start $server -reason 10 -minutes 30
	}
	invoke-command -computername (Get-Content $serverlistpath) -filepath 'QueryServer.ps1' -argumentlist $action,$bfstravbin,$newtravbin,$user,$pwd,$logfile
}
elseif ($action -eq 'full')
{
	Foreach ($server in (Get-Content $serverlistpath))
	{
		Write-Host "Deleting existing log file on $server"
		if ((Test-Path \\$server\d$\queryserver.log))
		{
			Remove-Item \\$server\c$\queryserver.log
		}
	}

	invoke-command -computername (Get-Content $serverlistpath) -filepath 'QueryServer.ps1' -argumentlist $action,$bfstravbin,$newtravbin,$user,$pwd,$logfile
	
	start-sleep -s 10

	Foreach ($server in (Get-Content $serverlistpath))
	{
		$last = Get-Content \\$server\c$\queryserver.log | Select-Object -last 1
		Write-Host $server $last
	}
}
else
{
	Write-Host Invalid commands.
	exit 1
}