# USEAGE: PS > DeployHAT.ps1 DRorPROD AorBConfig YourExpeso\UserName YourExpeso\Password
# EXAMPLE: DeployHAT.ps1 PROD A Expeso\Lahlbeck P@ssword
CLS
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')  
#######ARGS VARS######
# $env is Serverlist
$env = $args[0]
# $AorB is the A or B Config of hat to deploy to
$AorB = $args[1]

# Get service account login, either from arguments or ask user for it.
IF ($args[2])
{$SvcLogin = $args[2]}
ELSEIF ($SvcLogin)
{}
ELSE
{$SvcLogin = [Microsoft.VisualBasic.Interaction]::InputBox("EXPESO service account login.", "$SvcLogin", "EXPESO\")}

# Get service account password, either from arguments or ask user for it.
IF ($args[3])
{$SvcPword = $args[3]}
ELSEIF ($SvcPword)
{}
ELSE
{$SvcPword = [Microsoft.VisualBasic.Interaction]::InputBox("EXPESO Service account password.", "$SvcPword", "NoPeeking")}

# $Servers applies server list in to the path
$servers = (Get-Content -Path \\che-filidx\OPS\T2OPS\Automation\HATDeployment\$env.txt)


#Time the release
function GetElapsedTime() {
    $runtime = $(get-date) - $script:StartTime
    $retStr = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds", `
        $runtime.Days, `
        $runtime.Hours, `
        $runtime.Minutes, `
        $runtime.Seconds, `
        $runtime.Milliseconds)
    $retStr
    }
	
$script:startTime = get-date

#The First Invoke-Command below adds the regestry key to ".exe" to the LowRiskFileTypes on the remote computers. 
#This prevents the security warning from appearing from \References\Cryptographyregistration_32bit\CryptographyRegistration.exe
Foreach ($server in $servers) 
{
Invoke-Command -Computername $server {NEW-ITEM -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations}
Invoke-Command -Computername $server {NEW-ITEMProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations -Name LowRiskFileTypes -Value .exe -force}
}

#### RoboCopies over the Deploy & Deployment Folder to the server
Foreach ($server in $servers)
{
Write-Host "Copying Deploy Folder now" -foregroundcolor "Cyan"
Robocopy \\che-filidx\deployment\com\expeso\ph\ppe\depot\agtexpe\products\HAT\Deploy\ \\$server\D$\Deploy\ *.* /e

Write-Host "Copying Deployment Folder now" -foregroundcolor "Cyan"
Robocopy \\che-filidx\deployment\com\expeso\ph\ppe\depot\agtexpe\products\HAT\Deployment\ \\$server\d$\Deployment\ *.* /e
}

# Deploy each AirHAT service via local deploy script on the server.
FOREACH ($Server in $Servers) 
{
	Write-host -foregroundcolor Cyan "Deploying $Server $ServerEnv$SvcName"
	psexec \\$Server -u $SvcLogin -p $SvcPword /accepteula cmd /c "echo . | powershell -noninteractive -command D:\Deploy\$AorB`_$Server.ps1"
}

#This following command removes the registry key that we created above.
Foreach ($server in $servers) 
{
Invoke-Command -Computername $server {REMOVE-ITEM -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations\ -recurse}
}

############################################### Testing HAT AREA ##################################################################
####This test will run a functional test against Prod or DR HAT A or B based off what was used in $args[0] & $args[1]
####It will display the output and pipe it to \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\$Server-$AorB-Test.txt
####Only the following criteria will be recognized: PRODA PRODB DRA DRB  

##### TESTING PROD-A CONFIG #####
If (($args[0] + $args[1]) -eq "PRODA")
{
Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT101 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.159/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT101-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT102 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.160/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT102-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT103 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.161/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT103-A-Test.txt

Write-host -foregroundcolor Magenta "Testing CHEXAIRHAT104 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.193/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT104-A-Test.txt
}

##### TESTING PROD-B CONFIG #####
elseif (($args[0] + $args[1]) -eq "PRODB")
{
Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT101 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.175/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT101-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT102 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.181/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT102-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT103 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.187/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT103-B-Test.txt

Write-host -foregroundcolor Yellow "Testing CHEXAIRHAT104 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.186.12.199/HatService.svc t2appeng@expedia.com UXWdCie93ZS2Jof4Qb9x9DCNtGdFYBgh9QSbkRGJMDuloL2rxNOPgema+S7rjLi3 | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\CHEXAIRHAT104-B-Test.txt
}

##### TESTING DR-A CONFIG #####
elseif (($args[0] + $args[1]) -eq "DRA")
{
Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT101 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.58/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT101-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT102 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.64/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT102-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT103 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.70/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT103-A-Test.txt

Write-host -foregroundcolor Magenta "Testing PHEDAIRHAT104 ~A~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.113/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT104-A-Test.txt
}

##### TESTING DR-B CONFIG #####
elseif (($args[0] + $args[1]) -eq "DRB")
{
Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT101 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.94/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT101-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT102 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.100/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT102-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT103 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.106/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT103-B-Test.txt

Write-host -foregroundcolor Yellow "Testing PHEDAIRHAT104 ~B~ Config"
\\che-filidx\OPS\T2OPS\Automation\HATDeployment\Test\hst.exe https://10.202.147.119/HatService.svc t2appeng@expedia.com 6ga9T1ffaOuY49fdygx9FDkUsz6Wuxe510rjiNI3UHeOvhamJRMGMqv0gaCz/c4k | Tee-Object -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\PHEDAIRHAT104-B-Test.txt
}
############################################### END Testing AREA ##################################################################

##### Create LogFile 
#Output the time it took to run
write-host "Script Started at $script:startTime"
write-host "Script Ended at $(get-date)"
write-host "Total Elapsed Time: $(GetElapsedTime)"
#Update LogFile with Times
Write-Output "$(get-date) Script Started at $script:startTime" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\$env$AorB.txt -Append
Write-Output "$(get-date) Script Ended at $(get-date)" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\$env$AorB.txt -Append
Write-Output "$(get-date) Total Elapsed Time: $(GetElapsedTime)" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\HATDeployment\Logs\$env$AorB.txt -Append
