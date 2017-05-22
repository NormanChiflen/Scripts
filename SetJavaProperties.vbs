'	SetJavaProperties.vbs
'
'	It will look for a template file named argument0.template
'
'	For each argument1+ that is passed in:
'	1. Look for the value on the left side of the equality
'	2. Set the value of that property with the right side of the equality
'
'	The properties template file should look like this:
'		com.expedia/outgoingDestinationName=<outgoingDestinationName>.com.expedia
'		With the below command in the usage section, it will replace <outgoingDesitnationName> with PMP15
'
'	Usage:
'		cscript SetJavaProperties.vbs bus-carbsbridge-jms.environment.properties outgoingDestinationName=PMP15
'
'	Created:
'		KoichiT - 2007-05-01

Option Explicit

Dim objFSO
Dim strFileName
Dim objFile
Dim strText
Dim strNewText
Dim arrOptions
Dim idxArguments
Dim fFailedToSetProperty

' Check that all required arguments have been passed.
If Wscript.Arguments.Count < 2 Then
	Wscript.Echo "Arguments required. For example:" & vbCrLf & "cscript SetJavaProperties.vbs bus-carbsbridge-jms.environment.properties.test outgoingDestinationName=PMP15"
	Wscript.Quit(1)
End If

strFileName = Wscript.Arguments(0)
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Open the file to read from.
On Error Resume Next
Set objFile = objFSO.OpenTextFile(strFileName & ".template", 1)
If Err.Number <> 0 Then
	Wscript.Echo "File " & strFileName & ".template" & " cannot be opened to read." & vbCrLf
	Wscript.Echo "Failed to run FileSystemObject.OpenTextFile with error " & Err.Number & "."
	Wscript.Quit(Err.Number)
End If

strText = objFile.ReadAll
objFile.Close

' For each argument 1+, set the property value in the file
For idxArguments = 1 to Wscript.Arguments.Count - 1

	On Error Resume Next
	arrOptions = Split(Wscript.Arguments(idxArguments), "=", 2)
	If StrComp(arrOptions(1), "") = 0 Then
		Wscript.Echo "2nd+ arguments should be in the form SomePropertyName=SomePropertyValue"
		Wscript.Quit(1)
	End If

	strNewText = Replace(strText, "<" & arrOptions(0) & ">", arrOptions(1))

	If StrComp(strText, strNewText) = 0 Then
		Wscript.Echo strFileName & ": " & arrOptions(0) & " was not replaced"
		fFailedToSetProperty = true
	End If

	strText = strNewText

Next

' If we failed to set some property, fail
If fFailedToSetProperty Then
	Wscript.Quit(1)
End If

' Open the file to write to.
On Error Resume Next
Set objFile = objFSO.OpenTextFile(strFileName, 2, true)
If Err.Number <> 0 Then
	Wscript.Echo "File " & strFileName & " cannot be opened to write. Error code: " & Err.Number & vbCrLf
	Wscript.Echo "Failed to run FileSystemObject.OpenTextFile with error " & Err.Number & "."
	Wscript.Quit(Err.Number)
End If

objFile.Write strText
objFile.Close
