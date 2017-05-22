/*
*********************************************************************
Copyright (C) 2005 Expedia, Inc.
All rights reserved.

Description:
Encrypt the connection string in the dbo.PackageConfigurationParent table for ICRSConfig Data Push Job 
and the DestinationConnString items order should like below:
Data Source=XXXXXXX;User ID=XXXXXXX;Initial Catalog=XXXXXXX;Provider=XXXXXXX;Auto Translate=XXXXXXX;pwd=XXXXXXX

Change History:
Date        Author         Description
----------  -------------  ------------------------------------
2011-06-17  v-wuwang       Created
*********************************************************************
*/

-- Run this script on <server> in <database>

SET NOCOUNT ON


PRINT '/*************************************'
PRINT 'DB Name     : ' + cast( serverproperty ( 'ServerName' ) as varchar ) + '.' + db_name()
if serverproperty ( 'MachineName' ) <> serverproperty ( 'ServerName' )
    PRINT 'MachineName : ' + cast( serverproperty ( 'MachineName' ) as varchar )
PRINT 'DB User     : ' + current_user
PRINT 'System User : ' + system_user
PRINT 'Host        : ' + host_name() 
PRINT 'Application : ' + app_name()
PRINT 'Started at  : ' + convert( varchar(23), getdate(), 121 )
PRINT '*************************************/'
PRINT ''
PRINT 'RESULTS:'


PRINT ''
PRINT '--Started at ' + convert(varchar(23),getdate(),121)
GO


DECLARE
    @FALSE                          TINYINT,
    @TRUE                           TINYINT,
    @BugNumber                      VARCHAR(10),
	@ProcedureName                  sysname,	
    @SavePointName                  nvarchar(64),    
    @MsgParm1                       varchar(200),
    @MsgParm2                       varchar(200),
    @MsgParm3                       varchar(200),
    @MsgParm4                       varchar(200),
    @ErrorMsg                       nvarchar(4000),
    @ErrorNumber					int,	
    @ErrorSeverity                  int,
    @ErrorState                     int,
    @ErrorLine                      int	
   
SELECT
    @FALSE                          = 0,
    @TRUE                           = 1      

SELECT
    @BugNumber                      = '8536',
-- Standard variables
    @SavePointName                  = '$' + cast(@@NestLevel as varchar(15))
                                    + '_' + @ProcedureName,
    @ErrorMsg                       = 'Unknown',
    @ErrorSeverity                  = 16,
    @ErrorState                     = 1,
    @ErrorLine                      = 0	

-- Encrypt the SourceConnString and DestinationConnString columns 
USE RollCall
Print 'Before Encrypt'
select SourceConnString,DestinationConnString from PackageConfigurationParent 


Print 'Encrypt the SourceConnString and DestinationConnString columns'

Update P
set SourceConnString=N'Provider=SQLNCLI10;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=RollCall;Data Source=chelsqlcctst02;Auto Translate=False;'
,DestinationConnString=N'Data Source=chelsqlcrm05;User ID=ICRSDataPushUser;'+N'Initial Catalog=ICRSConfig;Provider=SQLNCLI10;Auto Translate=False;pwd='+CAST(EncryptByPassPhrase('Expedia ICRS',N'z00mAir1!') AS NVARCHAR(4000))
from PackageConfigurationParent P
where PackageParentID=3



Print 'After Encrypt'
select SourceConnString,DestinationConnString from PackageConfigurationParent 

	

GOTO ExitScript

---------------------------------------------------------------------
-- Error Handler
---------------------------------------------------------------------
-- If there was an error rollback the transaction, raise an error, and exit
ErrorHandler:
    -- The transaction states are:
			--    1.  xact_state() =  1:  we have a valid transaction.
			--    2.  xact_state() =  0:  we have no open transaction.
			--    3.  xact_state() = -1:  we have a doomed transaction.
			-- If the state is "1", we have a valid transaction and we can roll back to our
			-- save point.  If the state is "-1" (doomed) and we initiated the transaction 
			-- from this code module (@@Trancount = 1), then we'll roll back the entire
			-- transaction since nothing more can be done with it, and the caller does not
			-- have a pending transaction to resolve.  If the state is "0", there is no
			-- transaction to roll back.

			if xact_state() = 1 rollback transaction @SavePointName
			else if @@Trancount = 1 and xact_state() = -1 rollback transaction 

			select @ErrorMsg      = 'SP: %s; UNEXPECTED ERROR - Line: %d; Error: %d, ' + error_message(),
				   @ErrorNumber   = error_number(),
				   @ErrorSeverity = error_severity(),
				   @ErrorState    = error_state(),
				   @ErrorLine     = error_line()

			raiserror (@ErrorMsg, @ErrorSeverity, @ErrorState, @ProcedureName, @ErrorLine, @ErrorNumber)
			PRINT CONVERT(VARCHAR(25), GETDATE(), 121) + ' ' + @BugNumber + ' - Failed'

---------------------------------------------------------------------
-- Exit Script
---------------------------------------------------------------------
ExitScript:
    PRINT CONVERT(VARCHAR(25), GETDATE(), 121) + ' ' + @BugNumber + ' - Completed'
/*
*********************************************************************
End script for Bug: 
*********************************************************************
*/
go

PRINT ''
PRINT '--Completed at ' + convert(varchar(23),getdate(),121)
go

