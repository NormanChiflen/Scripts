' this script creates a new application for the site and maps it to passed in app pool
' you can see the application is IIS Info Services manager by right clicking on any
' web site or vitural directory and selecting properties
' click on "Home Directory" tab and look at "Application settings" area

option explicit

dim objIISW3SVC, strAppPoolName, strSiteName

if WScript.Arguments.Count = 2 then
    strAppPoolName = WScript.Arguments(0)
    strSiteName = WScript.Arguments(1)
else 
   WScript.Echo "Usage:"
   WScript.Echo WScript.ScriptFullName & " <App Pool Name to assign to> <Web site name>"
   WScript.Quit -1
end if 

if GetIisVersion < 6 then
   WScript.Echo "IIS version is below 6 - no action done."
   WScript.Quit
end if

if AppPoolExists(strAppPoolName) = False Then
   WScript.Echo "App Pool " & strAppPoolName & " does not exist"
   WScript.Quit -2
end if

set objIISW3SVC = GetObject("IIS://localhost/W3SVC")

dim objSingle, objChild

for each objSingle in objIISW3SVC
    Wscript.echo objSingle.Name & ", Class = " & objSingle.class
    
    if (objSingle.class = "IIsWebServer") THEN
        Wscript.echo "Webserver name=" & objSingle.ServerComment
        if (StrComp(objSingle.ServerComment, strSiteName) = 0) THEN
            for each objChild in objSingle
                if (StrComp(objChild.Name, "root", 1) = 0) THEN
		    createApp(objChild)
                    WScript.Quit
                end if
            next
        end if
    end if
next
Wscript.Quit

function createApp(objVirtualDir)
    On Error Resume Next
    Wscript.echo "create App called for object - name=" & objVirtualDir.Name & ", class=" & objVirtualDir.class
    Wscript.echo "Assigning " & objVirtualDir.Name & " to AppPool " & strAppPoolName
    objVirtualDir.AppCreate2 0
    objVirtualDir.AppFriendlyName = objVirtualDir.Name
    objVirtualDir.AccessExecute = True
    objVirtualDir.AccessRead = False
    objVirtualDir.AppPoolId = strAppPoolName
    objVirtualDir.SetInfo
end function ' createApp
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