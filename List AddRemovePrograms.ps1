if(!(gwmi -list Win32_AddRemovePrograms)) {

set-content $pwd\RegProgs.mof @'
#pragma namespace("\\\\.\\root\\cimv2")
instance of __Win32Provider as $Instprov
{
Name ="RegProv" ;
ClsID = "{fe9af5c0-d3b6-11ce-a5b6-00aa00680c3f}" ;
};
instance of __InstanceProviderRegistration
{
Provider =$InstProv;
SupportsPut =TRUE;
SupportsGet =TRUE;
SupportsDelete =FALSE;
SupportsEnumeration = TRUE;
};

[dynamic, provider("RegProv"),
ProviderClsid("{fe9af5c0-d3b6-11ce-a5b6-00aa00680c3f}"),
ClassContext("local|HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")]
class Win32_AddRemovePrograms
{
[key]
string ProdID;
[PropertyContext("DisplayName")]
string DisplayName;
[PropertyContext("Publisher")]
string Publisher;
[PropertyContext("DisplayVersion")]
string Version;
[PropertyContext("UninstallString")]
string UninstallString;
[PropertyContext("EstimatedSize")]
string EstimatedSizeKb;
[PropertyContext("InstallDate")]
string InstallDate;
};
'@

#if((gwmi Win32_OperatingSystem -Property OSArchitecture).OSArchitecture -eq '64-bit') {
#if([intptr]::size -eq 8) {
if( test-path HKLM:\SOFTWARE\Wow6432Node ) {
add-content $pwd\RegProgs.mof @'
[dynamic, provider("RegProv"),
ProviderClsid("{fe9af5c0-d3b6-11ce-a5b6-00aa00680c3f}"),
ClassContext("local|HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")]
class Win32_AddRemovePrograms32
{
[key]
string ProdID;
[PropertyContext("DisplayName")]
string DisplayName;
[PropertyContext("Publisher")]
string Publisher;
[PropertyContext("DisplayVersion")]
string Version;
[PropertyContext("UninstallString")]
string UninstallString;
[PropertyContext("EstimatedSize")]
string EstimatedSizeKb;
[PropertyContext("InstallDate")]
string InstallDate;
};
'@
}

Write-Warning "MOF compiler will be RunAs Administrator ..."
if(
    (new-object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) 
) {
   mofcomp.exe $pwd\RegProgs.mof
} else {
   (start-process mofcomp.exe -verb runas -Args "$pwd\RegProgs.mof" -Passthru).WaitForExit() # -class:forceupdate 
}
}


## EXAMPLE:
## List installed 64 bit applications with ".NET" in the name (or 32bit on Windows 32bit)
Get-WmiObject Win32_AddRemovePrograms -filter "DisplayName like '%.NET%'" | Sort-Object DisplayName | Format-Table DisplayName, Version

if( test-path HKLM:\SOFTWARE\Wow6432Node ) {
## List installed 32 bit applications with ".NET" in the name (or nothing on Windows 32bit)
Get-WmiObject Win32_AddRemovePrograms32 -filter "DisplayName like '%.NET%'" | Sort-Object DisplayName | Format-Table DisplayName, Version

}


## NOTE: the alternative is a registry query which is much longer and more typing ... 
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* DisplayName,Publisher,DisplayVersion,UninstallString,EstimatedSize,InstallDate -ea 0 | 
   Where-Object { $_.DisplayName -like "*.Net*" } | Sort-Object DisplayName | Format-Table DisplayName, DisplayVersion, EstimatedSize -AutoSize

## And which performs miserably, by comparison:   
# Duration Command
# -------- -------
# 0.23302s Get-WmiObject Win32_AddRemovePrograms32 -filter ...
# 1.04610s Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* ...