@echo Start %0 >> %0.log
date /t >> %0.log
time /t >> %0.log
net use \\chelappsbx001.karmalab.net\DeploymentAutomation_dogfood /u:sea\s-envManager 3nvManager!
robocopy \\chelappsbx001.karmalab.net\DeploymentAutomation_dogfood C:\cct_ops\DeploymentAutomation\ /E
net use \\chelappsbx001.karmalab.net\DeploymentAutomation_dogfood /d
@echo End %0 >> %0.log
