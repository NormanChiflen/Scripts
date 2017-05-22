Option Explicit
CONST FOR_READING = 1
CONST FOR_WRITING = 2

Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim CFilePath
CFilePath = "\C$\splunk\etc\system\local\inputs.conf"
Dim DFilePath
DFilePath = "\D$\splunk\etc\system\local\inputs.conf"

Dim splunkServices
splunkServices = "splunkd,splunkforwarder"

Dim serversFile, serverList, serversText, serversArray, server
If WScript.Arguments.Count <> 1 Then
	Usage
	WScript.Quit(1)
End If

serversFile = WScript.Arguments(0)

Set serverList = objFSO.OpenTextFile(serversFile,FOR_READING)

serversText = serverList.ReadAll()

serversArray = Split(serversText,vbcrlf)

For Each server in serversArray
	If objFSO.FileExists("\\" & server & CFilePath) Then
		UpdateConfFile server,CFilePath
	End If
	If objFSO.FileExists("\\" & server & DFilePath) Then
		UpdateConfFile server,DFilePath 
	End If
Next

Set serverList = NOTHING
Set objFSO = NOTHING

Function Usage
	WScript.Echo "Usage:"
	WScript.Echo "CScript updateSplunk.vbs <servers file>"
End Function

Function UpdateConfFile(serverName,confFilePath)
	WScript.Echo "Updating \\" & serverName & confFilePath
	'Variables needed to get contents of the file
	Dim file,fileContents
	Dim updateFSO
	Set updateFSO = CreateObject("Scripting.FileSystemObject")
	Set file = updateFSO.OpenTextFile("\\" & serverName & confFilePath,FOR_READING)
	'Get all of the file contents into a string
	fileContents = file.ReadAll()
	'Close the file so we can reopen to write to it later
	file.Close
	
	Dim pattern
	Dim regex
	Dim matches, match
	Dim submatches, submatch
	'We are expecting a file which contains host = servername
	pattern = "host = ([\w-]+)"
	Set regex = new regexp
	regex.pattern = pattern
	
	'Check for a match to the regular expression
	If regex.Test(fileContents) Then
		Set matches = regex.Execute(fileContents)
		For Each match in matches
			'Grab the submatch, which contains just the server name
			Set submatches = match.Submatches
			For Each submatch in submatches
				'Replace the old server name with the new server name
				fileContents = Replace(fileContents,submatch,serverName)
			Next
		Next
		'Open the file to write out the updated contents
		Set file = updateFSO.OpenTextFile("\\" & serverName & confFilePath,FOR_WRITING)
		file.Write(fileContents)
		file.Close
	End If

	'Clean up objects
	Set regex = NOTHING
	Set matches = NOTHING
	Set file = NOTHING
	Set updateFSO = NOTHING
End Function