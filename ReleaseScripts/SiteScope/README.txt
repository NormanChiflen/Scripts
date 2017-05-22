
** 
The DLL_Update.cmd script's purpose is to update the Sitescope monitors after a release when the DLL 
designator is increased. 

Created by:   Jeff Van Cleave
Last updated: 6/16/2004
**

Example: thrd153.dll was updated to thrd160.dll for release R16.

Usage: DLL_Update


Files:

DLL_Update.cmd
This is the main script. It does the following:
Step 1: Stops Sitescope on all servers that are supported by Site Operations
Step 2: Creates a file in the form of server_mglist for every Sitscope server. This file is a list
        of all of the mg files on every Sitescope server.
Step 3: Runs munge against the mg files, using the file: scriptfile
Step 4: Starts Sitescope on the monitors


scriptfile
This is the file containing the old pattern and the new pattern. This file will need to be updated
for each release as the DLL is updated.
Example: "153.dll" "160.dll"
  This will change all occurrences of 153 to 160 in the mg files.
Note: This is case sensitive unless otherwise specified. To catch cases of upper and lower, use
two lines.
Example:
"153.dll" "163.dll"
"153.DLL" "163.DLL"


sitescope_serverlist
This is a list of all the Sitescope servers that are supported by Site operations. Update this file
if there are new Sitescope systems.

servername_mglist
These are created by the DLL_Update.cmd script. There should be one created for every server. It 
contains a list of all of the mg files on that system. 