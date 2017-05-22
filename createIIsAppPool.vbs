
' VBScript source code
option explicit

dim strAppPoolName

if WScript.Arguments.Count = 1 then
    strAppPoolName = WScript.Arguments(0)
else 
   WScript.Echo "Usage:"
   WScript.Echo WScript.ScriptFullName & " <App Pool Name to create>"
   WScript.Quit -1
end if 

if GetIisVersion < 6 then
   WScript.Echo "IIS version is below 6 - no action done."
   WScript.Quit
end if

if AppPoolExists(strAppPoolName) = true then
   WScript.Echo "AppPool " & strAppPoolName & " already exists."
   WScript.Quit -1
end if

if createAppPool(strAppPoolName) = false then
   WScript.Echo "Error Creating AppPool " & strAppPoolName & "."
   WScript.Quit -1
end if 

' App Pool successfully created here - we are done
Wscript.Quit
'=========================================================================================================================================================
function createAppPool(strName)
    On Error Resume Next
    dim objAppPools, objAppPool
    Set objAppPools = GetObject("IIS://localhost/W3SVC/AppPools")
    Set objAppPool = objAppPools.Create("IIsApplicationPool", strName)
    objAppPool.SetInfo
    
    if err = 0 then
       createAppPool = True
    else
       createAppPool = false
    end if
    
end function    ' createAppPool
'=========================================================================================================================================================
function GetIisVersion
    dim strComputer, oReg, strKeyPath, strValueName, dwValue
    const HKEY_LOCAL_MACHINE = &H80000002
    strComputer = "."
     
    Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_
     strComputer & "\root\default:StdRegProv")
     
    strKeyPath = "Software\Microsoft\InetStp"
    strValueName = "MajorVersion"
    oReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
    GetIisVersion = dwValue 
end function
'=========================================================================================================================================================
function AppPoolExists(strAppPoolName)
    On Error Resume Next
    dim IIsAppPoolObject
    set IIsAppPoolObject = GetObject("IIS://localhost/W3SVC/AppPools/" & strAppPoolName)
    if err = 0 Then
        AppPoolExists = True
    else
        AppPoolExists = False
    end if
    set IIsAppPoolObject = nothing
end function    'AppPoolExists
'===================================================================================================




