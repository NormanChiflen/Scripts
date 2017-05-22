Option Explicit
Const OPTIONS_FILE = ".\options.txt"
Dim serverlist
Dim serversFile
Dim serversText
Dim servers
Dim server
Dim objFSO

Set objFSO = CreateObject("Scripting.FileSystemObject")
If NOT objFSO.FileExists(OPTIONS_FILE) Then
	'WScript.Echo "No options file discovered."
	CreateOptionsFile
End If

If WScript.Arguments.Count <> 1 Then
	Usage
Else
	serverlist = WScript.Arguments(0)
End If

Set serversFile = objFSO.OpenTextFile(serverlist,1)
serversText = serversFile.ReadAll()
servers = Split(serversText,vbcrlf)

WScript.Echo "Server,OS Version,RAM,C,D,E,IP"
For Each server in servers
	WScript.Echo server & "," & GetOSVersion(server) & "," & GetRAM(server) & "," & GetDrives(server) & "," & GetIP(server)
Next

Function Usage
	WScript.Echo vbtab & "***Usage :***" & vbtab
	WScript.Echo "CScript ServerQA.vbs <serverlist>"
	WScript.Echo "Where <serverlist> is the path to a file containing a list of servers."
	WScript.Quit(1)
End Function

Function CreateOptionsFile
	'WScript.Echo "Need to add code to create options file."
End Function

Function GetOSVersion (server)
	Dim returnValue
	Dim objWMI
	Dim colOS
	Dim os
	Set objWMI = GetObject("winmgmts:\\" & server & "\root\cimv2")
	Set colOS = objWMI.ExecQuery("Select Caption from Win32_OperatingSystem")
	For Each os in colOS
		returnValue = os.Caption
	Next
	Set objWMI = NOTHING
	Set colOS = NOTHING
	GetOSVersion = returnValue
End Function

Function GetRAM (server)
	Dim returnValue
	Dim objWMI
	Dim colRAM
	Dim RAM
	Dim GB
	GB = 1024 * 1024 * 1024
	Set objWMI = GetObject("winmgmts:\\" & server & "\root\cimv2")
	Set colRAM = objWMI.ExecQuery("Select TotalPhysicalMemory from Win32_ComputerSystem")
	For each RAM in colRAM
		returnValue = FormatNumber (RAM.TotalPhysicalMemory / GB, 1) & " GB"
	Next
	Set objWMI = NOTHING
	Set colRAM = NOTHING
	GetRAM = returnValue
End Function

Function GetDrives (server)
	Dim returnValue
	Dim objWMI
	Dim colDrives
	Dim drive
	Dim GB
	GB = 1024 * 1024 * 1024
	Set objWMI = GetObject("winmgmts:\\" & server & "\root\cimv2")
	Set colDrives = objWMI.ExecQuery("Select Name,Size,FreeSpace from Win32_LogicalDisk WHERE MediaType = '12'")
	For each drive in colDrives
		returnValue = returnValue & "," & drive.Name & " " & FormatNumber (drive.Size / GB, 1) & " GB"
	Next
	Set objWMI = NOTHING
	Set colDrives = NOTHING
	GetDrives = Right(returnValue,Len(returnValue)-1)
End Function

Function GetIP (server)
	Dim returnValue
	Dim objWMI
	Dim colIPs
	Dim ip
	Set objWMI = GetObject("winmgmts:\\" & server & "\root\cimv2")
	Set colIPs = objWMI.ExecQuery("Select Caption,DefaultIPGateway,IPAddress,IPSubnet from Win32_NetworkAdapterConfiguration WHERE IPEnabled = 'true'")
	For Each ip in colIPs
		returnValue = Join(ip.IPAddress) & " " & returnValue
	Next
	Set objWMI = NOTHING
	Set colIPs = NOTHING
	GetIP = returnValue
End Function