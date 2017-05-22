#-------------------------------------------------------------------------
#                                   Notes
# This PowerShell Script is used for purging log files and log folders of a system.
# In order to use this file the checkdirs.csv must exist and be filled in
# with the folders you would like to check. In addition each folder can have
# it's own specific days set. If you first run this script without the
# checkdirs.csv file existing one will be created for you.
#
#-------------------------------------------------------------------------
$StrDateTime = get-date -uformat "%m%d%Y-%I%M%S%p" #08112010-83805PM = 08/11/2010 8:38:05 PM
$CurrentPath = Get-Location
echo $CurrentPath 
$LogFile = "$CurrentPath\Logs\$StrDateTime-PurgeLog.txt"
$LogPath = "$CurrentPath\Logs"
echo $LogPath
$LogPurgeDays = 30
 
function PurgeFolders
{
    foreach($directory in $directories)
    {
        $strDir = $directory.Path
        $strDays = $directory.Days
        $strCompareDate = (Get-date).AddDays(-$strDays)
        $ArrayOfFilesForSize = Get-ChildItem $strDir -Recurse | Where-Object{$_.LastWriteTime -lt $strCompareDate} | Select Name,Length
        $ArrayOfFiles = Get-ChildItem $strDir | Where-Object{$_.LastWriteTime -lt $strCompareDate} | Select Name,Length
        $strCountOfFiles = $ArrayOfFiles.count
        $strSizeCount = 0
        foreach($size in $ArrayOfFilesForSize)
        {
            $strSizeCount = $strSizeCount + $size.Length
        }
        $strSizeOfPurge = "{0:N2}" -f ($strSizeCount / 1MB)
        Write-Host "--------------------------------------------------------`r" -foreground yellow
        Write-Host "Purging $strCountOfFiles files from $strDir that are older than $strDays days.`r" -foreground green
        Write-Host "This will recover $strSizeOfPurge MB of space.`r" -foreground green
        foreach($item in $ArrayOfFiles)
        {
            $strItemName = $item.Name
            if($strItemName)
            {
                Write-Host "$strItemName...Deleted`r" -foreground green
                Remove-Item $strDir\$strItemName -Recurse
            }
            else
            {
                Write-Host "Nothing to do`r" -foreground green
            }
        }
    }
    if ($LogPurgeDays -gt 0)
    {
        Write-Host "--------------------------------------------------------`r" -foreground yellow
        Write-Host "Purging Log Files from $CurrentPath$LogPath older than $LogPurgeDays days.`r" -foreground green
        $strCompareDate = (Get-date).AddDays(-$LogPurgeDays)
        $ArrayOfLogFiles = Get-ChildItem $CurrentPath$LogPath | Where-Object{$_.LastWriteTime -lt $strCompareDate} | Select Name,Length
        foreach($file in $ArrayOfLogFiles)
            {
                $strFileName = $file.Name
                if($strFileName)
                {
                    Write-Host "$strFileName...Deleted`r" -foreground green
                    Remove-Item $CurrentPath$LogPath\$strFileName
                }
                else
                {
                    Write-Host "No old Log Files to Delete.`r" -foreground green
                }
            }
    }
    else
    {
        Write-Host "--------------------------------------------------------`r" -foreground yellow
        Write-Host "Auto Purging of Log Files is Disabled.`r" -foreground green
    }
}
 
function CreateCheckDirsCSV
{
    Write-Host "--------------------------------------------------------`r" -foreground yellow
    Write-Host "The checkdirs.csv file did not exist. This was created for you.`r" -foreground yellow
    Write-Host "You must now populate this file with the proper information,`r" -foreground yellow
    Write-Host "See files for more details.`r" -foreground yellow
    New-Item checkdirs.csv -type file
    Add-Content checkdirs.csv "Path,Days"
}
 
Clear-Host
 
if ($LogPurgeDays -gt 0)
{
    if (!(Test-Path -path $CurrentPath$LogPath))
    {
        New-Item -path $CurrentPath -name $LogPath -type directory
        Start-Transcript -Path $LogFile
        Write-Host "--------------------------------------------------------`r" -foreground yellow
        Write-Host "Log folder path did not exist. This was created for you.`r" -foreground green
    }
    else
    {
        Start-Transcript -Path $LogFile
    }
}
 
if (Test-Path checkdirs.csv)
{
    $directories = Import-CSV checkdirs.csv | Select Path,Days
    PurgeFolders
}
else
{
    CreateCheckDirsCSV
}
 
if ($LogPurgeDays -gt 0)
{
    Stop-Transcript
}