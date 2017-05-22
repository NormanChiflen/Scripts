On Error Resume Next
‘Sets object shell/File for later use.
Set objShell=CreateObject(“Wscript.Shell”)
Set objFile = CreateObject(“Scripting.FileSystemObject”)

‘Sets Current User profile path
strUserProfile=objShell.ExpandEnvironmentStrings(“%USERPROFILE%”)

‘Sets up for HKCU registry edits
const HKEY_CURRENT_USER = &H80000001
strComputer = “.”
Set oReg=GetObject(“winmgmts:{impersonationLevel=impersonate}!\\” &_
strComputer & “\root\default:StdRegProv”)

‘Queries WMI for OS caption (aka name)
strComputer = “.”
Set objWMIService = GetObject(“winmgmts:{impersonationLevel=impersonate}!\\” & strComputer & “\root\cimv2″)
Set oss = objWMIService.ExecQuery (“Select * from Win32_OperatingSystem”)

‘Checks WMI caption and puts into the StrOS string
For Each os in oss
StrOS=os.Caption
Next

‘Checks if the StrOS string contains “XP”, to determine if XP or not. Then sets file and reg paths to Java files/settings based on OS.
If InStr(StrOS, “XP”) Then
StrJavaRegKeyPath=”Software\JavaSoft\DeploymentProperties”
StrJavaDeploymentPropertiesPath= strUserProfile & “\Application Data\Sun\Java\Deployment\deployment.properties”
Else
StrJavaRegKeyPath=”Software\AppDataLow\Software\JavaSoft\DeploymentProperties”
StrJavaDeploymentPropertiesPath= strUserProfile & “\AppData\LocalLow\Sun\Java\Deployment\deployment.properties”
End If

‘These lines actually remove the registry key and file.
objFile.DeleteFile(StrJavaDeploymentPropertiesPath)
oReg.DeleteKey HKEY_CURRENT_USER, StrJavaRegKeyPath