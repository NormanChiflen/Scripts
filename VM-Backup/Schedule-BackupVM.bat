This is a simple cmd/batch file that calls Powershell with the VMStartStop.ps1 script file and passes the hosts.txt (list of virtual machines) and a single parameter that instructs the script to shutdown the virtual machine or start it up.

REM Hyper-V Virtual Machine Backup

REM Shutdown virtual machines
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe c:\Powershell\VMStartStop.ps1 c:\Powershell\Hosts.txt 1

REM Copy virtual machines, /Y overwrites the file if it already exists

copy /Y "D:\Virtual Hard Disks\V1\Virtual Srv1.vhd" "\\computername\k$\Virtual Servers\V1\Virtual Srv1.vhd"
copy /Y "D:\Virtual Hard Disks\V2\Virtual Srv2.vhd" "\\computername\k$\Virtual Servers\V2\Virtual Srv2.vhd"
copy /Y "D:\Virtual Hard Disks\V3\VirtXP 1.vhd" "\\computername\k$\Virtual Servers\V3\VirtXP 1.vhd"

REM Start Up virtual machines

%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe c:\Powershell\VMStartStop.ps1 c:\Powershell\Hosts.txt 0

REM Finished!