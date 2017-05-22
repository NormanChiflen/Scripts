#http://www.techlearningblog.com/post/PowerShell-How-to-retrieve-disk-size-free-disk-space-from-multiple-systems.aspx
Get-WMIObject Win32_LogicalDisk -filter "DriveType=3" -computer localhost |
Select SystemName,DeviceID,VolumeName,@{Name="Size(GB)";Expression={'{0:N1}' -f($_.size/1gb)}},@{Name="Free Space(GB)";Expression={'{0:N1}' -f($_.freespace/1gb)}},@{Name="Free Space(%)";Expression={'{0:P2}' -f(($_.freespace/1gb) / ($_.size/1gb))}} |
Out-GridView -Title "Drive Space"