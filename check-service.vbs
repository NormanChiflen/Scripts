'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalScript 2009
'
' NAME: Windows Service Recovery Configuration Check
'
' AUTHOR: Pete Zerger, MVP
' DATE  : 3/15/2010
'
' COMMENT: Checks to see if service is configured to 'automatically restart'
'          in case of service failure. Use in a two-state monitor targeting
'          a Windows operating system class.
'==========================================================================

OPTION EXPLICIT
'ON ERROR RESUME NEXT

'Declare constants 
Const EVENT_TYPE_ERROR = 1 
Const EVENT_TYPE_WARNING = 2 
Const EVENT_TYPE_INFORMATION = 4

'Declare variables 
Dim objShell, objFSO, objTextFile 
Dim strTempDir, strTempFile, iReturn, bolRestart 
Dim oArgs, objAPI, objBag, StateDataType
Dim strScriptPath, objScriptFile
Dim ServiceName 

'********************************************************
'CONFIGURATION REQUIRED - Update name of service to check
'********************************************************
Set oArgs = WScript.Arguments

'Instantiate MOMScriptAPI and Create PropertyBag 
Set objAPI = CreateObject("MOM.ScriptAPI")
Set objBag = objAPI.CreateTypedPropertyBag(StateDataType)

If oArgs.Count <> 1 Then
    ' If the script is called without the required arguments,
    ' create an information event and then quit.
    Call objAPI.LogScriptEvent("ServiceRestartConfig.vbs", 10101, EVENT_TYPE_ERROR, _
    "ServiceRestartConfig script was called with fewer than one arguement(s)")
    WScript.Quit 
End If

 'ServiceName = "Spooler"
ServiceName = oArgs.Item(0)

'********************************************************
'END CONFIGURATION
'********************************************************

 bolRestart = 0


'Create Wscript Shell object (for running sc.exe)and FileSystemObject
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strScriptPath = WScript.ScriptFullName
Set objScriptFile = objFSO.GetFile(strScriptPath)
strScriptPath = objFSO.GetParentFolderName(objScriptFile)

'Check for existence of temp working directory
strTempDir = strScriptPath
'strTempDir = "c:\windows\temp"
'WScript.Echo "1. " & strTempDir

strTempFile = strTempDir + "\svcconfigtemp.txt"
'WScript.Echo "2. " & strTempFile

checkTempDir(strTempDir)

'Delete text file if it already exists 
FileCopyCleanup strTempDir

'Dump recovery properties of the desired service
iReturn = objShell.Run("%comspec% /C sc.exe qfailure " & ServiceName & " > """ & strTempFile & """", 0, True)

'Create FileSystemObject (for reading / parsing text file containing sc.exe output)
Set objFSO = CreateObject("Scripting.FileSystemObject")

'Open text file
Set objTextFile = objFSO.OpenTextFile(strTempFile, 1)

'If file not found or cannot be opened, log an error.
If Err.Number <> 0 Then 
wscript.echo "Error: " &  Err.Description
Call objAPI.LogScriptEvent("SvcConfigRestart.vbs",4500, EVENT_TYPE_ERROR , Err.Description)
Wscript.quit
End If

'Check for RESTART in service recovery options
While Not objTextFile.AtEndofStream
     If InStr(objTextFile.ReadLine, "RESTART") Then bolRestart = 1
Wend

'*******************************
'Determine and set monitor state
'*******************************
 
If bolRestart = 1 Then
	Call objBag.AddValue("State","GOOD")
	Call objAPI.Return(objBag)

Else 
	Call objBag.AddValue("State","BAD")
	Call objAPI.Return(objBag)
End If

'Clean up work
objTextFile.Close
'objFSO.DeleteFile (strTempFile)
Call FileCopyCleanup(strTempDir) 

'***************************************************************************************
'* Function: FileCopyCleanup
'* Purpose: Deletes temporary directory created by the FileCopy function
'***************************************************************************************
function FileCopyCleanup(strTempDir)

Dim objFSO1

Set objFSO1 = CreateObject("Scripting.FileSystemObject")

	if (objFSO1.FileExists(strTempDir & "\svcconfigtemp.txt")) Then
		objFSO1.DeleteFile(strTempDir & "\svcconfigtemp.txt")
	 	If Err.Number <> 0 Then
			Call objAPI.LogScriptEvent("SvcConfigRestart.vbs", 4451, EVENT_TYPE_ERROR, Err.Description )
			WSCript.Quit
		End if
	End If

End Function

'***************************************************************************************
'* Function: checkTempDir
'* Purpose: Checks for existence of temporary directory. If absent, temp directory is created.
'***************************************************************************************

Function checkTempDir(strTempDir)
	Dim objFSO
	
	Set objFSO = WScript.CreateObject("Scripting.FileSystemObject")
	
	On Error Resume Next
	Set oArgs = WScript.Arguments

	If (objFSO.FolderExists(strTempDir) = False) Then
		objFSO.CreateFolder(strTempDir)
	 	If Err.Number <> 0 Then
			Call objAPI.LogScriptEvent("SvcConfigRestart.vbs", 4451, EVENT_TYPE_ERROR, _
			"Unexpected Error Occured when attempting to create temp directory: " & VbCrLf & _
			"Error Number: " & Err.Number & VbCrLf & "Error Description: " & Err.Description )		
			WSCript.Quit
		End if
	End If
	On Error GoTo 0 
	
	Set objFSO = Nothing
	
End Function
