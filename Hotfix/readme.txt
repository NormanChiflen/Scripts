INFORMATION:

This readme is for operation of the hotfix scripts in this Directory.  They are 
designed currently to pull R15 hotfix code from a single unified source directory:
\\DNCRS01\R15hotfix\R15source\


EXECUTING HOTFIX SCRIPT:

To run this you'll need three parameters:
1.  Hotfix Date
2.  Your expeso Username
3.  Your Password

for example to run a web hotfix you'd run the following command:
c:\bin\hotfix\webs.cmd 12-16 aprice password

After executing a list of file copy log outputs will be placed here to be verified:
\\dnfil01\ops\hotfixed\<date you used for parameter 1>\<computername>.txt

Additionally a post hotfix DIR output will be placed in the following location if Dev 
or test require for verification.  You may also use windiff on these files to verify 
that all servers contain the same files:
\\dnfil01\ops\hotfixout\<date>-POST-<computername>-timestamp.txt


MORE INFORMATION:

These scripts, with the excpetion of the GATs, are designed to be run remotely from 
a scheduled task in batches.  Sometime soon I hope to create wrapper scripts that will 
automatically schedule and execute the scripts for you but for now you'll need to use 
your own command line scripting to schedule on servers.  Once you've scheduled the task
you'll only need to wait for the \\dnfil01\ops\hotfixed\ output to verify all files have
successfully been copied.  You'll also want to verify in Sitescope that all services 
have started successfully and there are no errors before adding back into rotation.  

Ideally you should have a Tester verify functionality for you as well.  

