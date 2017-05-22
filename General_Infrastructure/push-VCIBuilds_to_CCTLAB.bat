@echo Start %0 >> %0.log
date /t >> %0.log
time /t >> %0.log
net use \\chclappadfs02.cctlab.expecn.com\binroot /u:chclappadfs02\taskuser Password1!
robocopy \\karmalab.net\builds\continuousintegration\sait\VCI \\chclappadfs02.cctlab.expecn.com\binroot\continuousintegration\sait\VCI /MIR
robocopy \\karmalab.net\builds\directedbuilds\sait\VCI \\chclappadfs02.cctlab.expecn.com\binroot\directedbuilds\sait\VCI /MIR
if exist \\karmalab.net\builds\ReleaseCandidate\sait\VCI robocopy \\karmalab.net\builds\ReleaseCandidate\sait\VCI \\chclappadfs02.cctlab.expecn.com\binroot\ReleaseCandidate\sait\VCI /MIR
if exist \\karmalab.net\builds\Release\sait\VCI robocopy \\karmalab.net\builds\Release\sait\VCI \\chclappadfs02.cctlab.expecn.com\binroot\Release\sait\VCI /MIR
net use \\chclappadfs02.cctlab.expecn.com\binroot /d
@echo End %0 >> %0.log
