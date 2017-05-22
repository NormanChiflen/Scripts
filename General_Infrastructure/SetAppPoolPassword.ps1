param([string]$uid="",[string]$pwd="")
write-host " "
write-host "The script will find all AppPools where the username matches the partial username given (do not have to enter domain name), and set it's password to the value specified."
write-host "Usage: .\SetAppPoolPassword.ps1 '_synapps' 'Password123'"
write-host " "
if ($uid -eq "" -OR $pwd -eq ""){write-error "Must specify UserName and Password";break;}
ImportSystemModules
gci IIS:\AppPools | %{if ($_.processModel.username.contains("$uid")){$_.processModel.password="$pwd";$_ | set-item;$_.Recycle()}}