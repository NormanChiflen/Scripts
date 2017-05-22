#Get 'n' number of files
$FileLimit = 10
  
#Destination for files
$DropDirectory = "D:\OptiLink_Interface\TA\"
  
$PickupDirectory = Get-ChildItem -Path "D:\OptiLink_Interface\TA\Hold"
  
$Counter = 0
foreach ($file in $PickupDirectory)
{
    if ($Counter -ne $FileLimit)
    {
        $Destination = $DropDirectory+$file.Name
  
        #Write-Host $file.FullName #Output file fullname to screen
        #Write-Host $Destination   #Output Full Destination path to screen
          
        Move-Item $file.FullName -destination $Destination
        $Counter++
    } 
}
#http://www.techlearningblog.com/post/move-n-number-of-files-from-one-folder-to-another.aspx