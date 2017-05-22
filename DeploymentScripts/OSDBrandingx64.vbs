'////////////////////////////////////////////////////////////////////////
' OSD Deploy Tool Branding Script
'////////////////////////////////////////////////////////////////////////
' Brand OSD variables to registry
'////////////////////////////////////////////////////////////////////////
' Include/Exclude
'////////////////////////////////////////////////////////////////////////
' 1. Include or exclude variables "starting with"
' 2. Use semicolon to separate multiple values
' 3. Exclude takes precedence over includes
'////////////////////////////////////////////////////////////////////////
Option Explicit

	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	' Constants
	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	Const	REG32			= "%windir%\System32\reg.exe"
	Const	REG64			= "%windir%\Sysnative\reg.exe"
	Const	REGBRANDPATH	= "HKLM\Software\WOW6432Node\Microsoft\MPSD\OSD"

	Const	includeMap		= "OSD;_SMSTSClientGUID;_SMSTSClientIdentity;USMT_;PACKAGES;TSType;TSVersion;OldComputerName"
	Const	excludeMap		= "OSDJoinPassword;_SMSTSReserved;OSDLocalAdminPassword"
	
	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	' Globals
	'||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	Dim REGBRAND
	Dim oWSH 				: SET oWSH = CreateObject("WScript.Shell")
	Dim oTSE				: SET oTSE = CreateObject("Microsoft.SMS.TSEnvironment")   

	'[##############################################################################################################################]
	' MAIN
	'[##############################################################################################################################]
	

	'||||||||||||||||||||||||||||||||
	' Determine 32/64 Sysnative
	'||||||||||||||||||||||||||||||||	
	Call LogArea("Environmental Setup")
	IF ( IsSysnative() = TRUE ) Then REGBRAND = REG64 Else REGBRAND = REG32
	
	'||||||||||||||||||||||||||||||||
	' Build Exclude/Include Arrays
	'||||||||||||||||||||||||||||||||
	Call LogArea("Mapping Inclusions and Exclusions")
	Dim incArray : incArray = Split( includeMap, ";" )
	Dim excArray : excArray = Split( excludeMap, ";" )

	'||||||||||||||||||||||||||||||||
	' Loop through TS Variables
	'||||||||||||||||||||||||||||||||
	Call LogArea("Branding Registry")
	Call BrandValue( "InstalledOn", Date )
	
	Dim tV
    For Each tV in oTSE.GetVariables() 
		IF (MatchMaker( tV, incArray ) = TRUE) Then
			IF (MatchMaker( tV, excArray ) = FALSE ) Then
				Call BrandValue( tV, oTSE(tV) )
			End IF
		End IF
    Next	

	WScript.Quit(0)
	
	
	'[##############################################################################################################################]
	' FUNCTIONS
	'[##############################################################################################################################]
	
	
	' ////////////////////////////////////////////////////
	' Brand a name and value to registry
	' ////////////////////////////////////////////////////
	Sub BrandValue( theName, theValue )
	
		Dim retVal : retVal = 0
		Dim runCmd : runCmd = REGBRAND & " ADD " & REGBRANDPATH & " /F /V " & theName & " /T REG_SZ /D """ & theValue & """"

		Wscript.Echo " Branding : [" & runCmd & "]"
		retVal = oWSH.Run( runCMD, 0, True )
		Wscript.Echo " Result   : [" & retVal & "]"

	End Sub
	
	
	' ////////////////////////////////////////////////////
	' Match "StartsWith" against an array of values
	' ////////////////////////////////////////////////////
	Function MatchMaker(theItem, theArray)
		Dim retVal : retVal = FALSE
	
		Dim anItem
		For Each anItem in theArray
			If ( Len(anItem)=0 ) Then Exit For
			' ||||||||||||||||||||||||||||||||
			'  - StartsWith is position 1
			'  - Case/Text Insensitive is 1
			' ||||||||||||||||||||||||||||||||
			If ( InStr(1, theItem, anItem, 1) = 1 ) Then 
				retVal = TRUE
				Exit For
			End If
		Next
	
		MatchMaker = retVal
	
	End Function
	
	
	' ////////////////////////////////////////////////////
	' Detects if 32-bit environment on 64-bit OS
	' ////////////////////////////////////////////////////
	Function IsSysnative()
	
		Dim	PARCH1 : PARCH1 = UCASE( oWSH.ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%") )	
		Dim	PARCH2 : PARCH2 = UCASE( oWSH.ExpandEnvironmentStrings("%PROCESSOR_ARCHITEW6432%") )	
		
		wscript.echo "%PROCESSOR_ARCHITECTURE% = [" & PARCH1 & "]"
		wscript.echo "%PROCESSOR_ARCHITEW6432% = [" & PARCH2 & "]"
		
		IF ( (PARCH1 = "X86") AND (PARCH2 = "AMD64") ) Then IsSysnative=TRUE _
		ELSE IsSysnative = FALSE
	
		wscript.echo "32-BIT Environment on a 64-BIT OS: [" & IsSysnative & "]"
	
	End Function

	
	' ////////////////////////////////////////////////////
	' Log Area
	' ////////////////////////////////////////////////////
	Sub LogArea( theText )
	
		Wscript.Echo
		Wscript.Echo "---------------------------------------------------"
		Wscript.Echo " " & theText
		Wscript.Echo "---------------------------------------------------"
		Wscript.Echo

	End Sub