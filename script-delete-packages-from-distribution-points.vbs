    ‘Script to delete packages from its assigned Distribution Points.

    strComputer =inputBox("Please Enter the SMS provider OR Site where the packages are created" , "SCCM Server name")
    Set FSO = CreateObject("Scripting.FileSystemObject")
    Set packages=fso.OpenTextFile("C:\PACKAGESTODELETE.txt",1,true)
    Set objoutputfile=fso.OpenTextFile("C:\DP_results.txt",2,true)

    Do While packages.AtEndOfLine <> True
        ‘read the next line
        package = packages.Readline

    Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\SMS\site_CEN")
    if err.number<>0 then
        msgbox "server connection failed"
        wscript.quit
    end if
    Set colItems = objWMIService.ExecQuery("SELECT * FROM SMS_DistributionPoint where packageid=’" & Package & "’")
    For Each objItem in colItems
            ‘Wscript.Echo "ServerNALPath: " & objItem.ServerNALPath
    objoutputfile.WriteLine ( package & vbTab & " will be deleteting from" & VBTAB & objItem.ServerNALPath)

    objitem.Delete_

    If Err.number <> 0 Then

    objoutputfile.WriteLine ( "Failed to delete" & vbTab & package & "from" &  vbTab & objItem.ServerNALPath)
          End If
        Next

    loop

    msgbox "Done"
