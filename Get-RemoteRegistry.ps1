#.SYNOPSIS
#  Query the registry on a remote machine
#.NOTE
#  You have to have access, and the remote registry service has to be running
#
# Version History:
#   3.0
#       + updated to PowerShell 2 
#       + support pipeline parameter for path
#   2.1
#       + Fixed a pasting bug 
#       + I added the "Properties" parameter so you can select specific redgistry values
# ######################################################################################
#.EXAMPLE
#      (Get-RemoteRegistry ${Env:ComputerName} HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\).Subkeys | 
#         Get-RemoteRegistry ${Env:ComputerName} `
#         -Path { "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$_" } `
#         -Properties DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString
#.EXAMPLE
#   Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP"
#     * Returns a list of subkeys (because this key has no properties)
#.EXAMPLE
#   Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
#     * Returns a list of subkeys and all the other "properties" of the key
#.EXAMPLE
#   Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727\Version"
#     * Returns JUST the full version of the .Net SP2 as a STRING (to preserve prior behavior)
#.EXAMPLE
#   Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" Version
#     * Returns a custom object with the property "Version" = "2.0.50727.3053" (your version)
#.EXAMPLE
#   Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" Version,SP
#     * Returns a custom object with "Version" and "SP" (Service Pack) properties
#
#  For fun, get all .Net Framework versions (2.0 and greater) 
#  and return version + service pack with this one command line:
#
#    Get-RemoteRegistry $RemotePC "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" | 
#    Select -Expand Subkeys | ForEach-Object { 
#      Get-RemoteRegistry $RemotePC "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\$_" Version,SP 
#    }
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$computer = $(Read-Host "Remote Computer Name")
,
    [Parameter(Position=1, ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true, Mandatory=$true)]
    [string]$Path     = $(Read-Host "Remote Registry Path (must start with HKLM,HKCU,etc)")
,
    [Parameter(Position=2)]
    [string[]]$Properties
)
process {
   $root, $last = $Path.Split("\")
   $last = $last[-1]
   $Path = $Path.Substring($root.Length + 1,$Path.Length - ( $last.Length + $root.Length + 2))
   $root = $root.TrimEnd(":")

   #split the path to get a list of subkeys that we will need to access
   # ClassesRoot, CurrentUser, LocalMachine, Users, PerformanceData, CurrentConfig, DynData
   switch($root) {
      "HKCR"  { $root = "ClassesRoot"}
      "HKCU"  { $root = "CurrentUser" }
      "HKLM"  { $root = "LocalMachine" }
      "HKU"   { $root = "Users" }
      "HKPD"  { $root = "PerformanceData"}
      "HKCC"  { $root = "CurrentConfig"}
      "HKDD"  { $root = "DynData"}
      default { return "Path argument is not valid" }
   }


   #Access Remote Registry Key using the static OpenRemoteBaseKey method.
   Write-Verbose "Accessing $root from $computer"
   $rootkey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($root,$computer)
   if(-not $rootkey) { Write-Error "Can't open the remote $root registry hive" }

   Write-Verbose "Opening $Path"
   $key = $rootkey.OpenSubKey( $Path )
   if(-not $key) { Write-Error "Can't open $($root + '\' + $Path) on $computer" }

   $subkey = $key.OpenSubKey( $last )
   
   $output = new-object object

   if($subkey -and $Properties -and $Properties.Count) {
      foreach($property in $Properties) {
         Add-Member -InputObject $output -Type NoteProperty -Name $property -Value $subkey.GetValue($property)
      }
      Write-Output $output
   } elseif($subkey) {
      Add-Member -InputObject $output -Type NoteProperty -Name "Subkeys" -Value @($subkey.GetSubKeyNames())
      foreach($property in $subkey.GetValueNames()) {
         Add-Member -InputObject $output -Type NoteProperty -Name $property -Value $subkey.GetValue($property)
      }
      Write-Output $output
   }
   else
   {
      $key.GetValue($last)
   }
}