<# 
.SYNOPSIS  
    Change the database collation for a given database and propogate it down to each column 
.DESCRIPTION  
    This script will change the collation for a given database and propogate it down to each column making sure that all keys/indexes/statistics etc are dropped and re-created
.NOTES  
    File Name  : Change-Collation.ps1  
    Author     : Martin Bell
    Requires   : PowerShell V2
.LINK  
    Blog:  
    http://sqlblogcasts.com/blogs/martinbell/
.EXAMPLE  
    Usage, Windows autentication
    PS C:\Powershell> .\Change-Collation.ps1 -WorkingDirectory 'C:\Powershell\ChangeCollation\' -Collation 'Latin1_General_CS_AS' -Server '(local)' -Database 'Adventureworks2008'
    ----  
    WorkingDirectory  : C:\Powershell\ChangeCollation\
    Collation         : Latin1_General_CS_AS
    Server            : (local)
    Database          : Adventureworks2008
    Username          : 
    Password          : 
    ----
.EXAMPLE  
    Usage, SQL autentication
    PS C:\Powershell> .\Change-Collation.ps1 -WorkingDirectory 'C:\Powershell\ChangeCollation\' -Collation 'Latin1_General_CS_AS' -Server '(local)' -Database 'Adventureworks2008' -Username Martin -Password SecretPassword
    ----
    WorkingDirectory  : C:\Powershell\ChangeCollation\
    Collation         : Latin1_General_CS_AS
    Server            : (local)
    Database          : Adventureworks2008
    Username          : Martin
    Password          : SecretPassword
    ----
.PARAMETER WorkingDirectory
    Working directory for scripts and log - must be a string  
.PARAMETER Collation
    New Collation - must be a string  
.PARAMETER Server
    SQL Server Instance - must be a string  
.PARAMETER Database
    Database to change - must be a string  
.PARAMETER Username
    Username for SQL Login - optional string  
.PARAMETER Password
    Password for SQL Login - optional string  
#>  
param(
[Parameter(Position=0, Mandatory=$true, HelpMessage="Parameter missing: -WorkingDirectory WorkingDirectory" )]  
[string]$WorkingDirectory,
[Parameter(Position=0, Mandatory=$true, HelpMessage="Parameter missing: -Collation Collation")]  
[string]$Collation,
[Parameter(Position=0, Mandatory=$true, HelpMessage="Parameter missing: -Server Server")]  
[string]$Server,
[Parameter( Position=0, Mandatory=$true, HelpMessage="Parameter missing: -Database Database")]  
[string]$Database,
[Parameter(Position=0, Mandatory=$false)]  
[string]$Username="",
[Parameter(Position=0, Mandatory=$false)]  
[string]$Password=""
)

[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")  | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null


if ( Get-PSSnapin -Registered | where {$_.name -eq 'SqlServerCmdletSnapin100'} )
{
	if( !(Get-PSSnapin | where {$_.name -eq 'SqlServerCmdletSnapin100'}))
	{ 
		Add-PSSnapin SqlServerCmdletSnapin100 | Out-Null
	} ;
}
else
{
	if( !(Get-Module | where {$_.name -eq 'sqlps'}))
	{ 
		Import-Module 'sqlps' -DisableNameChecking ;
	}  ;
}

<#
    .SYNOPSIS 
    Creates a log file.

    .DESCRIPTION
    Creates a log file. The name of the file will be stored in the global variable $global:logfile

    .PARAMETER Logoutputfile 
    Specifies the file name for the logfile.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Create-Log 'C:\Powershell\CollationLog.txt'

    .EXAMPLE
    C:\PS> Create-Log ""
#>
function Create-Log ( [string] $Logoutputfile="" ) {

    if ( $Logoutputfile -eq "" ) { 
        $global:logfile = "C:\temp\Collation_Change_" + (get-date -format "yyyyMMddHHmmss") + ".log" ; 
        if ((Test-Path -Path "C:\temp") -eq $false ) {
            Write-Host "Create directory C:\Temp" ;
            $dir = New-Item -type directory "C:\Temp" ;
        } ;
    } else { 
        $global:logfile = $Logoutputfile ; 
    } 
	$logitem = "***********************************************************************************`r`nCollation change for database $Database starting " + (get-date -format "dd/MM/yyyy HH:mm:ss") + "`r`n***********************************************************************************" ; 
    $file = New-Item $global:logfile -type File -value $logitem  -force ; 
    Write-Host $logitem ; 
}

<#
    .SYNOPSIS 
    Add information to a log file.

    .DESCRIPTION
    Adds information to a log file.

    .PARAMETER Logitem 
    Specifies the information to add to the logfile specified in the global variable $global:logfile. This file must exist.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Write-Log "Audit Information"

    .EXAMPLE
    C:\PS> Write-Log $logstring
#>
function Write-Log ( [string] $logitem ) {

    Add-Content -path $global:logfile -value $logitem ; 
    Write-Host $logitem ; 
}

<#
    .SYNOPSIS 
    Connect to a database server.

    .DESCRIPTION
    Connect to a database server. Connection $conn must exist

    .PARAMETER Server 
    Specifies the SQL Server instance to connect to

    .PARAMETER Username 
    Specifies the Username of a SQL User - optional string

    .PARAMETER Password
    Specifies the Password of a SQL User - optional string

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection ; 
    C:\PS> Connect-Server '(local)' 

    .EXAMPLE
    C:\PS> $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection ; 
    C:\PS> Connect-Server '(local)'  'Martin' 'SecretPassword'
#>
function Connect-Server ( [string] $Server, [string] $Username = "", [string] $Password = "" ) {

    try {
        if ( $Username -ne "" ) {
            $conn.LoginSecure = $false; 
            $conn.Login = $Username ; 
            If ( $Password -ne "" ) {
                $conn.Password = $Password ; 
            } ;
        } else {
            $conn.LoginSecure = $true ; 
        } ;
        $conn.ServerInstance = $Server ; 
        $conn.NonPooledConnection = $true ; 
		$conn.StatementTimeout = 0 ;
        write-log $conn ;
        $conn.connect() ;
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error connecting to database server: " ; 
        Write-Log $err ; 
        Throw "Error connecting to database server"  ;
    }
} 

<#
    .SYNOPSIS 
    Checks the collation of a database against a given collation.

    .DESCRIPTION
    Checks the collation of a database against a given collation. $db should exist

    .PARAMETER Collation
    Specifies the collation to be checked

    .INPUTS
    None.

    .OUTPUTS
    Function returns the $true if the collations are the same or $false if not

    .EXAMPLE
    C:\PS> Check-Collation 'Latin1_General_CS_AS' 
#>
function Check-Collation ( [string] $Collation  ){

    try {
        return ( $db.Collation -eq $Collation ) 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error Checking Collation: " ; 
        Write-Log $err ; 
        Throw "Error Checking Collation" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop fulltext indexes

    .DESCRIPTION
    Scripts and drop all fulltext indexes based on columns that have the database collation.
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted fulltext indexes.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-Fulltextindexes 'C:\temp\FullTextIndexes.sql'

    .EXAMPLE
    C:\PS> Process-Fulltextindexes 'C:\temp\FullTextIndexes.sql' 'Martin' 'SecretPassword' 
#>
function Process-Fulltextindexes ( [string] $Sqlfile ) {

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Full Text Indexes to File: $Sqlfile " ;

#
# If a fulltext index uses referencs and index that has a column with the database collation then script the fulltext index
# Add it to the list so it is not scripted again (index can have multiple columns that have collation)
#
        $list = @{}
        foreach ($tbl in $db.Tables) {
			$ft = $tbl.FullTextIndex  ;
			if ( $ft -ne $null ) {
            	$ind = $tbl.Indexes.Item($ft.UniqueIndexName) ;
#					
# Remove Full Text Indexes where the Unique Index has a collated column
#
                foreach($indexcol in $ind.IndexedColumns) {
                	$col = $tbl.Columns.Item($indexcol.Name);
                    if($col.Computed -eq $true -or $col.Collation -eq $db.Collation) {
                    	if(-not $list.Contains($ft)) {
                        	$list.Add($ft, $tbl.Name);
                            $Scripter.Script($ft);
                            $logitem =  "Dropping FullText Index Table: " + $tbl + " Index: " + $ft.UniqueIndexName + " Catalog: " + $ft.CatalogName  ;;
                            Write-Log $logitem  ;
                            $ft.Drop();
                        }
					}
				}
#
# Remove Full Text Indexes where the Unique Index has a collated column
#					
                foreach($FullTextIndexColumn in $ft.IndexedColumns) {
                	$col = $tbl.Columns.Item($FullTextIndexColumn.Name);
                    if($col.Computed -eq $true -or $col.Collation -eq $db.Collation) {
                    	if(-not $list.Contains($ft)) {
                        	$list.Add($ft, $tbl.Name);
                            $Scripter.Script($ft);
                            $logitem =  "Dropping FullText Index Table: " + $tbl +  " Index: " + $ft.UniqueIndexName + " Catalog: " + $ft.CatalogName  ;;
                            Write-Log $logitem  ;
                            $ft.Drop();
						}
					}
				}
					
			}
		} ;
        Write-Log "End Process-Fulltextindexes" ; 
    } 
    catch {
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting FullTextIndexes: " ; 
        Write-Log $err ; 
        Throw "Error scripting FullTextIndexes" ;
    }
}

<#
    .SYNOPSIS 
    Scripts and drop foreign keys

    .DESCRIPTION
    Scripts and drop all foreign keys referencing/referenced by columns that have the database collation.
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted foreign keys.

    .INPUTS
    None.
	
    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-ForeignKeys 'C:\temp\ForeignKeys.sql'

    .EXAMPLE
    C:\PS> Process-ForeignKeys 'C:\temp\ForeignKeys.sql' 'Martin' 'SecretPassword'
#>
function Process-ForeignKeys ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.DriForeignKeys=$True ;
        $Scripter.Options.SchemaQualifyForeignKeysReferences=$True ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Foreign Keys to File: $Sqlfile " ;
#
# If a referenced column has the database collation then script the foreign key
# Add it to the list so it is not scripted again
#
        $list = @{}
            foreach ($tbl in $db.Tables) {
                foreach ($fk in $tbl.ForeignKeys) {
                    foreach($fkcol in $fk.Columns) {
#					
# Columns in a Foreign Key must have the same collation as those they are referencing
#
                        $col = $tbl.Columns[$fkcol.Name];
                        if ( $col.Collation -eq $db.Collation ) {
                            if(-not $list.Contains($fk)) {
                                $list.Add($fk, $tbl.Name);
                                $Scripter.Script($fk);
                            }
                        }
                    }
                }
            } ;
        foreach ( $fk in $list.keys ) {
            $logitem =  "Dropping Foreign Key Table: " + $fk.Parent + " Constraint: " + $fk.Name ;
            Write-Log $logitem  ;
            $fk.Drop();
	    } ;
		Write-Log "End Process-ForeignKeys" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Foreign Keys: " ; 
        Write-Log $err ; 
        Throw "Error scripting Foreign Keys" ;
    }
}

<#
    .SYNOPSIS 
    Scripts and drop Index/Primary key

    .DESCRIPTION
    Scripts and drop all Indexes/Primary keys on columns that have the database collation.
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted indexes.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-Indexes 'C:\temp\Indexes.sql'

    .EXAMPLE
    C:\PS> Process-Indexes 'C:\temp\Indexes.sql' 'Martin' 'SecretPassword' 
#>
function Process-Indexes ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Indexes to File: $Sqlfile " ;

#
# If a index column has the database collation or is a computed column then script the index
# Add it to the list so it is not scripted again
#
        $list = @{}
            foreach ($tbl in $db.Tables) {
                foreach ($ind in $tbl.Indexes) {
                    foreach($indexcol in $ind.IndexedColumns) {
                        $col = $tbl.Columns.Item($indexcol.Name);
                        if($col.Computed -eq $true -or $col.Collation -eq $db.Collation) {
                            if(-not $list.Contains($ind)) {
                                $list.Add($ind, $tbl.Name);
                                $Scripter.Script($ind);
                            }
                        }
                    }
                }
            } ;
        foreach ( $ind in $list.keys ) {
            $logitem =  "Dropping Index Key Table: " + $ind.Parent + " Constraint: " + $ind.Name ;
            Write-Log $logitem  ;
            $ind.Drop();
	    } ;
        Write-Log "End Process-Indexes" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Index: " ; 
        Write-Log $err ; 
        Throw "Error scripting Index"  ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop Check Constraints

    .DESCRIPTION
    Scripts and drop all Check Constraints on tables that have a column with the database collation.
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted check constraints.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-CheckConstraints 'C:\temp\CheckConstraints.sql'

    .EXAMPLE
    C:\PS> Process-CheckConstraints 'C:\temp\CheckConstraints.sql' 'Martin' 'SecretPassword'
#>
function Process-CheckConstraints ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.DriChecks=$True ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Check Constraints to File: $Sqlfile " ;
#
# Drop all Check constraints on a table
#
        $list = @{}
            foreach ($tbl in $db.Tables) {
                foreach ($chk in $tbl.Checks) {
                    if(-not $list.Contains($chk)) {
                        $list.Add($chk, $tbl.Name);
                        $Scripter.Script($chk);
                    }
                }
            } ;

		foreach ( $chk in $list.keys ) {
            $logitem =  "Dropping Check Constraint Table: " + $chk.Parent + " Constraint: " + $chk.Name ;
            Write-Log $logitem  ;
            $chk.Drop();
	    } ;

        Write-Log "End Process-CheckConstraints" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Check Constraints: " ; 
        Write-Log $err ; 
        Throw "Error scripting Check Constraints" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop statistics

    .DESCRIPTION
    Scripts and drop all statistics on columns with the database collation. Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted statistics.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-Statistics 'C:\temp\Statistics.sql'

    .EXAMPLE
    C:\PS> Process-Statistics 'C:\temp\Statistics.sql' 'Martin' 'SecretPassword'
#>
function Process-Statistics ( [string] $Sqlfile){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Statistics to File: $Sqlfile " ;

#
# If a referenced column has the database collation then script the statistics
# Add it to the list so it is not scripted again
# Exclude auto-created stats
#
        $list = @{}
            foreach ($tbl in $db.Tables) {
                foreach ($stat in $tbl.Statistics) {
                    if($stat.IsAutoCreated -eq 0 ) {
                        foreach($StatisticColumn  in $stat.StatisticColumns ) {
                            $col = $tbl.Columns[$StatisticColumn.Name];
                            if( $col.Collation -eq $db.Collation) {
                                if(-not $list.Contains($stat)) {
                                    $list.Add($stat, $tbl.Name);
                                    $Scripter.Script($stat);
                                }
                            }
                        }
                    }
                }
            } ;

		foreach ( $stat in $list.keys ) {
            $logitem =  "Dropping Foreign Key Table: " + $stat.Parent + " Statistic: " + $stat.Name ;
            Write-Log $logitem  ;
            $stat.Drop();
	    } ;

		Write-Log "End Process-Statistics" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Statistics: " ; 
        Write-Log $err ; 
        Throw "Error scripting Statistics" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop schema bound functions

    .DESCRIPTION
    Scripts and drop all schema bound functions. Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted schemabound functions .

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-SchemaBoundFunctions 'C:\temp\SchemaBoundFunctions.sql'
#>
function Process-SchemaBoundFunctions ( [string] $Sqlfile  ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Schema Bound Functions to File: $Sqlfile " ;

#
# Script all schemabound functions
#
        ForEach ( $Function in $db.UserDefinedFunctions | Where { $_.IsSchemaBound -eq $true } ) { 

            $Scripter.Script($Function) ;
            $logitem =  "Dropping Function: " + $Function.Schema + "." + $Function.Name ;
            Write-Log $logitem  ;
            $Function.Drop() ;
        } ;
        Write-Log "End Process-SchemaBoundFunctions" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Schema Bound Function: " ; 
        Write-Log $err ; 
        exit ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop schema bound views

    .DESCRIPTION
    Scripts and drop all schema bound views. Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted schemabound views .

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-SchemaBoundViews 'C:\temp\SchemaBoundViews.sql'
#>
function Process-SchemaBoundViews ( [string] $Sqlfile  ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Schema Bound Views to File: $Sqlfile " ;
#
# Script all schemabound views
#
        ForEach ( $view in $db.Views | Where { $_.IsSchemaBound -eq $true } ) { 

            $Scripter.Script($view) ;
            $logitem =  "Dropping View: " + $view.Schema + "." + $view.Name ;
            Write-Log $logitem  ;
            $view.Drop() ;
        } ;
Write-Log "End Process-SchemaBoundViews" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting View: " ; 
        Write-Log $err ; 
        Throw "Error scripting View" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop computed columns

    .DESCRIPTION
    Scripts and drop all computed columns. Requires $db to be the database to change.

    .PARAMETER NewCollation
    New collation for columns

    .PARAMETER Sqlfile 
    Specifies the file for the scripted computed columns.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-ComputedColumns  'Latin1_General_CS_AS' 'C:\temp\SchemaBoundFunctions.sql'
#>
function Process-ComputedColumns ( [string] $NewCollation, [string] $Sqlfile ){

    try {
        ForEach ( $tbl in $db.Tables | Where { $_.IsSystemObject -eq $false } ) { 
			$list = @() ;
            ForEach ( $col in $tbl.Columns | Where { $_.Computed -eq $true }  ) { 
	            if ( $list -notcontains $col.Name ) {
					$list += $col.Name ;
					$logitem =  "Scripting Computed Column Table: " + $tbl.Schema + "." + $tbl.Name + " Column: " + $col.Name ;
    	            Write-Log $logitem  ;
        	        $altercmd = "ALTER TABLE $tbl  ADD $col AS " + $col.ComputedText + ";`r`nGO`r`n";
            	    Add-Content -path $Sqlfile -value $altercmd ; 
                	$logitem =  "Dropping Computed Column Table: " + $tbl.Schema + "." + $tbl.Name + " Column: " + $col.Name + " Position: " + $col.ID.ToString()  + " of " + $tbl.Columns.Count.ToString() ;
                	Write-Log $logitem  ;
                	$col.Drop() ;
                	$tbl.Alter(); 
	            } ;
            } ;
        } ;
        Write-Log "End Process-ComputedColumns" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error processing computed column: " ; 
        Write-Log $err ; 
        Throw "Error processing computed column" ; 
    }
}

<#
    .SYNOPSIS 
    Chamges collation for all columns

    .DESCRIPTION
    Chamges collation for all columns. Requires $db to be the database to change.

    .PARAMETER NewCollation
    New collation for columns

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-Columns 'Latin1_General_CS_AS'
#>
function Process-Columns ( [string] $NewCollation ){

    try {
        Write-Log "Changing Column Collations" ;

        ForEach ( $tbl in $db.Tables | Where { $_.IsSystemObject -eq $false } ) { 
                
            ForEach ( $col in $tbl.Columns | Where { $_.Collation -eq $db.Collation -and $_.Computed -eq $false }  ) { 
                $logitem =  "Changing Collation Table: " + $tbl.Schema + "." + $tbl.Name + " Column: " + $col.Name ;
                Write-Log $logitem  ;
                $col.Collation = $NewCollation ;
                $col.Alter() ;
            } ;
        } ;
        Write-Log "End Process-Columns" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error changing column collation: " ; 
        Write-Log $err ; 
        Throw "Error changing column collation" ; 
    }
}

<#
    .SYNOPSIS 
    Changes the database collation

    .DESCRIPTION
    Changes the database collation. Requires $db to be the database to change and $srv the server.

    .PARAMETER NewCollation
    New collation for columns

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-Database 'Latin1_General_CS_AS'

    .EXAMPLE
    C:\PS> Process-Database 'Latin1_General_CS_AS' 'Martin' 'SecretPassword'
#>
function Process-Database ( [string] $NewCollation ){

    try {
        $db.UserAccess = "Single" ;
        $db.Alter([Microsoft.SqlServer.Management.Smo.TerminationClause]::RollbackTransactionsImmediately) ;
        $db.Collation = $NewCollation ;
        $db.UserAccess = "Multiple" ;
        $db.Alter() ;
        Write-Log "End Process-Database" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error ruuning script $Sqlfile : " ; 
        Write-Log $err ; 
        Throw "Error ruuning script $Sqlfile" ; 
    }
}

<#
    .SYNOPSIS 
    Runs the given SQL file

    .DESCRIPTION
    Runs the given SQL file using Invoke-Sqlcmd.

    .PARAMETER SqlFile
    Name of the SQL File to process

    .PARAMETER Server
    Specifies the SQL Server Instance to connect to.

    .PARAMETER Database
    Specifies the Database to connect to
    
    .PARAMETER Username 
    Specifies the Username of a SQL User - optional string

    .PARAMETER Password
    Specifies the Password of a SQL User - optional string

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-SQLFile 'C:\temp\SchemaBoundFunctions.sql' '(local)' "Adventurworks2008"

    .EXAMPLE
    C:\PS> Process-SQLFile 'C:\temp\SchemaBoundFunctions.sql' '(local)' "Adventurworks2008" 'Martin' 'SecretPassword'
#>
function Process-SQLFile ( [string] $Sqlfile, [string] $Server, [string] $Database, [string] $Username = "", [string] $Password = ""  ){

    try {
        Write-Log "Running SQLFile $Sqlfile" ; 

        if ((Test-Path -Path $Sqlfile) -eq $true ) {
            if ( $Username -ne "" ) {
                Invoke-Sqlcmd -ServerInstance  $Server -Database $Database -Username $Username -Password $Password  -InputFile $Sqlfile -AbortOnError -QueryTimeout 3000 ;
            } else {
                Invoke-Sqlcmd -ServerInstance  $Server -Database $Database -InputFile $Sqlfile -AbortOnError -QueryTimeout 3000 ;
            } ;
        } ;
        Write-Log "End Process-SQLFile $Sqlfile" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error running script $Sqlfile : " ; 
        Write-Log $err ; 
        Throw "Error running script $Sqlfile" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop dependent check constraints

    .DESCRIPTION
    Scripts and drop all check constriants dependent on columns that have the database collation (using sys.sql_constraints).
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted check constraints.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-DependentCheckConstraints 'C:\temp\DependentCheckConstraints.sql'

    .EXAMPLE
    C:\PS> Process-DependentCheckConstraints 'C:\temp\DependentCheckConstraints.sql' 'Martin' 'SecretPassword'
#>
function Process-DependentCheckConstraints ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.DriChecks=$True ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;

        Write-Log "Scripting Dependent Check Constraints to File: $Sqlfile " ;

        $sqlstmt = "SELECT DISTINCT s.name AS [Schema_Name], t.name AS [Table_Name], o.name AS [Constraint_Name]
        FROM sys.sql_dependencies d
        JOIN sys.columns c ON d.referenced_major_id = c.object_id AND d.referenced_minor_id = c.column_id 
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.objects o ON d.object_id = o.object_id
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE ( c.collation_name = CAST(DATABASEPROPERTYEX ( DB_NAME(), 'collation' ) AS varchar(128) ) COLLATE database_default
        OR c.is_computed = 1 )
        AND o.type = 'C'" ;

        $dataset = $db.ExecuteWithResults($sqlstmt);
        if($ds.IsInitialized)
        {
            # this has the columns that you specified in your SQL Statement.
            foreach($datarow in $ds.Tables[0].Rows) { 
                [Microsoft.SqlServer.Management.Smo.Table] $tbl = $db.Tables.Item($datarow.Table_Name , $datarow.Schema_Name )  ;
                [Microsoft.SqlServer.Management.Smo.Check] $constraint = $tbl.Checks.Item($datarow.Constraint_Name) ;
                $Scripter.Script($constraint) ;
                $logitem =  "Dropping Dependent Check Constraint Table: " + $datarow.Schema_Name + "." + $datarow.Table_Name + " Constraint: " + $datarow.Constraint_Name ;
                Write-Log $logitem  ;
                $constraint.Drop() ;
            }
        }

        Write-Log "End Process-DependentCheckConstraints" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Dependent Check Constraints: " ; 
        Write-Log $err ; 
        Throw "Error scripting Dependent Check Constraints" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop dependent functions

    .DESCRIPTION
    Scripts and drop all functions dependent on columns that have the database collation (using sys.sql_constraints).
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted functions.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-DependentFunctions 'C:\temp\DependentFunctions.sql'

    .EXAMPLE
    C:\PS> Process-DependentFunctions 'C:\temp\DependentFunctions.sql' 'Martin' 'SecretPassword'
#>
function Process-DependentFunctions ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Dependent Functions to File: $Sqlfile " ;

        $sqlstmt = "SELECT DISTINCT s.name AS [Schema_Name], o.name AS [Function_Name]
        FROM sys.sql_dependencies d
        JOIN sys.columns c ON d.referenced_major_id = c.object_id AND d.referenced_minor_id = c.column_id 
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.objects o ON d.object_id = o.object_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE ( c.collation_name = CAST(DATABASEPROPERTYEX ( DB_NAME(), 'collation' ) AS varchar(128) ) COLLATE database_default
        OR c.is_computed = 1 )
        AND ( o.type = 'FN'
        OR o.type = 'TF' ) " ;

        $dataset = $db.ExecuteWithResults($sqlstmt);
        if($dataset.IsInitialized)
        {
            # this has the columns that you specified in your SQL Statement.
            foreach($datarow in $dataset.Tables[0].Rows) { 
                [Microsoft.SqlServer.Management.Smo.UserDefinedFunction] $func = $db.UserDefinedFunctions.Item($datarow.Function_Name , $datarow.Schema_Name )  ;
                $Scripter.Script($func) ;
                $logitem =  "Dropping Dependent Function: " + $datarow.Schema_Name + "." + $datarow.Function_Name ;
                Write-Log $logitem  ;
                $func.Drop() ;
            }
        }

		Write-Log "End Process-DependentFunctions" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Dependent Functions: " ; 
        Write-Log $err ; 
        Throw "Error scripting Dependent Functions" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop dependent stored procedures

    .DESCRIPTION
    Scripts and drop all stored procedures dependent on columns that have the database collation (using sys.sql_constraints).
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted stored procedures.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-DependentProcedures 'C:\temp\DependentProcedures.sql'

    .EXAMPLE
    C:\PS> Process-DependentProcedures 'C:\temp\DependentProcedures.sql' 'Martin' 'SecretPassword'
#>
function Process-DependentProcedures ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;

        Write-Log "Scripting Dependent Procedures to File: $Sqlfile " ;

        $sqlstmt = "SELECT DISTINCT s.name AS [Schema_Name], o.name AS [Procedure_Name]
        FROM sys.sql_dependencies d
        JOIN sys.columns c ON d.referenced_major_id = c.object_id AND d.referenced_minor_id = c.column_id 
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.objects o ON d.object_id = o.object_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE ( c.collation_name = CAST(DATABASEPROPERTYEX ( DB_NAME(), 'collation' ) AS varchar(128) ) COLLATE database_default
        OR c.is_computed = 1 )
        AND o.type = 'P'" ;

        $dataset = $db.ExecuteWithResults($sqlstmt);
        if($ds.IsInitialized)
        {
            # this has the columns that you specified in your SQL Statement.
            foreach($datarow in $ds.Tables[0].Rows) { 
                [Microsoft.SqlServer.Management.Smo.StoredProcedure] $proc = $db.StoredProcedures.Item($datarow.Procedure_Name , $datarow.Schema_Name )  ;
                $Scripter.Script($proc) ;
                $logitem =  "Dropping Dependent Procedure: " + $datarow.Schema_Name + "." + $datarow.Procedure_Name ;
                Write-Log $logitem  ;
                $proc.Drop() ;
            }
        }

        Write-Log "End Process-DependentProcedures" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Dependent Procedures: " ; 
        Write-Log $err ; 
        Throw "Error scripting Dependent Procedures" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop dependent views

    .DESCRIPTION
    Scripts and drop all views dependent on columns that have the database collation (using sys.sql_constraints).
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted views.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-DependentViews 'C:\temp\DependentViews.sql'

    .EXAMPLE
    C:\PS> Process-DependentViews 'C:\temp\DependentViews.sql' 'Martin' 'SecretPassword'
#>
function Process-DependentViews ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Dependent Views to File: $Sqlfile " ;

        $sqlstmt = "SELECT DISTINCT s.name [Schema_Name], o.name AS [View_Name]
        FROM sys.sql_dependencies d
        JOIN sys.columns c ON d.referenced_major_id = c.object_id AND d.referenced_minor_id = c.column_id 
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.objects o ON d.object_id = o.object_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE ( c.collation_name = CAST(DATABASEPROPERTYEX ( DB_NAME(), 'collation' ) AS varchar(128) ) COLLATE database_default
        OR c.is_computed = 1 )
        AND o.type = 'V'" ;

        $dataset = $db.ExecuteWithResults($sqlstmt);
        if($ds.IsInitialized)
        {
            # this has the columns that you specified in your SQL Statement.
            foreach($datarow in $ds.Tables[0].Rows) { 
                [Microsoft.SqlServer.Management.Smo.View] $view = $db.Views.Item($datarow.View_Name , $datarow.Schema_Name )  ;
                $Scripter.Script($view) ;
                $logitem =  "Dropping Dependent View: " + $datarow.Schema_Name + "." + $datarow.View_Name ;
                Write-Log $logitem  ;
                $view.Drop() ;
            }
        } ;

        Write-Log "End Process-DependentViews" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Dependent Views: " ; 
        Write-Log $err ; 
        Throw "Error scripting Dependent Views" ; 
    }
}

<#
    .SYNOPSIS 
    Scripts and drop dependent triggers

    .DESCRIPTION
    Scripts and drop all triggers dependent on columns that have the database collation (using sys.sql_constraints).
    Requires $db to be the database to change and $srv the server.

    .PARAMETER Sqlfile 
    Specifies the file for the scripted triggers.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Process-DependentTriggers 'C:\temp\DependentTriggers.sql'

    .EXAMPLE
    C:\PS> Process-DependentTriggers 'C:\temp\DependentTriggers.sql' 'Martin' 'SecretPassword'
#>
function Process-DependentTriggers ( [string] $Sqlfile ){

    try {
        $Scripter=New-Object ("Microsoft.SqlServer.Management.Smo.Scripter") ($srv)  ;
        $Scripter.Options.DriAll=$False ;
        $Scripter.Options.IncludeHeaders=$False ;
        $Scripter.Options.ToFileOnly=$True ;
        $Scripter.Options.WithDependencies=$False  ;
        $Scripter.Options.FileName=$Sqlfile ;
        $Scripter.Options.ScriptDrops=$False ; 
        $Scripter.Options.IncludeIfNotExists=$False ; 
        $Scripter.Options.AppendToFile=$True ;
        Write-Log "Scripting Dependent Triggers to File: $Sqlfile " ;

        $sqlstmt = "SELECT DISTINCT ps.name [Schema_Name], p.name [Table_name], o.name AS [Trigger_Name]
        FROM sys.sql_dependencies d
        JOIN sys.columns c ON d.referenced_major_id = c.object_id AND d.referenced_minor_id = c.column_id 
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.objects o ON d.object_id = o.object_id
        JOIN sys.objects p ON p.object_id = o.parent_object_id
        JOIN sys.schemas ps ON ps.schema_id = p.schema_id
        WHERE ( c.collation_name = CAST(DATABASEPROPERTYEX ( DB_NAME(), 'collation' ) AS varchar(128) ) COLLATE database_default
        OR c.is_computed = 1 )
        AND o.type = 'TR'
        ORDER BY ps.Name, p.Name " ;

        $dataset = $db.ExecuteWithResults($sqlstmt);
        if($ds.IsInitialized)
        {
            # this has the columns that you specified in your SQL Statement.
            foreach($datarow in $ds.Tables[0].Rows) { 
                [Microsoft.SqlServer.Management.Smo.Table] $tbl = $db.Tables.Item($datarow.Table_Name , $datarow.Schema_Name )  ;
                [Microsoft.SqlServer.Management.Smo.Trigger] $trigger = $tbl.Triggers.Item($datarow.Trigger_Name)  ;
                $Scripter.Script($trigger) ;
                $logitem =  "Dropping Dependent Trigger: " + $datarow.Schema_Name + "." + $datarow.Table_Name + " Trigger: " + $datarow.Trigger_Name ;
                Write-Log $logitem  ;
                $trigger.Drop() ;
            }
        } ;

        Write-Log "End Process-DependentTriggers" ; 
    } 
    catch { 
        $err = $Error[0].Exception ; 
        Write-Log "Error scripting Dependent Triggers: " ; 
        Write-Log $err ; 
        Throw "Error scripting Dependent Triggers" ; 
    }
}

##########################################################################################
# Main Progam
##########################################################################################

try {

	if ( $WorkingDirectory.EndsWith('\') -eq $false ) {
		$WorkingDirectory = $WorkingDirectory + '\' ;
	} ;
    $timestamp = (Get-Date -format "yyyyMMddHHmmss") ;
    $Logoutputfile = $WorkingDirectory  + "Collation_Change_" + $timestamp + ".log" ; 
    $FullTextIndexfile = $WorkingDirectory + "FullTextIndex_" + $timestamp + ".sql" ; 
    $ForeignKeyfile = $WorkingDirectory + "ForeignKey_" + $timestamp + ".sql" ; 
    $Indexfile = $WorkingDirectory + "Index_" + $timestamp + ".sql" ; 
    $CheckConstraintfile = $WorkingDirectory + "CheckConstraint_" + $timestamp + ".sql" ; 
    $Statisticsfile = $WorkingDirectory + "Statistics_" + $timestamp + ".sql" ; 
    $SchemaBoundFunctionsfile = $WorkingDirectory + "SchemaBoundFunctions_" + $timestamp + ".sql" ; 
    $SchemaBoundViewsfile = $WorkingDirectory + "SchemaBoundViews_" + $timestamp + ".sql" ; 
    $ComputedColumnfile = $WorkingDirectory + "ComputedColumns_" + $timestamp + ".sql" ; 

    $DependentTriggerfile = $WorkingDirectory + "DependentTriggers_" + $timestamp + ".sql" ; 
    $DependentViewfile = $WorkingDirectory + "DependentViews_" + $timestamp + ".sql" ; 
    $DependentProcedurefile = $WorkingDirectory + "DependentProcedures_" + $timestamp + ".sql" ; 
    $DependentFunctionfile = $WorkingDirectory + "DependentFunctions_" + $timestamp + ".sql" ; 
    $DependentCheckConstraintfile  = $WorkingDirectory + "DependentCheckConstraints_" + $timestamp + ".sql" ; 
    
    if ((Test-Path -Path $WorkingDirectory) -eq $false ) {
        Write-Host "Create directory $WorkingDirectory" ;
        $dir = New-Item -type directory $WorkingDirectory ;
    } ; 
} 
catch { 
    $err = $Error[0].Exception ; 
    Write-Host "Error caught: $err" ; 
    exit ; 
} ; 

try {
    Create-Log $Logoutputfile ;
    Write-Log "`r`n----`r`nWorkingDirectory  : $WorkingDirectory`r`nCollation         : $Collation`r`nServer            : $Server`r`nDatabase          : $Database`r`nUsername          : $Username`r`nPassword          : $Password`r`n----`r`n"  ;

    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection ; 

    Connect-Server $Server $Username $Password  ;
    $srv = New-Object Microsoft.SqlServer.Management.Smo.Server ( $conn ) ; 
    $db = New-Object Microsoft.SqlServer.Management.Smo.Database ;
    $db = $srv.Databases.Item($Database) ;
    if ( (Check-Collation $Collation) ) {
        Write-Host "Collation '$Collation' same as database" ;
        if ( $conn.InUse -eq $true ) {
            $conn.disconnect() ;
        }
        exit ;
    }
    Process-Fulltextindexes $FullTextIndexfile ;
    Process-Foreignkeys $Foreignkeyfile ;
    Process-Indexes $Indexfile ;

    Process-DependentCheckConstraints $DependentCheckConstraintfile ;
    Process-DependentFunctions $DependentFunctionfile ;
    Process-DependentProcedures $DependentProcedurefile ;
    Process-DependentViews $DependentViewfile ;
    Process-DependentTriggers $DependentTriggerfile ;

    Process-Checkconstraints $Checkconstraintfile ;
    Process-Statistics $Statisticsfile ;
    Process-Computedcolumns $Collation $Computedcolumnfile ;
    Process-Schemaboundfunctions $Schemaboundfunctionsfile ;
    Process-Schemaboundviews  $Schemaboundviewsfile ;
    Process-Columns $Collation ;
    Process-Database $Collation ;

    if ( $conn.InUse -eq $true ) {
        $conn.disconnect() ;
    }
    Process-SQLFile $SchemaBoundViewsfile $Server $Database $Username $Password ; 
    Process-SQLFile $SchemaBoundFunctionsfile $Server $Database $Username $Password ; 
    Process-SQLFile $ComputedColumnfile $Server $Database $Username $Password ; 
    Process-SQLFile $Statisticsfile $Server $Database $Username $Password ; 

    Process-SQLFile $DependentTriggerfile $Server $Database $Username $Password ;
    Process-SQLFile $DependentViewfile $Server $Database $Username $Password ;
    Process-SQLFile $DependentProcedurefile $Server $Database $Username $Password ;
    Process-SQLFile $DependentFunctionfile $Server $Database $Username $Password ;
    Process-SQLFile $DependentCheckConstraintfile $Server $Database $Username $Password ;

    Process-SQLFile $CheckConstraintfile $Server $Database $Username $Password ; 
    Process-SQLFile $Indexfile $Server $Database $Username $Password ; 
    Process-SQLFile $ForeignKeyfile $Server $Database $Username $Password ;
    Process-SQLFile $FullTextIndexfile $Server $Database $Username $Password ;

	$logitem = "***********************************************************************************`r`nCollation change for database $Database completed " + (get-date -format "dd/MM/yyyy HH:mm:ss") + "`r`n***********************************************************************************" ; 
    Write-Log $logitem ;

}
catch { 
    $err = $Error[0].Exception ; 
    Write-Log "Error caught: " ; 
    Write-Log $err ; 
    if ( $conn.InUse -eq $true ) {
        $conn.disconnect() ;
    }
} ; 
#http://sqlblogcasts.com/blogs/martinbell/Powershell/Change-Collation.ps1.txt