'how to run?
'http://systemcentersupport.blogspot.co.uk/2011/11/vbscript-to-monitor-specific-service-on.html
'-create a separate folder name it anything
'-create a txt file name as compname.txt (in case of me, I have used this name under script)
'-Input all servers name inside the compname.txt file
'-copy and paste the script in notepad and save it as .vbs
'-double click on the .vbs file
'-log file with current date and time will be automatically generated and you can see the service status inside.

'script to monitor specific service on multiple Windows Servers
'script created by Atul Mishra
'pls check the automatically generated log file for service status
Dim sDate
Dim strTime
Dim strDate
Dim strState
Dim strDataIn           'Input list from text file
Dim aryData                     'Array to hold input stream
Dim iCounter            'Iterative loop counter
dim strOUT                      'Output file
Dim oWshShell           'Windows shell script 
Dim objFSO                      'Scripting File System 
Dim objFile                     'Open text file
Dim strFilePath         'Path to current directory
Dim strServiceName      'Name of service to be checked
 
Set oWshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
strFilePath = objFSO.GetAbsolutePathName(".")
 
'Get Service Name
strServiceName = InputBox("Enter name of service...", "Service name input")
 
'Read file into a variable
strDataIn = f_r(strFilePath & "\compname.txt")

'Split into an array
aryData = Split(strDataIn,vbCrLf) 
oWshShell.Popup Ubound(aryData) + 1 & " Hosts/Addresses in list." & Chr(13) & "Scan is underway.",2,"Notice",64
sDate = Date
strTime = Now
StrDate = DatePart("m",sDate) & "." & DatePart("d",sDate) & "." & Hour(strTime) & "." & Minute(strTime)
set strOUT = objFSO.CreateTextFile(strFilePath & "\SERVICEResults." & strDate & ".log")
strOUT.WriteLine strServiceName & " query results:"
strOUT.WriteBlankLines (2)
For iCounter = 0 to Ubound(aryData)
 aryData(iCounter) = Trim(aryData(iCounter)) ' clean "white space"
If GetService(aryData(iCounter), strServiceName) then
        strOUT.Write aryData(iCounter) & ",Installed : " & strState & vbcrlf
Else
        strOUT.Write aryData(iCounter) & ",Service not present" & vbcrlf
End if
Next
strOUT.Close 
set strOUT = nothing
set objFSO = nothing
oWshShell.Popup "Scan processing complete.",5,"Notice",64
WScript.quit
   
'Given the path to a file,  this function will return entire contents
Function f_r(FilePath)
Dim FSO
Set FSO = CreateObject("Scripting.FileSystemObject")
  f_r = FSO.OpenTextFile(FilePath,1).ReadAll
End Function
'Returns True or False based on the status of the specified Service
Function GetService(strComputer, strSrvce)
On Error Resume Next
Dim objWMIService
Dim colListOfServices
Dim objService
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colListOfServices = objWMIService.ExecQuery _
    ("Select DisplayName,State from Win32_Service Where Name = '" & strSrvce & "'")
If Err.Number <> 0 Then
  GetService = "False"
  Err.Clear
Else
For Each objService in colListOfServices
  GetService  = "True"
  strState  = objService.State
Next
End If
End Function 