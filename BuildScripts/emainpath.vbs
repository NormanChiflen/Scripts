'#########################################################
'## This script updates the system path to include %systemdrive%\ExpediaSys

'## Log all changes
'## Action 	xxxx-xx-xx username change description

'## Created 	2008-07-10 johnmca New script for X64 build out


'#########################################################

dim strAddPath

strAddpath = ";%SystemDrive%\ExpediaSys"
strComputer = "."

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

Set colItems = objWMIService.ExecQuery _
    ("Select * From Win32_Environment Where Name = 'Path'")

For Each objItem in colItems
    strPath = objItem.VariableValue' & strAddpath
    
    if inStr(strpath,straddpath) = 0 then
		strPath = strPath & strAddpath
		objItem.VariableValue = strPath
		objItem.Put_
		wscript.echo "New path is: " & vbcrlf
		wscript.echo strPath
		wscript.quit 111
		
	else
		wscript.echo ("Server has " & strAddPath & " in path already.")
		wscript.quit 112
    end if
    
Next


