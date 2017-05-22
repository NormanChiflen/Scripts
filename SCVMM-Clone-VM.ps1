# ------------------------------------------------------------------------------
# New Virtual Machine Script
# Norman Fletcher
# ------------------------------------------------------------------------------
# 
# For additional help on cmdlet usage, type get-help <cmdlet name>
# ------------------------------------------------------------------------------


Set-VirtualFloppyDrive -RunAsynchronously -VMMServer localhost -NoMedia -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a 


Set-VirtualCOMPort -NoAttach -VMMServer localhost -GuestPort 1 -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a 


Set-VirtualCOMPort -NoAttach -VMMServer localhost -GuestPort 2 -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a 


New-VirtualNetworkAdapter -VMMServer localhost -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a -PhysicalAddressType Dynamic -VirtualNetwork "Primary App - Virtual Network" -NetworkLocation "New Network Location (10.184.52.1)" -VLanEnabled $false -VMNetworkOptimizationEnabled $false -MACAddressesSpoofingEnabled $false 


New-VirtualDVDDrive -VMMServer localhost -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a -Bus 1 -LUN 0 

$CPUType = Get-CPUType -VMMServer localhost | where {$_.Name -eq "1.00 GHz Pentium III Xeon"}


New-HardwareProfile -VMMServer localhost -Owner "SEA\nfletcher" -CPUType $CPUType -Name "Profile631812e3-e37c-45cb-9cfd-cec09765b2c9" -Description "Profile used to create a VM/Template" -CPUCount 4 -MemoryMB 16384 -ExpectedCPUUtilization 20 -DiskIO 0 -CPUMax 100 -CPUReserve 0 -NetworkUtilization 0 -RelativeWeight 100 -HighlyAvailable $false -NumLock $false -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -LimitCPUFunctionality $false -LimitCPUForMigration $true -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a 


$VirtualNetworkAdapter = Get-VirtualNetworkAdapter -VMMServer localhost -All | where {$_.ID -eq "c90727ca-d1e8-48ef-9a0d-fc0b732ca753"}

Set-VirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -VirtualNetwork "Primary App - Virtual Network" -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a 

$VM = Get-VM -VMMServer localhost -Name "CHELT2TST03" | where {$_.VMHost.Name -eq "chelt2hst05.karmalab.net"}
$VMHost = Get-VMHost -VMMServer localhost | where {$_.Name -eq "chelt2hst05.karmalab.net"}
$HardwareProfile = Get-HardwareProfile -VMMServer localhost | where {$_.Name -eq "Profile631812e3-e37c-45cb-9cfd-cec09765b2c9"}
$OperatingSystem = Get-OperatingSystem -VMMServer localhost | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Enterprise"}

New-VM -VM $VM -Name "CHELT2TST04" -Description "" -Owner "SEA\nfletcher" -VMHost $VMHost -Path "e:\VMM_Guests" -JobGroup 8e3b50bc-4b0f-4580-b4d1-3b056597979a -RunAsynchronously -HardwareProfile $HardwareProfile -OperatingSystem $OperatingSystem -RunAsSystem -StartAction TurnOnVMIfRunningWhenVSStopped -DelayStart 0 -UseHardwareAssistedVirtualization $true -StopAction SaveVM -StartVM 

