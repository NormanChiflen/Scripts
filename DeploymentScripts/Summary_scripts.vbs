' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      Summary_scripts.vbs
' // 
' // Version:   5.1.1642.01
' // 
' // Purpose:   Scripts to initialize and validate summary wizard
' // 
' // ***************************************************************************

Option Explicit

Dim iErrors
Dim iWarnings
Dim sBuffer
Dim bFirst

Function InitializeSummary

	bFirst = True


	' If this is a replace, then modifiy the title

	if Property("DeploymentType") = "REPLACE" then
		NormalTitle.style.display = "none"
		ReplaceTitle.style.display = "inline"
	end if

	' Set the background color based on the return code

	If oEnvironment.Item("RETVAL") = "0" or oEnvironment.Item("RETVAL") = "" then
		' OK
	Else
		MyContentArea.style.backgroundColor = "salmon"
	End if


	' Initialize the error and warning count

	iErrors = 0
	iWarnings = 0


	' Process the current log

	ProcessLog oUtility.LogPath & "\" & oLogging.MasterLogFile


	' No errors found in the master log file, but the task sequence failed?  If so, try to process the BDD.LOG in PE (?).

	If oEnvironment.Item("RETVAL") <> "0" and (iErrors = 0 or iWarnings = 0) Then
		ProcessLog "X:\MININT\SMSOSD\OSDLOGS\BDD.LOG"
	End if


	' If the task sequence failed, process the task sequence log

	If oEnvironment.Item("RETVAL") <> "0" then

		If oFSO.FileExists(oEnvironment.Item("SMSTSLogPath_Cache") & "\SMSTS.LOG") then
			ProcessLog oEnvironment.Item("SMSTSLogPath_Cache") & "\SMSTS.LOG"
		ElseIf oFSO.FileExists(oEnvironment.Item("_SMSTSLogPath") & "\SMSTS.LOG") then
			ProcessLog oEnvironment.Item("_SMSTSLogPath") & "\SMSTS.LOG"
		ElseIf oFSO.FileExists(oEnv("TEMP") & "\SMSTS.LOG") then
			ProcessLog oEnv("TEMP") & "\SMSTS.LOG"
		End if

	End if

		
	' Update the dialog

	ErrorCount.InnerText = CStr(iErrors)
	WarningCount.InnerText = CStr(iWarnings)
	optionalWindow1.InnerText = sBuffer
	buttonCancel.disabled = true


	' Set the background color to yellof if success and errors and warnings.

	If oEnvironment.Item("RETVAL") = "0" or oEnvironment.Item("RETVAL") = "" then
		If iErrors > 0 or iWarnings > 0 then
			MyContentArea.style.backgroundColor = "yellow"
		End if
	End if

End Function

Function ProcessLog(sLog)

	Dim oLog
	Dim sLine
	Dim sMessage
	Dim sDetails
	Dim sType
	Dim sFile
	Dim sComponent
	Dim bProcess


	' Make sure the file exists

	If not oFSO.FileExists(sLog) then
		Exit Function
	End if


	' Process the file

	Set oLog = oFSO.OpenTextFile(sLog)
	While not oLog.AtEndOfStream

		' Split apart the message
		bProcess = false
		sLine = oLog.ReadLine
		If Instr(sLine, "<![LOG[") > 0 then  ' Line beginning found

			If Instr(sLine, "]LOG]!>") = 0 then  ' No end label found, start of multiline message
				sMessage = Mid(sLine, 8)
			Else
				sMessage = Mid(sLine, 8, Instr(sLine, "]LOG]!>") - 8)
				sDetails = Mid(sLine, Instr(sLine, "]LOG]!>") + 7)
				sType = Mid(sDetails, Instr(sDetails, "type=""") + 6, 1)
				bProcess = true
			End if

		Else  ' No line beginning found, continuation

			If Instr(sLine, "]LOG]!>") = 0 then  ' No end label found, start of multiline message
				sMessage = sMessage & vbNewLine & sLine
			Else
				sMessage = sMessage & vbNewLine & Left(sLine, Instr(sLine, "]LOG]!>") - 1)
				sDetails = Mid(sLine, Instr(sLine, "]LOG]!>") + 7)
				sType = Mid(sDetails, Instr(sDetails, "type=""") + 6, 1)
				sFile = Mid(sDetails, Instr(sDetails, "file=""") + 6)
				sFile = Left(sFile, Instr(sFile, """") - 1)
				sComponent = Mid(sDetails, Instr(sDetails, "component=""") + 11)
				sComponent = Left(sComponent, Instr(sComponent, """") - 1)
				bProcess = true
			End if

		End if


		' Inspect the type

		If bProcess then

			' Add the message to the details display

			If sType > "1" then

				If Instr(1, sMessage, "_SMSTaskSequence", 1) > 0 or Instr(1, sFile, "executionenv.cxx", 1) > 0 or Instr(1, sFile, "environmentlib.cpp", 1) > 0 then
					' Ignore these messages
				Else
					' Increment the counter

					Select Case sType
					Case "3"
						iErrors = iErrors + 1
					Case "2"
						iWarnings = iWarnings + 1
					End Select


					' Add a header when appropriate

					If bFirst and Instr(1, sLog, "smsts", 1) > 0 then
						oStrings.AddToList sBuffer, vbNewLine & "Messages from the task sequence engine:" & vbNewLine, vbNewLine
						bFirst = False
					End if


					' Add the string to the list

					oStrings.AddToList sBuffer, sMessage, vbNewLine

				End if
			End if

		End if

	WEnd

	oLog.Close
	Set oLog = Nothing

End Function
