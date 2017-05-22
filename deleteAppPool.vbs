
' this script will delete an appPool whose name is passed in as the first argument
' It will also delete any applications under the specified app pool before deleting the app pool
' because IIS does not allow app pools to be deleted if there are any applications under that app pool
'
' If the specified app pool does not exist, this script will NOT return an error
option explicit

dim strAppPoolName

if WScript.Arguments.Count > 1 then
   WScript.Echo "Usage:"
   WScript.Echo WScript.ScriptFullName & " <App Pool to delete>"
   WScript.Quit -1
end if 

strAppPoolName = Wscript.Arguments(0)

if GetIisVersion < 6 then
   WScript.Echo "IIS version is below 6 - no action done."
   WScript.Quit
end if

'If App Pool does not exist - nothing to do here
if AppPoolExists(strAppPoolName) = false Then
   Wscript.Quit 
end if

'Make sure we delete all the applications under the app pool 
if deleteAllAppsUnderAppPool(strAppPoolName) = false Then
    Wscript.Echo "Error deleting some of the applications under app pool " & strAppPoolName
    Wscript.Quit -1
end if

'All the applications under the app pool are gone - so should be able to delete the app pool
if DeleteAppPool(strAppPoolName) = false then
   WScript.Echo "Error Deleting AppPool " & strAppPoolName
   WScript.Quit -1
end if 

'call enumAppPools

' App Pool successfully deleted here - we are done
Wscript.Quit

'=============================================================================

function DeleteAppPool(strName)
    'On Error Resume Next
    
    dim objAppPools, objAppPool
    Set objAppPools = GetObject("IIS://localhost/W3SVC/AppPools")

    objAppPool = objAppPools.Delete("IIsApplicationPool", strName)

    if err = 0 then
       DeleteAppPool = True
    else
       DeleteAppPool = false
    end if
    
end function    ' createAppPool
'=============================================================================
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
end function    ' GetIisVersion
'===================================================================================================
function deleteAllAppsUnderAppPool(strAppPoolName)
    'On Error Resume Next
    dim IIsAppPoolObject, index, Applications

    deleteAllAppsUnderAppPool = true

    set IIsAppPoolObject = GetObject("IIS://localhost/W3SVC/AppPools/" & strAppPoolName)

    Applications = IIsAppPoolObject.EnumAppsInPool()

    ' Iterate through the list of applications and delete each one
    for index = 0 to UBound(Applications)
        Dim objVirtualDir
        set objVirtualDir = GetObject("IIS://localhost" & cleanUpDirectoryName(Applications(index)))
        
        objVirtualDir.AppDeleteRecursive
        objVirtualDir.SetInfo
        
        if err <> 0 then
            deleteAllAppsUnderAppPool = false
        end if
        set objVirtualDir = nothing
    next
    
end function 'deleteAllAppsUnderAppPool
'===================================================================================================
' The name that we get from the app pool is like - /LM/W3SVC/998577302/ROOT/
' We want to get the name W3SVC/998577302/ROOT so that it can be used to get the virtual directory
function cleanUpDirectoryName(directoryName)
    dim finalName 
    finalName = Mid(directoryName,4)
    cleanUpDirectoryName = Left(finalName,Len(finalName)-1)
end function 'cleanUpDirectoryName
'===================================================================================================
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