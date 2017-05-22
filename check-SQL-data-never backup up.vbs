'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalScript 2009
'
' NAME: New and Improved Two-State Monitor Script to Identify SQL Databases Never Backed Up
'
' AUTHOR: Bob Messer, David Scheltens, et al
' DATE  : 11/13/2009
'
' COMMENT: This script, designed for use in an OpsMgr two-state monitor, will alert on databases 
'          not based up within a user-defined threshold
'
'ORIGINAL POST: http://www.systemcentercentral.com/BlogDetails/tabid/143/IndexId/50132/Default.aspx
'   
'RELATED POSTS: How to create a two-state monitor in OpsMgr 2007
'               http://www.systemcentercentral.com/Downloads/DownloadsDetails/tabid/144/IndexID/7362/Default.aspx 
'
'
'
'==========================================================================

' ---------------------------------------------------------
' SQL Full or Diff Backup check for OpsMgr 2007 2-state monitor
' ---------------------------------------------------------
' Param 0: The SQL connection string for the server 
' Param 1: The Database to use
' Param 2: The threshold (in hours) to use
' Author:  David Scheltens
' Date:    02-02-2009
' ---------------------------------------------------------
Option Explicit
 
Sub Main()
 
    Dim oAPI, strServer, strDatabase, iThresholdHours, objBag, strErrDescription, objArgs, I, Param, strReason, strHours, strStatus
 
    Const EVENT_TYPE_ERROR = 1
    Const EVENT_TYPE_WARNING = 2
    Const EVENT_TYPE_INFORMATION = 4
 
      ' Initialize SCOM Script object
    Set oAPI = CreateObject("MOM.ScriptAPI")
 
      ' Write Parameters to eventlog
      ' Enable for debugging.
      Set objArgs = Wscript.Arguments
      For I = 0 to objArgs.Count -1
          Param = objArgs(I)
           'strErrDescription = strErrDescription & ", " & Param
      Next
          'call oAPI.LogScriptEvent("SQL Full or Diff Backup Check.vbs", 1313, EVENT_TYPE_INFORMATION, strErrDescription)    
 
    If WScript.Arguments.Count = 3 then
 
        
        ' Retrieve parameters
        strServer = CStr(WScript.Arguments(0))
        strDatabase = CStr(WScript.Arguments(1))
 
        If LCase(strDatabase) = "tempdb" Then
            
            Set objBag = oAPI.CreateTypedPropertyBag(2)
            
            ' tempdb is always ok
            Call objBag.AddValue("BackupType", "Full or differential backup")
            Call objBag.AddValue("NumHours", "0")
            Call objBag.AddValue("Reason", "Database tempdb is skipped.")
            Call objBag.AddValue("Status","OK")            
            strHours = "0"
            strStatus = "OK"
            strReason = "Database tempdb is skipped."
            
            oAPI.AddItem(objBag)        
 
        Else
 
            iThresholdHours = 0
            iThresholdHours = CInt(WScript.Arguments(2))
            
            'Connect to the database
            Dim cnADOConnection 
            Set cnADOConnection = CreateObject("ADODB.Connection") 
            cnADOConnection.Provider = "sqloledb" 
            cnADOConnection.ConnectionTimeout = 60
            Dim ConnString
            ConnString = "Server=" & strServer & ";Database=master;Integrated Security=SSPI" 
            cnADOConnection.Open ConnString
            
            'Connection established, now run the code
            Dim oResults 
            Set oResults = cnADOConnection.Execute( _ 
                "SELECT TOP 1 " & _
                    "MAX([bs].[backup_start_date]) AS [lasttime], " & _
                    "DATEDIFF(hour, MAX([bs].[backup_start_date]), GETDATE()) AS [numhours] " & _
                "FROM " & _
                    "[master].[dbo].[sysdatabases] AS [sd] WITH (NOLOCK) " & _
                "LEFT JOIN " & _
                    "[msdb].[dbo].[backupset] AS [bs] WITH (NOLOCK) ON ([bs].[database_name] COLLATE SQL_Latin1_General_CP1_CI_AS  = [sd].[name]) " & _
                "WHERE " & _
                    "[sd].[name] COLLATE SQL_Latin1_General_CP1_CI_AS = '" & strDatabase & "' " & _
                    "AND " & _
                    "[bs].[type] IN ('D', 'I') " & _
                "GROUP BY " & _
                    "[bs].[type] " & _
                "ORDER BY " & _
                    "1 DESC;" _
                )
 
            ' should be just one record
            ' oResults.MoveFirst
 
            Set objBag = oAPI.CreateTypedPropertyBag(2)
            If oResults.EOF Then    
                ' a backup is never made!
                Call objBag.AddValue("BackupType", "Full or differential backup")
                Call objBag.AddValue("NumHours", "9999")
                Call objBag.AddValue("Reason", "A full backup for database " & strDatabase & " is never be made!")
                Call objBag.AddValue("Status","Bad")            
                strStatus = "Bad"
                strHours = "9999"
                strReason = "A full backup for database " & strDatabase & " is never be made!"
            Else
                ' backup is made
                Call objBag.AddValue("BackupType", "Full or differential backup")
                Call objBag.AddValue("NumHours", CStr(oResults(1)))
                strHours = CStr(oResults(1))
                
                If CInt(oResults(1)) > iThresholdHours Then
                    ' last backup is too old
                    Call objBag.AddValue("Reason", "The last full or differential backup for database " & strDatabase & " is more than " & oResults(1) & " hours old!")
                    Call objBag.AddValue("Status","Bad")            
                    strReason = "The last full or differential backup for database " & strDatabase & " is more than " & oResults(1) & " hours old!"
                    strStatus = "Bad"
                Else
                    ' backups is ok
                    Call objBag.AddValue("Reason", "The last full or differential backup for database " & strDatabase & " SHOULD NOT BE ALERTING BECAUSE IT is less than " & CStr(iThresholdHours) & " hours old.")
                    Call objBag.AddValue("Status","OK")            
                    strReason = "The last full or differential backup for database " & strDatabase & " SHOULD NOT BE ALERTING BECAUSE IT is less than " & CStr(iThresholdHours) & " hours old."
                    strStatus = "OK"
                End If
            End If            
            oAPI.AddItem(objBag)
            
            cnADOConnection.Close
 
        End If
            
        'return the property bag objects
        Call oAPI.ReturnItems
 
        ' Log results into Operations Manager event log
             ' Enable for debugging.
        ' Call oAPI.LogScriptEvent("SQLCustomBackupMonitor.vbs", 101, 4, "SQLCustomBackupMonitor.vbs returned the following values to SCOM for " & strDatabase & "  Reason:" & strReason & "  Hours:" & strHours & "  Status:" & strStatus)
 
    End If 
        
End Sub
 
Call Main()
 