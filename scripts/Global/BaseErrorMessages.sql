/*
*********************************************************************
Copyright (C) 2010 Expedia, Inc. All rights reserved.

Description:
    This script will create the custom error messages.

Change History:
    Date        Author          Description
    ----------  --------------- ------------------------------------
    2010-11-30  Steve Couch     Created.
*********************************************************************
*/

exec dbo.sp_addmessage 200100, 16, 'SP: %s. Record not found in table: %s; key: %s.', null, false, REPLACE
exec dbo.sp_addmessage 200101, 16, 'SP: %s. Duplicate record for table: %s; key: %s.', null, false, REPLACE
exec dbo.sp_addmessage 200102, 16, 'SP: %s. Referential integrity violation in parent table: %s, key: %s; child table: %s, key: %s.', null, false, REPLACE
exec dbo.sp_addmessage 200103, 16, 'SP: %s. Maximum count of %s exceeded for %s.', null, false, REPLACE
exec dbo.sp_addmessage 200104, 16, 'SP: %s. Unexpected error. See previous error messages. Error number: %s.', null, false, REPLACE
exec dbo.sp_addmessage 200105, 16, 'SP: %s. Number of columns supplied by %s does not match number expected by %s.', null, false, REPLACE
exec dbo.sp_addmessage 200106, 16, 'SP: %s. Unexpected error: %i-%s', null, false, REPLACE
exec dbo.sp_addmessage 200110, 16, 'SP: %s. Parameter is invalid. Parameter: %s; value: %s.', null, false, REPLACE

go
