#[TO DO] - allow user to pass in config file for the environment.

# "To be executed on Karmalab 2k8 server with SQL installed."
# SQL server used for testing: CHELSQLE2ECCT22
# pushd \\chelappsbx001\DeploymentAutomation_dogfood\Hub
"Script is disabled"

Break

Param(
 $EmainUtlServer="CHELUTLINT-01"				# $(throw 'A computer name is required')
,$HubDBHost="chelsqlcctst02"					# $(throw 'A HubStagingDBHost name is required')
,$HubDB="AgentAuthentication"				# $(throw 'A HubStagingDB name is required')
#HubHostDB and HubDB can be obtained from HUB web front end server by looking in the
#(chelwebpmp48-02) E:\Apps\deploymenthome\CentralAdmin\shared\classes\CentralAdmin\bootstrapconfig.properties
)

#Envvironments:
#Milan H* server	- $EmainUtlServer=	"CHELWEBE2ECCT34"
#Milan E* server	- $EmainUtlServer=	"CHELWEBE2ECCT25"
#Milan Hub DB Host	- $HubDBHost	=	"CHELSQLE2ECCT20"
#Milan Hub DB 		- $HubDB		=	"AgentAuthentication"
#---
#Maui (Int) H* server	- $EmainUtlServer=	"chelutl1hint01"
#Maui (Int)E* server	- $EmainUtlServer=	"CHELUTLINT-01"
#Maui Hub DB Host		- $HubDBHost	=	"NSSQLINT3DSECURE01.bgb.karmalab.net"
#Maui Hub DB 			- $HubDB		=	"AgentAuthentication_PMP48"
#--
#Eugencia Web server	- $EmainUtlServer=	"chelwbecte2e002"
#---
#Test web all - CHELUTLINT-01
#Test sql     - chelsqlcctst02
#Test HubDB   - AgentAuthentication


#Environment setup
# [ TO DO] - Test if SQL is installed
	# where.exe sqlcmd or something
# [ TO DO] - Test if BCP functionality of SQL is installed
	#if where.exe bcp = true, then ok.
	#$bcp_installer = where.exe bcp.exe
	$bcp_installer = "bcp.exe"
# [ TO DO] - Test Access to $EmainUtlServer
	#Test-Connection $EmainUtlServer
# [ TO DO] - Test Access to $HubDBHost
	#Test-Connection $HubDBHost
# [ TO DO] - Test if CCT_Ops exists
	#if (!(test-path c:\cct_ops)){md c:\cct_ops}
# [ TO DO] - Test if Staging DB can be reached
	#sqlcmd :Connect <DB connection string>
	#use Agent authentication or whatever DB specified in CSV file
	#GO
	#If errorlevel 0 Validate, otherwise terminate script
# [TO DO] - Allow execution against specific DB / TPID
	#param($optional: Specific DB/Connection string/TPID / etc..

try {Set-ExecutionPolicy bypass -force}
catch {"could not Set-ExecutionPolicy bypass, please execute"}

Import-Module ..\lib\Functions_common.psm1 -verbose -Force

# if(!(Test-Administrator)){
	# Write-host -f "Please run as Administrator";break
	##LogMessage "error" "Please run as Administrator."
	# }


#Environment Variables
$MTT_DB_mapping		= "c:\cct_ops\DB_mapping.txt"
$TPID_URL_mapping	= "c:\cct_ops\TPID_URL_mapping.txt"
#$MTT_DB_Mapping_csv= "c:\cct_ops\hub_alex.csv"
$working_dir		= "c:\cct_ops"

if (!(test-path $working_dir)){md $working_dir}
if (test-path $MTT_DB_mapping){del $MTT_DB_mapping}
if (test-path $TPID_URL_mapping){del $TPID_URL_mapping}
#if (test-path $MTT_DB_Mapping_csv){del $MTT_DB_Mapping_csv}



# Function to clean working file.
Function CleanWorkingFile {
	if(test-path $working_dir\$working_file){
		#"entering the loop" #debug code
		attrib -a -r -h -s $working_dir\$working_file
		del $working_dir\$working_file -force
		}
	}



# STEP - Create Staging DB Agent Authorization on HUB Staging server.
# script 3
$working_file = "3_AgentAuthentication_createHubStagingAndURLStagingTables.sql"

CleanWorkingFile 

(gc .\$working_file) -replace("##DBName##",$HubDB) | out-file $working_dir\$working_file
gc $working_dir\$working_file | select -first 5
#command execution - verified
sqlcmd -S $HubDBHost -i $working_dir\$working_file






# STEP - Acquire a list of DB strings and DB names from the UTL box
$a = reg query \\$EmainUtlServer\hklm\software\expedia\shared\database\expdsn /f MTT
#$b=$a -match('MTT.*')
$b=$a[1..($a.count -2)]

#creating header for .CSV file
"db_string`tdb_name" | out-file $MTT_DB_Mapping
#test code
gc $MTT_DB_Mapping

foreach ($i in $b){
	$c=reg query \\$EmainUtlServer\$i
	$db_string = $c[3].trim().replace("Server","").trim().replace("REG_SZ","").trim()
	$db_name = $c[5].trim().replace("Database","").trim().replace("REG_SZ","").trim()
	$db_string + "`t" + $db_name | out-file $MTT_DB_mapping -append
	# $db_string + "~" + $db_name | out-file $MTT_DB_Mapping_csv -append		#.csv for alex
	# creates a pretty hash tables... but not useful
	#$d+=@{$c[3].trim().replace("Server","").trim().replace("REG_SZ","").trim()=$c[5].trim().replace("Database","").trim().replace("REG_SZ","").trim()}
	}
#$d
gc $MTT_DB_Mapping





# Convert DB listing into usable .CSV format.
$db_csv = Import-Csv $MTT_DB_Mapping -Delimiter `t


# STEP - Display up to 12 supported TPIDs for each Database
foreach ($i in $db_csv){
	$working_file = "MTT_DB_TPID_Mapping_"+$i.db_name+".txt"
	CleanWorkingFile 

	$Query6 = "DECLARE @DB_NAME VARCHAR(128) SET @DB_NAME = (SELECT DB_NAME(dbid) FROM MASTER..SYSPROCESSES WHERE spid = @@SPID)
	DECLARE @TPID_TOTAL VARCHAR(128) SET @TPID_TOTAL = (select count(*) from travelproduct)
	print `'--- Displaying top 12 TPIDs for `'  + @DB_NAME  + `' Database ---`'
	print `'--- Total TPIDs in this DB: `' + @TPID_TOTAL
	select top (12) TravelProductID,TravelProductName from travelproduct order by travelproductid"
	sqlcmd -S $i.db_string -d $i.db_name -l 1 -Q $query6 -h -1 
	sqlcmd -S $i.db_string -d $i.db_name -l 1 -Q "select TravelProductID,TravelProductName from travelproduct order by travelproductid" -o $working_file
	"Full list of TPIDs can be found in the $working_file file"
	}
write-host "You can also execute "  -nonewline
write-host -f yellow "FINDSTR /i <TPID> $working_dir\*.* " -nonewline
write-host "to find DB containing a specific TPID" -nonewline






# STEP - Collect all Website entries and matching TPID from UTL box
$a = reg query \\$EmainUtlServer\hklm\software\expedia\webserver\pidsettings /t REG_SZ

foreach ($i in $a[2..($a.count -3)]){
	$i -match('[0-9]{1,}') |out-null
	$tpid = $matches[0]
	$URL_1  = $i.split(",")[2]
	$URL_2 = $i.split(",")[0].split("REG_SZ")[-1].trim()
	if ($URL_1 -eq ""){
		$URL_1 = $URL_2
		}
	$tpid + "`t" + "https://" + $url_1 | out-file $TPID_URL_mapping -append -encoding ascii
	#`t $url_2 
	} 
#test code
gc $TPID_URL_mapping







# Step 3,4,5
# Step  - Creates a super user for each TPID in each MTT database 
$working_file = "1_MTTWeb_CreateSuperUserAndAssociateWithTPIDs.sql"

	# [TO DO] - have a graceful way to handle SQL connection errors - Not all db strings actually exist.
foreach ($i in $db_csv){
	
	#Step  - Creates a super user for each TPID in each MTT database 
	# script 1
	CleanWorkingFile 
	(gc .\$working_file) -replace("##DBNAME##",$i.db_name) | out-file $working_dir\$working_file
	gc $working_dir\$working_file | select -first 5
	#command execution
	"db string = " + $i.db_string
	sqlcmd -S $i.db_string -i $working_dir\$working_file


	#Step - BCP out the TPID of the user we just created
	# Script 2
	[string]$bcp_out_command = gc .\2_MTTWeb_BCPOutTUIDTPIDList.bcp
	$bcp_out_command = $bcp_out_command.replace("bcp","").replace("##DBNAME##",$i.db_name).replace("##WORKING_DIR##",$working_dir).replace("##SQLINSTANCE##",$i.db_string)
	$bcp_out_command
	#command execution
	#invoke-command $bcp_out_command
	Start-Process $bcp_installer $bcp_out_command -nonewwindow -wait


	#Step - BCP files into Agent Auth Staging Table
	# Script 4
	[string]$bcp_in_command = gc .\4_AgentAuthentication_BCPInToHubStaging.bcp
	$bcp_in_command = $bcp_in_command.replace("bcp","").replace("##HUBDB##",$HubDB).replace("##WORKING_DIR##",$working_dir).replace("##DBNAME##",$i.db_name).replace("##SQLINSTANCE##",$HubDBHost)
	$bcp_in_command
	#command execution
	Start-Process $bcp_installer $bcp_in_command -nonewwindow -wait
	}






#Step - BCP in URL - add URL to URL staging table
# Script 5
[string]$bcp_in_command = gc .\5_AgentAuthentication_BCPInToURLStaging.bcp
$bcp_in_command = $bcp_in_command.replace("bcp","").replace("##FILENAME##",$TPID_URL_mapping).replace("##SQLINSTANCE##",$HubDBHost).replace("##HubStagingDB##",$HubDB)
$bcp_in_command
#command execution
Start-Process $bcp_installer $bcp_in_command -nonewwindow -wait







# Step - Issue the SQL command to combine URL with Hub Staging Table based on TPID
# Script 6
$working_file = "6_AgentAuthentication_SetHubStagingURL.sql"

CleanWorkingFile 

(gc .\$working_file) -replace("##DBNAME##",$HubDB) | out-file $working_dir\$working_file
gc $working_dir\$working_file | select -first 5
#command execution
sqlcmd -S $HubDBHost -i $working_dir\$working_file






#Step - Add TPID to travel product from HUB staging.
# Script 7
# Already configured to use the Staging Table.
$working_file = "7_AgentAuthentication_ADDTPIDToTravelProduct_fromHubStaging.sql"

CleanWorkingFile 

(gc .\$working_file) -replace("##DBNAME##",$HubDB) | out-file $working_dir\$working_file
gc $working_dir\$working_file | select -first 5
#command execution
sqlcmd -S $HubDBHost -i $working_dir\$working_file







#Step - SQL script that archives the DB and then drops them.

$working_file = "8_AgentAuthentication_ArchiveHubStagingAndURLStaging.sql"

CleanWorkingFile 

(gc .\$working_file) -replace("##DBNAME##",$HubDB) | out-file $working_dir\$working_file
gc $working_dir\$working_file | select -first 5
#command execution

Write-host -f Yellow "To clean up the Staging tables, please execute the following command manually (for now)"
Write-host "sqlcmd -S $HubDBHost -i $working_dir\$working_file"


