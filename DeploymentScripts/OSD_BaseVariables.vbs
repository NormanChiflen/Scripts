'///////////////////////////////////////////////////////
' OSD_BaseVariables
'///////////////////////////////////////////////////////

Option Explicit

	' ############################################################ CONST

	Const TsXmlVarName    = "_SMSTSTaskSequence"
	Const TsBaseVarName   = "BaseVariableName"
	Const TsSaveVarName   = "OSDBaseVariableName"
	Const OSDBrandingArea = "HKLM\SOFTWARE\Microsoft\MPSD\OSD"

	' ############################################################ GLOBAL
	
	Dim TsBaseValue
	
	Dim oTSE
	Dim oXML
	Dim oWSH
	Dim oWMI

	' ############################################################ MAIN BEGIN
	
	PrintTitle("Initializing Objects")
	If (SetObjects = false) Then QuitScript( 100 )
	
	PrintTitle("Extracting TS Base Variable")
	If (GetBaseVariableName = false) Then QuitScript( 200 )
	
	PrintTitle("Extracting Package Names")
	If (GetPackageNames = false) Then QuitScript( 300 )
	
	PrintTitle("Script Completed Successfully!")
	QuitScript ( 0 )
	
	' ############################################################ MAIN END



	
	' /////////////////////////////////////////////////////////
	' Initialize/Set Objects
	' /////////////////////////////////////////////////////////
	Function SetObjects
		SetObjects = true

		On Error Resume Next
		Err.Number = 0
		
		SET oTSE = CreateObject("Microsoft.SMS.TSEnvironment") 
		SET oXML = CreateObject("Microsoft.XMLDOM")
		SET oWSH = CreateObject("WScript.Shell")
		SET oWMI = GetObject( "winmgmts:{impersonationLevel=impersonate}!\\.\root\ccm\Policy\Machine" )
	
		if (Err.Number <> 0) Then 
			SetObjects = false
			wscript.echo " --| Error: [" & Err.Number & "]"
			wscript.echo " --| Description: [" & Err.Description & "]"
		End If
	
		On Error Goto 0
	
	End Function	
	
	
	' /////////////////////////////////////////////////////////
	' Return Base Variable Name
	' /////////////////////////////////////////////////////////
	Function GetBaseVariableName
		GetBaseVariableName = true
		
		Dim xmlString
	
		On Error Resume Next
		Err.Number = 0
	
		Wscript.Echo "Reading OSD variable: [" & TsXmlVarName & "]"
		xmlString = oTSE(TsXmlVarName)
		If (Len(xmlString)=0) Then
			Wscript.Echo "Failed to read OSD variable, or value is empty."
			GetBaseVariableName = false
			Exit Function
		End If
		
		wscript.Echo "Loading XML from variable string content..."
		if (oXML.LoadXml( xmlString ) = false) Then
			Wscript.Echo "Failed to load XML from string (OSD variable)."
			GetBaseVariableName = false
			Exit Function
		End If

		wscript.Echo "Using XPATH to query for [" & TsBaseVarName & "]"
		TsBaseValue = ""
		TsBaseValue = oXML.selectSingleNode( "//variable[@name='" & TsBaseVarName & "']" ).Text
		If (Len(TsBaseValue)=0) Then
			Wscript.Echo "Failed to read XPATH query value, or value is empty."
			GetBaseVariableName = false
			Exit Function
		End If
		
		wscript.echo "Extracted XPATH variable name: [" & TsBaseValue & "]"
		wscript.Echo "Setting new variable: [" & TsSaveVarName & "] = [" & TsBaseValue & "]"
		oTSE( TsSaveVarName ) = TsBaseValue

		If (Err.Number <> 0) Then 
			GetBaseVariableName = false
			wscript.echo " --| Error: [" & Err.Number & "]"
			wscript.echo " --| Description: [" & Err.Description & "]"
		End If
	
		On Error Goto 0
		
	End Function	
	

	' /////////////////////////////////////////////////////////
	' Get Package Names
	' /////////////////////////////////////////////////////////
	Function GetPackageNames
		GetPackageNames = true
		
		Dim numItem
		Dim numItemString
		Dim itemFound
		
		numItem       = 0
		numItemString = ""
		itemFound     = true
		
			Do 
				Dim nameBuilder
				Dim nameValue
			
				numItem = numItem + 1
				
				If (numItem<10) Then 
					numItemString = "00" & numItem
				ElseIf (numItem<100) Then 
					numItemString = "0" & numItem
				Else
					numItemString = numItem
				End If

				nameBuilder = TsBaseValue & numItemString
				wscript.echo "Checking for registry entry name: [" & nameBuilder & "]"

				nameValue = oTSE( nameBuilder )
				wscript.echo " --| Value: [" & nameValue & "]"

				If ( len(nameValue) = 0 ) Then 
					wscript.echo " --| Item not found."
					itemFound = false
				Else

					Dim wmiValue
					
					wmiValue = GetPackageName( nameValue )
					nameBuilder = nameBuilder & "Name"
					oTSE( nameBuilder ) = wmiValue
					
					wscript.echo " --| Set OSD variable [" & nameBuilder & "] equal to [" & wmiValue & "]"
					
				End If
				
				
			Loop Until (itemFound = false)
	
	End Function
	
	
	' /////////////////////////////////////////////////////////
	' Get Package Name from WMI
	' /////////////////////////////////////////////////////////
	Function GetPackageName( thePackageProgram )
		
		Dim PackageID
		Dim PackageName
		Dim splitArray

		splitArray = Split( thePackageProgram, ":" )
		PackageID  =( splitArray(0) )

		Dim WMICollection
		Dim WMIItem
		
		On Error Resume Next
		Err.Number = 0		

		wscript.echo " --| Running WMI Query..."
		SET WMICollection = oWMI.ExecQuery( "Select * from CCM_SoftwareDistribution where PKG_PackageID='" & PackageID & "'" )

		GetPackageName = ""
		For Each WMIItem in WMICollection
			GetPackageName = WMIItem.PKG_Name
			wscript.echo " --| Found: [" & GetPackageName & "]"
		Next

		If (Err.Number <> 0) Then 
			GetPackageName = ""
			wscript.echo " --| Error: [" & Err.Number & "]"
			wscript.echo " --| Description: [" & Err.Description & "]"
		End If
		
		On Error Goto 0
		
	End Function


	' /////////////////////////////////////////////////////////
	' Print Title
	' /////////////////////////////////////////////////////////
	Sub PrintTitle( theTitle )
	
		wscript.echo "--------------------------------"
		wscript.echo theTitle
		wscript.echo "--------------------------------"
		wscript.echo ""
		
	End Sub


	' /////////////////////////////////////////////////////////
	' Quit Script
	' /////////////////////////////////////////////////////////	
	Sub QuitScript( theExitCode )
	
		wscript.echo "--------------------------------"
		wscript.echo " Exiting with [" & theExitCode & "]"
		wscript.echo "--------------------------------"	

		wscript.Quit( theExitCode )
	
	End Sub