'true automation.  Rather than running this script and having to type a name for each machine or having to run the script locally on each machine, it would be better to provide a list (perhaps in Excel) of machine names with what new name to join to the domain with.
'If you had 1000 machines to join to the domain, it would be extremely tedious where a script designed to read data from a file would be considerably more useful.
'As an example, here is a script I wrote that uses Netdom.  I use this to move computers from one domain to another.  I feed it a list of machine names and away it goes.  ''
'CODE

'==========================================================================
'
' NAME: NetDomJoinWorkstations
'
' AUTHOR: Norman Fletcher
' DATE  : 
'
' COMMENT: Joins computers to a new domain.  Edit domain name, 
' user ID and passwords below.  Uses a workstation list wslist.txt. 
' Modification 7/28/2003 to include Remove command.  Suggest synchronizing old and new server passwords 
'
'==========================================================================

On Error Resume Next

'open the file system object
Set oFSO = CreateObject("Scripting.FileSystemObject")
set WSHShell = wscript.createObject("wscript.shell")
'open the data file
Set oTextStream = oFSO.OpenTextFile("wslist.txt")
'make an array from the data file
RemotePC = Split(oTextStream.ReadAll, vbNewLine)
'close the data file
oTextStream.Close

For Each strWorkstation In RemotePC
'Do something useful with strWorkstation
Call WSHShell.Run("cmd.exe /c NETDOM REMOVE " & strWorkstation &"/Domain:<domain> /UserD:<user> /PasswordD:<password> UserO:<user> /PasswordO:<password> /REBoot:30000")
Wscript.sleep 15000
Call WSHShell.Run("cmd.exe /c NETDOM JOIN " & strWorkstation &"/Domain:<domain> /UserD:<user> /PasswordD:<password> UserO:<user> /PasswordO:<password> /REBoot:0")

Next