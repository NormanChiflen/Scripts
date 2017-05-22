' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      DeployWiz_Initialization.wsf
' // 
' // Version:   5.1.1642.01
' // 
' // Purpose:   Main Client Deployment Wizard Validation routines
' // 
' // ***************************************************************************

Option Explicit


'''''''''''''''''''''''''''''''''''''
'  Validate DeployRoot and Credentials
'


Function ChangeServerFromSite

	Dim oItem
	dim UpperBound
	dim oServer
	dim Index

	dim oServerList

	if oXMLSiteData is nothing then
		exit function
	end if

	for each oItem in oXMLSiteData.selectNodes("//servers/server")
		if SiteList.value = oUtility.SelectSingleNodeString(oItem,"serverid") then

			set oServerList = oItem.selectNodes("(server1|server2|server3|server4|server5|server6|server7|server8|server9|server|UNCPath)")

			' Get the Weighted Value UpperBound
			UpperBound = 0
			for each oServer in oServerList
				if oServer.Attributes.getQualifiedItem("weight","") is nothing then
					UpperBound = UpperBound + 1
				else
					UpperBound = UpperBound + cint(oServer.Attributes.getQualifiedItem("weight","").Value)
				end if
			next

			randomize
			Index = int(rnd * UpperBound + 1)

			' Pick a random server entry based on Weighted Value.
			UpperBound = 0
			for each oServer in oServerList
				if oServer.Attributes.getQualifiedItem("weight","") is nothing then
					UpperBound = UpperBound + 1
				else
					UpperBound = UpperBound + cint(oServer.Attributes.getQualifiedItem("weight","").Value)
				end if

				if Index <= UpperBound then
					DeployRoot.value = oServer.Text
					DisplayValidateDeployRoot
					exit function
				end if
			next

		end if
	next

	DisplayValidateDeployRoot

end function


Function DisplayValidateDeployRoot

	DeployRoot.readonly = RadioCT1.checked
	if RadioCT1.checked then
		DeployRoot.style.color = "graytext"
	else
		DeployRoot.style.color = ""
	end if

	SiteList.Disabled = RadioCT2.Checked

	DisplayValidateDeployRoot = ParseAllWarningLabels

end function


Function ValidateDeployRoot
	Dim oItem
	Dim oVariable
	Dim oName
	Dim sCmd

	ValidateDeployRoot = DisplayValidateDeployRoot

	If ValidateDeployRoot = FALSE then
		Exit function
	End if


	' Test the share for network access.

	ValidateDeployRoot = FALSE

	Do
		On Error Resume Next
		Err.Clear
		If oFSO.FileExists(DeployRoot.value & "\Control\OperatingSystems.xml" ) then
			ValidateDeployRoot = TRUE
			Exit Do
		End if
		On Error Goto 0

		If Mid(DeployRoot.value, 2, 2) = ":\" then
			Alert "Invalid or unrecognized path specified!"  ' For example, if they specified W:\Deploy and that didn't exist
			ValidateDeployRoot = FALSE
			Exit Function
		ElseIf not ValidateDeployRoot then

			' Get the credentials and connect to the share!

			oEnvironment.Item("UserID") = ""
			oEnvironment.Item("UserDomain") = ""
			oEnvironment.Item("UserPassword") = ""

			oShell.Run "mshta.exe " & window.document.location.href & " /NotWizard /LeaveShareOpen /ValidateAgainstUNCPath:" & DeployRoot.value & " /Definition:Credentials_ENU.xml", 1, true

			If UCase(oEnvironment.Item("UserCredentials")) <> "TRUE" then
				Alert "Could not validate Credentials!"
				Exit function
			End if

		End if

	Loop until ValidateDeployRoot = TRUE


	' Flush the value to variables.dat, before we continue.

	SaveAllDataElements
	SaveProperties

	' Process full rules

	sCmd = "wscript.exe """ & oUtility.ScriptDir & "\ZTIGather.wsf"""
	oItem = oSHell.Run(sCmd, , true)

	' Extract out other fields within the XML Data Object.

	If oXMLSiteData is nothing then
		Exit function
	End if

	For each oItem in oXMLSiteData.selectNodes("//servers/server")
		If SiteList.value = oUtility.SelectSingleNodeString(oItem,"serverid") then
			For each oVariable in oItem.selectNodes("otherparameters/parameter")
				Set oName = oVariable.Attributes.getQualifiedItem("name","")
				If not oName is Nothing then
					oProperties(oName.Value) = oVariable.Text
				End if
			Next

		End if
	Next

End Function


Dim UserID_isDirty
UserID_isDirty = FALSE

Function ValidateCredentials

	UserID_isDirty = TRUE
	ValidateCredentials = ParseAllWarningLabelsEx(userdomain, username )

End Function

Function ValidateCredentialsEx
	Dim r

	ValidateCredentialsEx = ValidateCredentials

	InvalidCredentials.style.display = "none"

	If ValidateCredentialsEx and oEnvironment.Item("OSVersion") <> "WinPE" then

			' Check using ADSI (not possible in Windows PE)

			r = CheckCredentials("", username.value, userdomain.value, userpassword.value)
			If r <> TRUE then

				InvalidCredentials.innerText = "* Invalid credentials: " & r
				InvalidCredentials.style.display = "inline"
				ValidateCredentialsEx = false

			End if


	End if

end function



Function RmPropIfFound( Prop )

	If oProperties.Exists(Prop) then
		oProperties.Remove(Prop)
	End if

End function


Function ValidateDeploymentType

	ValidateDeploymentType = TRUE

	If DTRadio2.Checked then

		' UPGRADE

		RmPropIfFound("UserDataLocation")

		RmPropIfFound("ComputerBackupLocation")


	End if

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate ComputerName
'

Function ValidateComputerName

	' Check Warnings
	ParseAllWarningLabels


	If Len(OSDComputerName.value) > 15 then
		InvalidChar.style.display = "none"
		TooLong.style.display = "inline"
		ValidateComputerName = false
		ButtonNext.disabled = true
	ElseIf IsValidComputerName ( OSDComputerName.Value ) then
		ValidateComputerName = TRUE
		InvalidChar.style.display = "none"
		TooLong.style.display = "none"
	Else
		InvalidChar.style.display = "inline"
		TooLong.style.display = "none"
		ValidateComputerName = false
		ButtonNext.disabled = true
	End if

End function


'''''''''''''''''''''''''''''''''''''
'  Validate Domain Membership
'

Function ValidateDomainMembership
	Dim IsDomain
	Dim r

	InvalidCredentials.style.display = "none"

	IsDomain = JDRadio1.checked

	JoinDomain.disabled = not IsDomain
	UserName.disabled = not IsDomain
	userdomain.disabled = not IsDomain
	Password.disabled = not IsDomain

	MachineObjectOU.disabled = not IsDomain
	MachineObjectOUOptionalBtn.disabled = not isDomain
	MachineObjectOUOptional.disabled = not isDomain

	Workgroup.disabled = IsDomain

	If not isDomain then

		RMPropIfFound("BdeInstall")
		RMPropIfFound("BdeInstallSuppress")
		RMPropIfFound("DoCapture")
		RMPropIfFound("BackupFile")
		
		If Property("DeploymentType") <> "REFRESH" and Property("DeploymentType") <> "REPLACE" and Property("DeploymentType") <> "UPGRADE" then
			RMPropIfFound("ComputerBackupLocation")
		End if

	End if

	' Check Warnings

	ValidateDomainMembership = ParseAllWarningLabelsEx(userdomain, UserName)


	' Check credentials

	If IsDomain and ValidateDomainMembership and oEnvironment.Item("OSVersion") <> "WinPE" then

		' Only check credentials when the next button is clicked

		If window.event.srcElement is ButtonNext then

			' Check using ADSI (not possible in Windows PE)

			r = CheckCredentialsAD(JoinDomain.value, UserName.value, userdomain.value, Password.value)
			If r <> TRUE then

				InvalidCredentials.innerText = "* Invalid credentials: " & r
				InvalidCredentials.style.display = "inline"
				ValidateDomainMembership = false

			End if

		End if

	End if


	' We need to clean up the keyboard hook

	If ValidateDomainMembership then
		document.body.onMouseDown = ""
	End if

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate UserData Location
'

Function ValidateUserDataLocation

	Dim USMTTagFile
	InvalidPath.style.display = "none"

	UDRadio2.Value = DataPath.Value
	AllowLocal.Disabled = not UDRadio1.Checked
	document.GetElementByID("DataPath").Disabled = not UDRadio2.Checked
	document.GetElementByID("DataPathBrowse").Disabled = not UDRadio2.Checked

	ValidateUserDataLocation = ParseAllWarningLabels

	If UDRadio2.Checked then
		If UCase(Left(DataPath.Value, 2)) = UCase(Left(oUtility.LocalRootPath, 2)) and Property("DeploymentType") = "REFRESH" then
			InvalidPath.style.display = "inline"
			ValidateUserDataLocation = false
			Exit Function
		End if
		'If local Path (USB or other drive) is specified tag the drive
		If Mid(DataPath.Value, 2,1) = ":" Then
			On Error Resume Next
			Set USMTTagFile = OFSO.CreateTextFile(Left(DataPath.Value, 2) & "\UserState.tag", true)
			If Err Then
				InvalidPath.style.display = "inline"
				ValidateUserDateLocation = False
				Exit Function
			End If
			USMTTagFile.Close
		End If
			
	End if

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate UserData Location
'

Function ValidateUserDataRestoreLocation

	UDRadio2.Value = StatePath.Value

	document.GetElementByID("StatePath").Disabled = not UDRadio2.Checked
	document.GetElementByID("StatePathBrowse").Disabled = not UDRadio2.Checked

	InvalidPath.style.display = "none"
	ValidateUserDataRestoreLocation = TRUE
	If UDRadio2.Checked and StatePath.value <> "" then

		If Left(StatePath.value, 2) = "\\" and len(StatePath.value) > 6 and ubound(split(StatePath.value,"\")) >= 3 then
			oUtility.ValidateConnection StatePath.value
		End if

		If (oFSO.FileExists(StatePath.value & "\USMT3.MIG" ) or oFSO.FileExists(StatePath.value & "\USMT.MIG" )) or ( oFSO.FileExists(StatePath.value & "\MIGSTATE.DAT" ) and _
			oFSO.FileExists(StatePath.value & "\catalog.mig" ) ) then

			' Just in case the user selects the USMT3 directory.
			StatePath.value = StatePath.value & "\.."

		End if

		If not (oFSO.FolderExists(StatePath.value & "\USMT3" ) or oFSO.FolderExists(StatePath.value & "\USMT" )) then
			ValidateUserDataRestoreLocation = FALSE
			InvalidPath.style.display = "inline"
		Elseif not (oFSO.FileExists(StatePath.value & "\USMT3\USMT3.MIG" ) or oFSO.FileExists(StatePath.value & "\USMT\USMT.MIG" )) and _
			not (oFSO.FileExists(StatePath.value & "\USMT3\MIGSTATE.DAT" ) or oFSO.FileExists(StatePath.value & "\USMT\MIGSTATE.DAT" )) and _
			not (oFSO.FileExists(StatePath.value & "\USMT3\catalog.mig" ) or oFSO.FileExists(StatePath.value & "\USMT\catalog.mig" )) then

			ValidateUserDataRestoreLocation = FALSE
			InvalidPath.style.display = "inline"
		End if



	End if

	ValidateUserDataRestoreLocation = ValidateUserDataRestoreLocation and ParseAllWarningLabels

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate Computer Backup Location
'

Function ValidateComputerBackupLocation
	Dim HasErrors

	HasErrors = FALSE
	document.GetElementByID("CBRadio2").Value = document.GetElementByID("DataPath").Value

	document.GetElementByID("AllowLocal").Disabled = not CBRadio1.Checked

	document.GetElementByID("DataPath").Disabled = not CBRadio2.Checked
	document.GetElementByID("DataPathBrowse").Disabled = not CBRadio2.Checked

	ValidateComputerBackupLocation = ParseAllWarningLabels

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate task sequence List
'

Function ValidateTSList

	Dim oTaskList
	Dim oTS
	Dim oItem
	Dim oOSItem
	Dim sID
	Dim bFound
	Dim sTemplate
	
	set oTS = new ConfigFile
	oTS.sFileType = "TaskSequences"

	SaveAllDataElements

	If Property("TSGuid") = "" then
		oLogging.CreateEntry "No valid TSGuid found in the environment.", LogTypeWarning
		ValidateTSList = false
	End if

	oLogging.CreateEntry "TSGuid Found: " & Property("TSGuid"), LogTypeVerbose
	
	If Ucase(oEnvironment.Item("SkipDeploymentType")) = "YES" Then

		If Ucase(Property("DeploymentType")) = "REFRESH" or Ucase(Property("DeploymentType")) = "UPGRADE" Then
			oProperties("tmpDeploymentType") = Ucase(Property("DeploymentType"))
		End If
	End if

	sID = ""
	sTemplate = ""
	If oTS.FindAllItems.Exists(Property("TSGuid")) then
		sID = oUtility.SelectSingleNodeString(oTS.FindAllItems.Item(Property("TSGuid")),"./ID")
		sTemplate = oUtility.SelectSingleNodeString(oTS.FindAllItems.Item(Property("TSGuid")),"./TaskSequenceTemplate")
	End if
	
	oEnvironment.item("TaskSequenceID") = sID
	TestAndLog sID <> "", "Verify Task Sequence ID: " & sID
	Set oTaskList = oUtility.LoadConfigFileSafe( sID & "\TS.XML" )

	If not FindTaskSequenceStep( "//step[@type='BDD_InstallOS']", "" ) then

		oLogging.CreateEntry "Task Sequence does not contain an OS and does not contain a LTIApply.wsf step, possibly a Custom Step or a Client Replace.", LogTypeInfo
		
		oProperties.Item("OSGUID")=""
		If not (oTaskList.SelectSingleNode("//group[@name='State Restore']") is nothing) then
			oProperties("DeploymentType") = "StateRestore"
		ElseIf sTemplate <> "ClientReplace.xml" and oTaskList.SelectSingleNode("//step[@name='Capture User State']") is nothing then
			oProperties("DeploymentType")="CUSTOM"
		Else
			oProperties("DeploymentType")="REPLACE"

			RMPropIfFound("ImageIndex")
			RMPropIfFound("ImageSize")
			RMPRopIfFound("ImageFlags")
			RMPropIfFound("ImageBuild")
			RMPropIfFound("InstallFromPath")
			RMPropIfFound("ImageMemory")

			oEnvironment.Item("ImageProcessor")=Ucase(oEnvironment.Item("Architecture"))
		End if

	Elseif oEnvironment.Item("OSVERSION")="WinPE" Then

		oProperties("DeploymentType")="NEWCOMPUTER"

	Else

		oLogging.CreateEntry "Task Sequence contains a LTIApply.wsf step, and is not running within WinPE.", LogTypeInfo

		If Ucase(oEnvironment.Item("SkipDeploymentType")) = "YES" Then
			oProperties("DeploymentType") = Property("tmpDeploymentType")
		Else
			oProperties("DeploymentType")=""
		End if
		oEnvironment.Item("DeployTemplate")=Ucase(Left(sTemplate,Instr(sTemplate,".")-1))

	End if

	oLogging.CreateEntry "DeploymentType = " & oProperties("DeploymentType"), LogTypeInfo

	
	set oTaskList = nothing
	set oTS = nothing

	' Set the related properties

	RMPropIfFound("DestinationDisk")
	RMPropIfFound("DestinationPartition")
	RMPropIfFound("DefaultDestinationDisk")
	RMPropIfFound("DefaultDestinationPartition")
	RMPropIfFound("DefaultDestinationIsDirty")

	oEnvironment.Item("ImageProcessor") = ""
	oEnvironment.Item("OSGUID")=""
	oUtility.SetTaskSequenceProperties sID


	If Left(Property("ImageBuild"), 1) < "6" then
		RMPropIfFound("LanguagePacks")
		RMPropIfFound("UserLocaleAndLang")
		RMPropIfFound("KeyboardLocale")
		RMPropIfFound("UserLocale")
		RMPropIfFound("UILanguage")
		RMPropIfFound("BdePin")
		RMPropIfFound("BdeModeSelect1")
		RMPropIfFound("BdeModeSelect2")
		RMPropIfFound("OSDBitLockerStartupKeyDrive")
		RMPropIfFound("WaitForEncryption")
		RMPropIfFound("BdeInstall")
		RMPropIfFound("OSDBitLockerWaitForEncryption")
		RMPropIfFound("BdeRecoveryKey")
		RMPropIfFound("BdeInstallSuppress")
	End If

	If oEnvironment.Item("OSGUID") <> "" and oEnvironment.Item("ImageProcessor") = "" then
		' There was an OSGUID defined within the TS.xml file, however the GUID was not found 
		' within the OperatingSystems.xml file. Which is a dependency error. Block the wizard.
		ValidateTSList = False
		ButtonNext.Disabled = True
		Bad_OSGUID.style.display = "inline"
	Else
		ValidateTSList = True
		ButtonNext.Disabled = False
		Bad_OSGUID.style.display = "none"
	ENd if


End Function


'''''''''''''''''''''''''''''''''''''
'  Validate Password
'

Function ValidatePassword

	ValidatePassword = ParseAllWarningLabels

	NonMatchPassword.style.display = "none"
	If Password1.Value <> "" then
		If Password1.Value <> Password2.Value then
			ValidatePassword = FALSE
			NonMatchPassword.style.display = "inline"
		End if
	End if

	ButtonNext.Disabled = not ValidatePassword

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate Capture
'

Function ValidateCaptureLocation

	InvalidCaptureLocation.style.display = "none"
	ValidateCaptureLocation = true

	If not CaptureRadio1.Checked then
		Exit Function
	End if

	If Left(ComputerBackupLocation.value, 2) = "\\" and len(ComputerBackupLocation.value) > 6 and ubound(split(ComputerBackupLocation.value,"\")) >= 3 then

		If not oUtility.ValidateConnection(ComputerBackupLocation.value) = Success then
				InvalidCaptureLocation.style.display = "inline"
				ValidateCaptureLocation = FALSE
		End if

	Else
		InvalidCaptureLocation.style.display = "inline"
		ValidateCaptureLocation = FALSE
	End if

End Function

Function ValidateCapture

	document.GetElementByID("ComputerBackupLocation").Disabled = not CaptureRadio1.Checked
	document.GetElementByID("BackupFile").Disabled = not CaptureRadio1.Checked

	if not CaptureRadio3.Checked then

		RMPropIfFound("BdeInstall")
		RMPropIfFound("BdeInstallSuppress")

	End if

	ValidateCapture = ParseAllWarningLabels

End Function


'''''''''''''''''''''''''''''''''''''
'  Validate LanguagePack
'

''''''''''''''''''''''''''''''''''''''

Function Locale_Validation

	Dim iSplit

	Locale_Validation = TRUE

	UILanguage_err.style.display = "none"
	If UILanguage.SelectedIndex = -1 then
		UILanguage_Err.style.display = "inline"
		Locale_Validation = FALSE
	End if

	UserLocale_Err.style.display = "none"
	If UserLocale_Edit.SelectedIndex = -1 then
		UserLocale_Err.style.display = "inline"
		Locale_Validation = FALSE
	End if

	KeyboardLocale_Err.style.display = "none"
	If KeyboardLocale_Edit.SelectedIndex = -1 then
		KeyboardLocale_Err.style.display = "inline"
		Locale_Validation = FALSE
	End if
	
	If not Locale_Validation then
		Exit Function
	End if
	
	iSplit = instr(1,UserLocale_Edit.Value,";",vbTextCompare)
	TestAndLog iSplit <> 0 , "Verify UserLocale_Edit contains Comma Delimiter: " & UserLocale_Edit.Value

	If instr(1,UserLocale_Edit.Value,";",vbTextCompare) <> 0 then
		' Take the LCID From UserLocale and add it to the KeyboardLocale
		KeyboardLocale.Value = UserLocale_Edit.Value & ":" & KeyboardLocale_Edit.Value
	Else
		' Some kind of Error
		KeyboardLocale.Value = right("0000" & hex(GetLocale),4) & ":" & KeyboardLocale_Edit.Value
	End if
	
	If iSplit <> 0 then
		UserLocale.Value = mid(UserLocale_Edit.Value,1,instr(1,UserLocale_Edit.Value,";",vbTextCompare) - 1)
	Else
		UserLocale.Value = UserLocale_Edit.Value
	End if

End function


Function ValidateProductKey

	ValidateProductKey = False

	If Left(Property("ImageBuild"), 1) < "6" then

		' Make sure the product key is valid

		If locProductKey.value = "" then
			PKBlank.style.display = "inline"
			PKInvalid.style.display = "none"
		ElseIf IsEmpty(GetProductKey(locProductKey.value)) then
			PKBlank.style.display = "none"
			PKInvalid.style.display = "inline"
		Else
			PKBlank.style.display = "none"
			PKInvalid.style.display = "none"
			ProductKey.value = GetProductKey(locProductKey.value)
			ValidateProductKey = True
		End if

	ElseIf PKRadio1.checked then

		locOverrideProductKey.disabled = true
		locProductKey.disabled = true

		OverrideBlank.style.display = "none"
		OverrideInvalid.style.display = "none"
		PKBlank.style.display = "none"
		PKInvalid.style.display = "none"

		ProductKey.value = ""
		OverrideProductKey.value = ""

		ValidateProductKey = True


	ElseIf PKRadio2.checked then

		locOverrideProductKey.disabled = false
		locProductKey.disabled = true

		PKBlank.style.display = "none"
		PKInvalid.style.display = "none"


		' Make sure the MAK key is valid

		If locOverrideProductKey.value = "" then
			OverrideBlank.style.display = "inline"
			OverrideInvalid.style.display = "none"
		ElseIf IsEmpty(GetProductKey(locOverrideProductKey.value)) then
			OverrideBlank.style.display = "none"
			OverrideInvalid.style.display = "inline"
		Else
			OverrideBlank.style.display = "none"
			OverrideInvalid.style.display = "none"
			OverrideProductKey.value = GetProductKey(locOverrideProductKey.value)
			ProductKey.value = ""
			ValidateProductKey = True
		End if

	Else

		locOverrideProductKey.disabled = true
		locProductKey.disabled = false

		OverrideBlank.style.display = "none"
		OverrideInvalid.style.display = "none"


		' Make sure the product key is valid

		If locProductKey.value = "" then
			PKBlank.style.display = "inline"
			PKInvalid.style.display = "none"
		ElseIf IsEmpty(GetProductKey(locProductKey.value)) then
			PKBlank.style.display = "none"
			PKInvalid.style.display = "inline"
		Else
			PKBlank.style.display = "none"
			PKInvalid.style.display = "none"
			ProductKey.value = GetProductKey(locProductKey.value)
			OverrideProductKey.value = ""
			ValidateProductKey = True
		End if

	End if

End Function


const PRODUCT_KEY_TEST = "([0-9A-Z]+)?[^0-9A-Z]*([0-9A-Z]{5})[^0-9A-Z]?([0-9A-Z]{5})[^0-9A-Z]?([0-9A-Z]{5})[^0-9A-Z]?([0-9A-Z]{5})[^0-9A-Z]?([0-9A-Z]{5})[^0-9A-Z]*([0-9A-Z]+)?" '


Function GetProductKey( pk )

	Dim regEx, match

	Set regEx = New RegExp
	regEx.Pattern = PRODUCT_KEY_TEST
	regex.IgnoreCase = TRUE

	For each match in regEx.Execute( UCase(pk) )
		If IsEmpty(match.SubMatches(0)) and IsEmpty(match.SubMatches(6)) then
			GetProductKey = ucase( match.SubMatches(1) & "-" & match.SubMatches(2) & "-" & _
			match.SubMatches(3) & "-" & match.SubMatches(4) & "-" & match.SubMatches(5) )
		End if
		Exit function
	Next

End function


Function AssignProductKey

	If not IsEmpty(GetProductKey(locProductKey.value)) then
		locProductKey.value = GetProductKey(locProductKey.value)
	End if
	If Left(Property("ImageBuild"), 1) >= "6" then
		If not IsEmpty(GetProductKey(locOverrideProductKey.value)) then
			locOverrideProductKey.value = GetProductKey(locOverrideProductKey.value)
		End if
	End if

End Function


Function ValidateBDE

	Dim regEx


	' Enable and disable

	If BDERadio2.checked then

		' Enable second set of radio buttons

		BdeModeRadio1.disabled = false
		BdeModeRadio2.disabled = false
		BdeModeRadio3.disabled = false
		BdeModeRadio4.disabled = false

		BdePin.disabled = false
		ADButton1.disabled = false
		ADButton2.disabled = false

		WaitForEncryption.disabled = false
	Else

		' Disable second set of radio buttons

		BdeModeRadio1.disabled = true
		BdeModeRadio2.disabled = true
		BdeModeRadio3.disabled = true
		BdeModeRadio4.disabled = true


		BdeModeSelect1.disabled = true
		BdeModeSelect2.disabled = true

		BdePin.disabled = true

		ADButton1.disabled = true
		ADButton2.disabled = true

		WaitForEncryption.disabled = true
	End if


	' Scan required fields

	ValidateBDE = ParseAllWarningLabels


	' Set BdeInstall based on choices

	If BDERadio2.checked then
		BdeInstallSuppress.value = "NO"

		' Mode/location
		If BdeModeRadio1.checked then
			BdeInstall.value = "TPM"
			BdePin.disabled = true
		ElseIf BdeModeRadio2.checked then
			BdeInstall.value = "TPMKey"
			OSDBitLockerStartupKeyDrive.value = BdeModeSelect1.Value
			BdeModeSelect1.disabled = false
			BdeModeSelect2.disabled = true
			BdePin.disabled = true
		ElseIf BdeModeRadio3.checked then
			BdeInstall.value = "Key"
			OSDBitLockerStartupKeyDrive.value = BdeModeSelect2.Value
			BdeModeSelect1.disabled = true
			BdeModeSelect2.disabled = false
			BdePin.disabled = true
		Else
			BdeInstall.value = "TPMPin"
			BdeModeSelect1.disabled = true
			BdeModeSelect2.disabled = true
			BdePin.disabled = false
		End if


		If ADButton1.checked Then
			BdeRecoveryKey.value = "AD"
		Else
			BdeRecoveryKey.value = ""
		End if

		OSDBitLockerWaitForEncryption.value = WaitForEncryption.checked

	Else ' IF BDERadio1.Checked then
	
		BdeInstall.value = ""
		BdeInstallSuppress.value = "YES"
	End if

End Function




Function ValidateDestinationDisk

	Dim sDestDrive

	ValidateDestinationDisk = True
	InvalidPartition.style.display = "none"
	InvalidDisk.style.display = "none"

	If not HasGoodDestPart ( DestinationDisk.Value, DestinationPartition.Value ) then
		oLogging.CreateEntry "Target Drive does not match System Drive [" & oEnv("SystemDrive") & "]", LogTypeInfo
		InvalidPartition.style.display = "inline"
		ValidateDestinationDisk = False
	End if 


End Function
