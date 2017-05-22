'==========================================================================
'
' VBScript Source File to Install ISAPI Filter
'
' AUTHOR: Sven Zethelius
' DATE  : 10/3/2008
'
' COMMENT: This script removes ISAPI Filters
'        
'==========================================================================

Option Explicit

Dim filterDllName
Dim w3svc, child
Dim siteIndexValues()
Dim i

IF WScript.Arguments.Length <> 1 THEN
	WScript.Echo "Usage: RemoveIISFilter filterDLL"
	wscript.quit(1)
end if

filterDllName = WScript.Arguments( 0 )

i = 0
' Get all websites and add their index to SiteIndexValues()				
Set w3svc = GetObject("IIS://" & "LocalHost" & "/W3SVC")	
For Each child in w3svc
	If IsNumeric(child.Name) then
		ReDim Preserve siteIndexValues(i)
			siteIndexValues(i) = child.Name
		i = i + 1
		End If 
Next

' Remove site filters
For i = 0 to UBound(SiteIndexValues)
	RemoveFilter SiteIndexValues(i), filterDllName
Next
' Remove global filters
RemoveFilter "",filterDllName

WScript.quit(0)

Sub RemoveFilter(site, filterDllName)
	On Error resume Next
	Dim objFilters, objFilter, strLoadOrder
	Dim i, iFilter
	
	if site <> "" then
		Dim objSite
		Set objSite = GetObject("IIS://LocalHost/W3SVC/" & site)
		WScript.Echo Now() & "     Currently checking Web Site: " & objSite.ServerComment & " (Index= " & site & ")"

		Set objFilters = GetObject("IIS://LocalHost/W3SVC/" & site & "/Filters")
	else
		WScript.Echo Now() & "     Currently checking Site Filters"

		Set objFilters = GetObject("IIS://LocalHost/W3SVC/Filters")
	End if
	If err.number <> 0 Then    
		If err.number = -2147024893 Then
			WScript.Echo Now() & "     Filters is not present."
			err.number = 0  
			Exit Sub
		else
			WScript.Echo Now() & "     Error retrieving filter information.  Error Number: " & Err.Number & " |  Error Description: " & err.description
			err.number = 0
			wscript.quit(1)
		End if
	End if  
    
	strLoadOrder = objFilters.FilterLoadOrder
	
	For Each objFilter in ObjFilters
		If LCase(Right(objFilter.FilterPath, Len(filterDllName))) = LCase(filterDllName) Then
			WScript.Echo Now() & "     Removing Filter: "&objFilter.Name&":"&objFilter.FilterPath
			objFilters.Delete "IIsFilter", objFilter.name
			If strLoadOrder <> "" Then
				iFilter = InStr(strLoadOrder, objFilter.name)
				
				IF iFilter <> 0 Then	
					If Right(strLoadOrder, 1) <> "," Then                    
						strLoadOrder = strLoadOrder & ","
					End if
					strLoadOrder = Mid(strLoadOrder, 1, iFilter - 1) & _
								Mid(strLoadOrder, iFilter + Len(objFilter.name) + 1, _
									Len(strLoadOrder))
				End If
			End If

			If err.number <> 0 Then
				WScript.Echo Now() & "     Error removing filter.  Error Number: " & Err.Number & " |  Error Description: " & err.description
				wscript.quit(1)
			End if
		End if
	Next
	
	WScript.Echo Now() & "     New filter load order: "&strLoadOrder
	objFilters.FilterLoadOrder = strLoadOrder
	objFilters.SetInfo
	If err.number <> 0 Then
		WScript.Echo Now() & "     Error updating load order.  Error Number: " & Err.Number & " |  Error Description: " & err.description
		wscript.quit(1)
	End if
  
End Sub