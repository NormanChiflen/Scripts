param($server)

# Checking Powershell version
Write-Host "`nChecking Powershell version..."
$powershellversion = $PSVersionTable.PSVersion
Write-Host "Version: $powershellversion"
if ($powershellversion -lt "2.0")
{
	
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Powershell version 2.0 or greater required!"
	exit 1
}

# Setting needed values
$ScriptPath = $null
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$autorunnerpath = "\\chelt2fil01\Products\Tools\AutoRunner\autorunner.exe"
$mstravobport = "5679"

Function Get-ScriptHelp
{
    write-host "`nDisplaying help...`n"
    write-host "SCRIPT: TVARecycle.ps1"
    write-host "PURPOSE: Cycles air related services on a specified TVA server`n"
    write-host "USAGE:"
    write-host "    .\TVARecycle.ps1 -server 'SERVERNAME'"
	write-host "   OR:" 
	write-host "    powershell \\server\share\TVARecycle.ps1 -server 'SERVERNAME'`n"
    write-host "WHERE:`n"
    write-host " -server  (Required) TVA server to cycle services.`n"
    exit 1
}

# Returning help if help argument passed
if ($args -contains "-?" -or $args -contains "-help")
{
    Get-ScriptHelp
}

# Returning help if server argument is missing
if (!$server)
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: -server argument is missing!"
    Get-ScriptHelp
}

# Making sure Set-ServiceState script exists and setting path
if (!(Test-Path -path "$ScriptPath\Set-ServiceState.ps1"))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Script '$ScriptPath\Set-ServiceState.ps1' not found."
    exit 1
}

# Checking for autorunner.exe path
if (!(Test-Path -path $autorunnerpath))
{
    write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Autorunner tool '$autorunnerpath' not found."
    exit 1
}

# Checking for host connection (ping)
write-host "`n[" (get-date -format HH:mm:ss) "] Checking for server connectivity..."
write-host "[" (get-date -format HH:mm:ss) "] Pinging '$server'..."
if (!(Test-Connection $server -quiet))
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Server '$server' did not respond."
	exit 1
}
write-host "[" (get-date -format HH:mm:ss) "] Server responded."

# Verifying and cycling services
# Stopping services
write-host "`n[" (get-date -format HH:mm:ss) "] Stopping services..."
# Stopping mstravob service if exists
if (get-service -ComputerName $server -Name "mstravob" -erroraction "silentlycontinue")
{
    write-host "[" (get-date -format HH:mm:ss) "] Stopping 'mstravob' service..."
	
	if ((get-service -ComputerName $server -Name "mstravob").status -eq "stopped")
    {
        write-host "[" (get-date -format HH:mm:ss) "] 'mstravob' service already stopped."
    }
	else
	{
		(get-service -ComputerName $server -Name "mstravob").Stop()
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Service 'mstravob' does not exist on '$server'."
	exit 1
}
while ((get-service -ComputerName $server -Name "mstravob").status -ne "stopped")
{
   start-sleep -s 5
}
write-host "[" (get-date -format HH:mm:ss) "] Service stopped."

# Stopping *sp services if exist
if (get-service -ComputerName $server -Name "*sp" -Exclude "NtLmSsp" -erroraction "silentlycontinue")
{
	foreach ($service in (get-service -ComputerName $server -Name "*sp" -Exclude "NtLmSsp"))
	{	
		$service = $service.name
		write-host "[" (get-date -format HH:mm:ss) "] Stopping '$service' service..."
		if ((get-service -ComputerName $server -Name "$service").status -eq "stopped")
	    {
	        write-host "[" (get-date -format HH:mm:ss) "] '$service' service already stopped."
	    }
		else
		{
			(get-service -ComputerName $server -Name "$service").Stop()
		}
		while ((get-service -ComputerName $server -Name "$service").status -ne "stopped")
		{
		   start-sleep -s 5
		}
		write-host "[" (get-date -format HH:mm:ss) "] Service stopped."
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: No '*sp' services exist on '$server'."
	exit 1
}

# Stopping airinterfacesvc services if exist
if (get-service -ComputerName $server -Name "airinterfacesvc" -erroraction "silentlycontinue")
{
    write-host "[" (get-date -format HH:mm:ss) "] Stopping 'airinterfacesvc' service..."
	if ((get-service -ComputerName $server -Name "airinterfacesvc").status -eq "stopped")
    {
        write-host "[" (get-date -format HH:mm:ss) "] 'airinterfacesvc' service already stopped."
    }
	else
	{
		(get-service -ComputerName $server -Name "airinterfacesvc").Stop()
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Service 'airinterfacesvc' does not exist on '$server'."
	exit 1
}
while ((get-service -ComputerName $server -Name "airinterfacesvc").status -ne "stopped")
{
   start-sleep -s 5
}
write-host "[" (get-date -format HH:mm:ss) "] Service stopped."

write-host "[" (get-date -format HH:mm:ss) "] All services stopped."

# Starting services
write-host "`n[" (get-date -format HH:mm:ss) "] Starting services..."
# Starting mstravob service if exists
if (get-service -ComputerName $server -Name "mstravob" -erroraction "silentlycontinue")
{
    write-host "[" (get-date -format HH:mm:ss) "] Starting 'mstravob' service..."
	
	if ((get-service -ComputerName $server -Name "mstravob").status -eq "running")
    {
        write-host "[" (get-date -format HH:mm:ss) "] 'mstravob' service already running."
    }
	else
	{
		(get-service -ComputerName $server -Name "mstravob").Start()
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Service 'mstravob' does not exist on '$server'."
	exit 1
}
write-host "[" (get-date -format HH:mm:ss) "] Waiting for 'mstravob' to enter running state..."
while ((get-service -ComputerName $server -Name "mstravob").status -ne "running")
{
   start-sleep -s 5
}
write-host "[" (get-date -format HH:mm:ss) "] Service running."

# Checking if *sp services started
if (get-service -ComputerName $server -Name "*sp" -Exclude "NtLmSsp" -erroraction "silentlycontinue")
{
	foreach ($service in (get-service -ComputerName $server -Name "*sp" -Exclude "NtLmSsp"))
	{	
		$service = $service.name
		write-host "[" (get-date -format HH:mm:ss) "] Waiting for '$service' to enter running state..."
		while ((get-service -ComputerName $server -Name "$service").status -ne "running")
		{
		   start-sleep -s 5
		}
		write-host "[" (get-date -format HH:mm:ss) "] Service running."
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: No '*sp' services exist on '$server'."
	exit 1
}

# Starting airinterfacesvc services if exist
if (get-service -ComputerName $server -Name "airinterfacesvc" -erroraction "silentlycontinue")
{
    write-host "[" (get-date -format HH:mm:ss) "] Starting 'airinterfacesvc' service..."
	if ((get-service -ComputerName $server -Name "airinterfacesvc").status -eq "running")
    {
        write-host "[" (get-date -format HH:mm:ss) "] 'airinterfacesvc' service already running."
    }
	else
	{
		(get-service -ComputerName $server -Name "airinterfacesvc").Start()
	}
}
else
{
	write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Service 'airinterfacesvc' does not exist on '$server'."
	exit 1
}
write-host "[" (get-date -format HH:mm:ss) "] Waiting for 'airinterfacesvc' to enter running state..."
while ((get-service -ComputerName $server -Name "airinterfacesvc").status -ne "running")
{
   start-sleep -s 5
}
write-host "[" (get-date -format HH:mm:ss) "] Service running."

write-host "[" (get-date -format HH:mm:ss) "] All services running."

try
{
	# Open the socket, and connect to the computer on the specified port
	write-host "`n[" (get-date -format HH:mm:ss) "] Connecting to '$server' on port '$mstravobport'"
	$socket = new-object System.Net.Sockets.TcpClient($server, $mstravobport)
	if($socket -eq $null)
	{
		write-host -foregroundcolor Red "[" (get-date -format HH:mm:ss) "] ERROR: Could not connect."
		return;
	}
	
	write-host "[" (get-date -format HH:mm:ss) "] Socket connected."
}
catch
{
	write-host -foregroundcolor Red "`n[" (get-date -format HH:mm:ss) "] ERROR: Could not connect to host '$server' on port '$mstravobport'."
	Write-Host "Error Message: $error"
	exit 1
}

write-host "`n[" (get-date -format HH:mm:ss) "] Trying autorunner..."
&$autorunnerpath -s $server -t Search.DLL


