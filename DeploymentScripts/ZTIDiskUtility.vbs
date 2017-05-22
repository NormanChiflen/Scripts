' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      ZTIDiskUtility.vbs
' // 
' // Version:   5.1.1642.01
' // 
' // Purpose:	Utility functions for disk operations
' // 
' // Usage:	 <script language="VBScript" src="ZTIDiskUtility.vbs"/>
' // 
' // ***************************************************************************

Option Explicit


Function GetDiskSize (iDrive)
	Dim sQuery, oDisk, oRow
	Dim iRetVal

	iRetVal = -1
	sQuery = "SELECT Size from Win32_DiskDrive WHERE Index = " & iDrive
	On Error Resume Next
		 Set oDisk = objWMI.ExecQuery(sQuery)
	On Error Goto 0
	If Err Then
		GetDiskSize = -1
		EXIT FUNCTION
	End If

	For Each oDisk In objWMI.ExecQuery(sQuery)
		oLogging.CreateEntry "Total Disk size in bytes" & oDisk.Size, LogTypeInfo
		iRetVal = cLng(Fix(oDisk.Size / 1024 /1024))
	Next
	GetDiskSize = iRetVal
End Function

Function GetPartitionSize (sDriveLetter)
	Dim sDisk, sPartition, sScope, sQuery
	Dim iRetVal

	iRetVal = 0

	sQuery = "SELECT * from Win32_LogicalDisk WHERE DeviceId =" & chr(34) & sDriveLetter & chr(34)

	For Each sPartition in objWMI.ExecQUery( sQuery )
	If sPartition.Size > 0 Then
		iRetVal = cLng(sPartition.Size / 1024 / 1024)
		GetPartitionSize = iRetVal
		EXIT FUNCTION
	 End If
	Next

	GetPartitionSize = iRetVal
End Function

Function GetDiskPartitionCount (iDrive)

	Dim sQuery, iDiskSize, oPartition, oDisk
	Dim iRetVal
	
	iRetVal = 0
	
	'// Calculate total used space by adding each partitions used space.
	
	sQuery = "SELECT * from Win32_DiskPartition WHERE DiskIndex = " & iDrive
	
	For Each oPartition in objWMI.ExecQUery(sQuery)
			iRetVal = iRetVal + 1
	Next
	
	GetDiskPartitionCount = iRetVal
End Function

function GetDiskForDrive (sDriveLetter)
	Dim sDisk, sDrive,sQuery

	sQuery = "SELECT * from Win32_LogicalDisk WHERE DeviceId =" & chr(34) & left(sDriveLetter,2) & chr(34)

	For Each sDrive in objWMI.ExecQUery( sQuery )
		For Each sDisk in objWMI.ExecQUery("ASSOCIATORS OF {" & sDrive.Path_ & "} WHERE AssocClass = Win32_LogicalDiskToPartition")
			GetDiskForDrive = sDisk.DiskIndex
			exit function
		Next
	next

	GetDiskForDrive = -1
End Function

Function GetDiskFreeSpace (iDrive)

	Dim sQuery, iDiskSize, oPartition, oDisk
	Dim iPartitionUsedSpace
	Dim iRetVal

	iRetVal = -1
	iPartitionUsedSpace = 0

	'// Capture complete disk size

	iDiskSize = GetDiskSize(iDrive)

	'// Calculate total used space by adding each partitions used space.

	sQuery = "SELECT * from Win32_DiskPartition WHERE DiskIndex = " & iDrive

	For Each oPartition in objWMI.ExecQUery(sQuery)

		For Each oDisk in objWMI.ExecQUery("ASSOCIATORS OF {" & oPartition.Path_ & "} WHERE AssocClass = Win32_LogicalDiskToPartition")

			If (oDisk.Size <> "") Then
				iPartitionUsedSpace = iPartitionUsedSpace + cLng(oDisk.Size / 1024 /1024)
			End If

		Next
	Next
	iRetVal = iDiskSize - iPartitionUsedSpace
	GetDiskFreeSpace = iRetVal
End Function

Function GetNotActiveDrive()
	Dim sQuery, oPartition, oDisk

	sQuery = "SELECT * from Win32_DiskPartition WHERE BootPartition = FALSE"
	For Each oPartition in objWMI.ExecQUery(sQuery)
		For Each oDisk in objWMI.ExecQUery("ASSOCIATORS OF {" & oPartition.Path_ & "} WHERE AssocClass = Win32_LogicalDiskToPartition")
			GetNotActiveDrive = oDisk.DeviceId
			EXIT FUNCTION
		Next
	Next

	GetNotActiveDrive = False

End Function


Function GetBootDrive
	Dim sQuery, oPartition, oDisk

	sQuery = "SELECT * from Win32_DiskPartition WHERE Bootable = TRUE"
	For Each oPartition in objWMI.ExecQUery(sQuery)
		For Each oDisk in objWMI.ExecQUery("ASSOCIATORS OF {" & oPartition.Path_ & "} WHERE AssocClass = Win32_LogicalDiskToPartition")

			If oDisk.DriveType = 3 then
				If oFSO.FileExists( oDisk.DeviceID & "\ntldr" ) or oFSO.FileExists( oDisk.DeviceID & "\bootmgr" ) then
					GetBootDrive = oDisk.DeviceID
					Exit function
				End if
			End if
		Next
	Next

	GetBootDrive = Failure
End function


' Determine drive status as compared to the custom partition config
'
' Return:
'   0 = Partition exists and meets criteria
'   1 = Partition exists and does not meet the criteria
'   -1= Partition does not exist.


Function MatchPartitionConfiguration (iDriveIndex, iPartitionIndex, sDriveLetter, iMinSizeMB)

	Dim sDisk, sPartition, sScope
	Dim iRetVal

	iRetVal = -1

	sScope = "WHERE DiskIndex = " & iDriveIndex & " AND Index = " & iPartitionIndex


	For Each sPartition in objWMI.ExecQUery("SELECT * from Win32_DiskPartition " & sScope)
		For Each sDisk in objWMI.ExecQUery("ASSOCIATORS OF {" & sPartition.Path_ & "} WHERE AssocClass = Win32_LogicalDiskToPartition")

			If UCase(sDisk.DeviceId) = UCase(sDriveLetter) And sDisk.DriveType = 3 And (sDisk.FileSystem = "FAT" Or sDisk.FileSystem = "FAT32" Or sDisk.FileSystem = "NTFS")  And cLng(sDisk.Size / 1024 / 1024) >= cLng(iMinSizeMB) Then
				iRetVal = 0
			Else
				iRetVal = 1
			End If

		Next
	Next

	MatchPartitionConfiguration = iRetVal
End Function

Function RunBCDBoot()
	
	Dim iRetval,sCMDString
	Dim sBCDBoot
	iRetVal = Success
	If (sBCDBoot = "") Then
		
		iRetVal = oUtility.FindFile("bcdboot.exe",sBCDBoot)
		TestAndFail iRetVal, 6731, "Find bcdboot.exe"
			
	End If
	
	If OEnvironment.Item("UILanguage") = "" Then
		OEnvironment.Item("UILanguage") = oShell.RegRead("HKEY_CURRENT_USER\Control Panel\International\LocaleName")
	End If

	If Left(oENV("SYSTEMROOT"),1) = "X" Then
		sCMDString = sBCDBoot & " " & oEnvironment.Item("DestinationLogicalDrive") & "\windows /l " & oEnvironment.Item("UILanguage")
	Else
		sCMDString = sBCDBoot & " %SystemRoot% /l " & oEnvironment.Item("UILanguage")
	End If
	oLogging.CreateEntry "Running: " & sCmdString, LogTypeInfo
	iRetVal = oUtility.RunWithHeartbeat(sCMDString)
	RunBCDBoot = iRetVal

End Function

Function MarkActive(sBDEDrive)
	
	Dim iRetVal, oDiskpartFile,sDiskPartFile
	iRetVal = Success
	sDiskPartFile = oShell.ExpandEnvironmentStrings("%temp%") & "\BdeMarkActiveDiskPart.txt"

	Set oDiskPartFile = oFSO.CreateTextFile(sDiskPartFile, True, False)
	TestAndFail SUCCESS, 6729, "Create Text File "& sDiskPartFile
	oDiskPartFile.WriteLine "Select Vol " & sBDEDrive
	oDiskPartFile.WriteLine "Active"
	oDiskPartFile.Close


	'// Execute diskpart.exe

	iRetVal = oShell.Run("cmd /c ""DISKPART.EXE /s """ & sDiskPartFile & """ >> """ & oUtility.LogPath & "\ZTIMarkActive_diskpart.log"" 2>&1""", 0, true)
	TestAndFail iRetVal, 6730, "Execute cmd /c ""DISKPART.EXE /s """ & sDiskPartFile & """ >> """ & oUtility.LogPath & "\ZTIMarkActive_diskpart.log"" 2>&1"""
	MarkActive = iRetVal


End Function

DIM ExtendedSpace

Class CustomPartition

	DIM DiskIndex
	DIM PartitionIndex
	DIM PartitionType
	DIM VolumeLabel
	DIM DriveLetter
	DIM FileSystem
	DIM FormatType
	DIM Sizeunits
	DIM SizePartition
	DIM FreeSpaceAvailable
	Dim NeedCreate



	Private Sub Class_Initialize
		FileSystem = "NTFS"
	End Sub

	'TODO: Error Handling Routine

	Public Function Validate(iDiskFreeSpace,FreeSpaceAvailable)

		Dim iRetVal
		dim iPercentage
		DIM partitionSize

		iRetVal = Success



		IF ( FreeSpaceAvailable < 0) THEN
			iRetVal = Failure
			oLogging.CreateEntry "No Disk" & DiskIndex & "is available. or No Enough space is present in the disk index", LogTypeError
		END IF

		If (IsNull(PartitionIndex) OR PartitionIndex = "") Then
			iRetVal = Failure
			oLogging.CreateEntry "No Index value specified in partition configuration file.", LogTypeError
		End If

		If PartitionIndex = 0 Then
			iRetVal = Failure
			oLogging.CreateEntry "0 is an invalid Index in partition configuration file.", LogTypeError
		End If

		If (IsNull(DriveLetter) OR DriveLetter = "") Then
			'iRetVal = Failure
			'oLogging.CreateEntry "No DriveLetter value specified in partition configuration file. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
		End If

		'Validate the size of the disk

		IF (IsNull(SizePartition) OR SizePartition ="") THEN
			iRetVal = Failure
			oLogging.CreateEntry "No size value specified in partition configuration file. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
		END IF

		'Included code for the handling sizeunits in MB
		IF StrComp(Trim(Sizeunits),"GB") = 0 THEN
			SizePartition = clng(SizePartition * 1024)
		ELSE
			SizePartition = clng(SizePartition)
		END IF

		IF (UCASE(PartitionType)) <> "LOGICAL" THEN
			IF StrComp(Sizeunits,"%") = 0 THEN
				iPercentage = SizePartition / 100 - 0.01
				SizePartition = clng(Fix(iPercentage * FreeSpaceAvailable))

				oLogging.CreateEntry "Percentage Partition: " & iPercentage & " and Parition Size: " & SizePartition , LogTypeInfo
				IF SizePartition > FreeSpaceAvailable THEN
					iRetVal = Failure
					oLogging.CreateEntry "Size value specified in partition configuration file is greater than total space. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
				END IF
			ELSE
				IF SizePartition > FreeSpaceAvailable THEN
					iRetVal = Failure
					oLogging.CreateEntry "Size value specified in partition configuration file is greater than total space. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
				END IF
			END IF
			FreeSpaceAvailable = clng(FreeSpaceAvailable - SizePartition)
			oLogging.CreateEntry "Free space: " & FreeSpaceAvailable & " out of Total Space: " & iDiskFreeSpace , LogTypeInfo
			IF (UCASE(PartitionType)) = "EXTENDED" THEN
				ExtendedSpace = SizePartition
			END IF
		ELSE
			IF StrComp(Sizeunits,"%") = 0 THEN
				iPercentage  =   SizePartition / 100 - 0.01
				SizePartition = clng(Fix(iPercentage * ExtendedSpace))
				oLogging.CreateEntry "Percentage Partition: " & iPercentage & " and Parition Size: " & SizePartition , LogTypeInfo
				IF SizePartition > ExtendedSpace THEN
					iRetVal = Failure
					oLogging.CreateEntry "Size value specified in partition configuration file is greater than total space. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
				END IF
			ELSE
				IF SizePartition > ExtendedSpace THEN
					iRetVal = Failure
					oLogging.CreateEntry "Size value specified in partition configuration file is greater than total space. PartitionIndex:" & PartitionIndex & "and DiskIndex:" & DiskIndex, LogTypeError
				END IF
			END IF
		ExtendedSpace = clng(ExtendedSpace - SizePartition)
		oLogging.CreateEntry "Free space: " & ExtendedSpace & " out of Space." , LogTypeInfo
	END IF
		Validate = iRetVal

	End Function

End Class





