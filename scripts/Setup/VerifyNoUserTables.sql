/*
*********************************************************************
Copyright (C) 2010 Expedia, Inc. All rights reserved.

Description:
    This script will raise an error if the database contains user
    tables. It is used as a verification script prior to running setup.

Change History:
    Date        Author          Description
    ----------  --------------- ------------------------------------
    2010-11-19  Steve Couch     Created.
*********************************************************************
*/

if exists(select [name] from sys.objects where [type] = 'u') begin
    raiserror ('Error: This database contains user tables!', 16, 1)
end
go
