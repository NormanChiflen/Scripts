 #Backup Site Collection in Windows SharePoint Services Site Collection to file

   #Author: Norman Fletcher

   #Weblog:   syntax for using this script:
 

# c:\backup.ps1 -SiteCollectionUrl "http://web:2020" -Path c:\backups

# You must give an existing folder for the path parameter!
# If you use it from the task scheduler, use this syntax (change the path and the site collection url):

# powershell.exe c:\script\backup.ps1 -SiteCollectionUrl "http://web:2020" -Path 

    

param(  

[string]$SiteCollectionUrl = $(throw "Please enter the URL of the Site Collection you want to backup"),  

[string]$Path =$(throw "Please enter the folder you want to backup to")  

)  

if(test-path $path)  

{  

  $guid = "\" + [Guid]::NewGuid().ToString()  

  & "$env:programfiles\Common Files\Microsoft Shared\web server extensions\12\BIN\stsadm.exe" `  

  -o backup -url $SiteCollectionUrl -filename $Path$guid.backup -overwrite > $null  

  [DateTime]::Now.ToString() +  ": Backup Done! File name is $path$guid.backup" >> "$path\log.txt"  

}  

else  

{  

  write-error "The Path doesn't exists"  

}  
 