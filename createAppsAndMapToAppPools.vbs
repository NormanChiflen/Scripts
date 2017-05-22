' this script creates new applications for each pub and htx directory and maps it to passed in app pool
' you can see the application is IIS Info Services manager by right clicking on any
' web site or vitural directory and selecting properties
' click on "Home Directory" tab and look at "Application settings" area

option explicit

dim objIISW3SVC, strAppPoolName

if WScript.Arguments.Count = 1 then
    strAppPoolName = WScript.Arguments(0)
else 
   WScript.Echo "Usage:"
   WScript.Echo WScript.ScriptFullName & " <App Pool Name to assign to>"
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

dim objSingle

for each objSingle in objIISW3SVC
    Wscript.echo objSingle.Name & ", Class = " & objSingle.class
    
    if (objSingle.class = "IIsWebServer") THEN
        traverseObject objSingle, 0
    end if
next
Wscript.Quit
'=========================================================================================================================================================
function traverseObject(objRoot, level)
    Wscript.echo Space(level * 5) & objRoot.Name & ", Class = " & objRoot.class
    if (objRoot.class = "IIsWebVirtualDir") AND (StrComp(objRoot.Name, "pub") = 0 OR StrComp(objRoot.Name, "htx") = 0) THEN
        createApp(objRoot)
    else   ' ROOT level for each web-site
        Dim objChild
        for each objChild in objRoot
            traverseObject objChild, (level+1)
        next
    end if
end function 'traverseObject
'=========================================================================================================================================================
function createApp(objVirtualDir)
    On Error Resume Next
    Wscript.echo "create App called for object - name=" & objVirtualDir.Name & ", class=" & objVirtualDir.class
	Wscript.echo "Assigning to AppPool " & strAppPoolName
    objVirtualDir.AppCreate2 0
    objVirtualDir.AppFriendlyName = objVirtualDir.Name
    objVirtualDir.AccessExecute = True
    objVirtualDir.AccessRead = False
'    objVirtualDir.AppPoolId = "ISAPI_AppPool"
    objVirtualDir.AppPoolId = strAppPoolName
    objVirtualDir.SetInfo
    
    if err <> 0 then
        Wscript.echo "Mapping failed"
        Wscript.Quit -3
    end if

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