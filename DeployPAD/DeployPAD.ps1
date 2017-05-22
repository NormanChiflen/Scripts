# USEAGE:  deploypad.ps1 Enviroment (DR/PROD) Version without the "v", expeso\_travfusesvc password 
# EXAMPLE: deploypad.ps1 PPE 1.10.1 P@ssword
CLS
#######ARGS VARS######
# $file is Serverlist
$env = $args[0]
# $version is the version that is being deployed
$version = $args[1]
# $realpass is the password for Travfusesvc Service Account
$realpass = $args[2]
######################
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

#SourceU is the Commandline used to Uninstall PAD
$SourceU = "c:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe /u /LogFile=e:\TravelFusionWebSvcIISPublish\PADuninstall.log E:\TravelFusionWebSvcIISPublish\bin\TravelFusionWebSvcIIS.dll"

# $Servers applies server list in to the path
$servers = (Get-Content -Path \\che-filidx\OPS\T2OPS\Automation\PADDeployment\$env.txt)

#Next Section Is to Uninstall Padd
Foreach ($server in $servers) 
{
$Command1 = $SourceU
$SourceR = "\\$servers\c$\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe /u /LogFile=e:\TravelFusionWebSvcIISPublish\PADuninstall.log E:\TravelFusionWebSvcIISPublish\bin\TravelFusionWebSvcIIS.dll"
#Start Remote PAD Uninstall uninstall
Write-Host "Starting AirPAD Uninstall on $server" -foregroundcolor "Green"
#The First Invoke-Command below turns UAC OFF on the remote computer
Invoke-Command -Computername $server {Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0}
#The below Invoke-Command Runs the PAD Uninstall Command
Invoke-Command -Computername $server {param($Command1) cmd /c "$Command1"} -ArgumentList (,$Command1)
}
###### Deletes, renames and RoboCopy
# This part deletes any child folders named TravelFusionWebSvcIISPublish*** keeping any other folders in tact 
Foreach ($server in $servers)
{
if(Test-Path -Path \\$server\e`$\TravelFusionWebSvcIISPublish*){
    cd \\$server\e`$
    foreach ($dir in ls){
        if (!($dir.Name -eq "TravelFusionWebSvcIISPublish") -and $dir.Name.StartsWith("TravelFusionWebSvcIISPublish")){
            Remove-Item $dir -recurse
        }
    }
}
#This part then renames TravelFusionWebSvcIISPublish to "old"
Rename-Item -path \\$server\e`$\TravelFusionWebSvcIISPublish -NewName TravelFusionWebSvcIISPublishold

#Check for bits if not present copy over the TravelFusionWebSvcIISPublishold folder
if (!(Test-Path -path \\$server\e`$\TravelFusionWebSvcIISPublish))
{
Write-Host "Bits do not exist copying now" -foregroundcolor "Red"
Robocopy \\che-filidx\release\depot\agtexpe\products\ProviderAdapter\v$version\deliverables\depot.agtexpe.products.provideradapter\v$version\Release\TravelFusionWebSvcIISPublish \\$server\e$\TravelFusionWebSvcIISPublish /e
}
}
##### Install PAD

$realoptions = " /LogFile=e:\TravelFusionWebSvcIISPublish\installPAD.log E:\TravelFusionWebSvcIISPublish\bin\TravelFusionWebSvcIIS.dll"
$Source = "C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe /install /optionsfile=E:\TravelFusionWebSvcIISPublish\bin\SetupOptions\prod.txt /IIS7.ApplicationPool.ProcessModel.Password="

Foreach ($server in $servers) 
{
$pass = $realpass
$options = $realoptions
$Command = $Source + $pass + $options
$SourceR = "\\$servers\c$\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe /install /LogFile=e:\TravelFusionWebSvcIISPublish\installPAD.log E:\TravelFusionWebSvcIISPublish\bin\TravelFusionWebSvcIIS.dll"
#Start Remote install
Write-Host "Starting AirPAD Install on $server" -foregroundcolor "Green"
#The First Invoke-Command below turns UAC OFF on the remote computer
#Invoke-Command -Computername $server {Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0}
#The below Invoke-Command Runs the PAD Uninstall Command
Invoke-Command -Computername $server {param($Command) cmd /c "$Command"} -ArgumentList (,$Command)
}
####### Pad Functional Test
#Start Remote PAD Uninstall uninstall
Write-Host "Starting AirPAD Functional Test on $server" -foregroundcolor "Green"
Foreach ($server in $servers) 
{
\\che-filidx\OPS\T2OPS\Automation\PADDeployment\PADTests\Autorunner\AutoRunner.exe -s $server -t GenericPAD.dll -r \\che-filidx\OPS\T2OPS\Automation\PADDeployment\PADTests\Logs\
}

##### Create LogFile 
#Output the time it took to run
write-host "Script Started at $script:startTime"
write-host "Script Ended at $(get-date)"
write-host "Total Elapsed Time: $(GetElapsedTime)"
#Update LogFile with Times
Write-Output "$(get-date) Script Started at $script:startTime" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\PADDeployment\Logs\$env.txt -Append
Write-Output "$(get-date) Script Ended at $(get-date)" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\PADDeployment\Logs\$env.txt -Append
Write-Output "$(get-date) Total Elapsed Time: $(GetElapsedTime)" | Out-File -FilePath \\che-filidx\ops\t2ops\Automation\PADDeployment\Logs\$env.txt -Append
