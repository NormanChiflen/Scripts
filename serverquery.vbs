On Error Resume Next

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

arrComputers = Array("CHE-TVMAMR01","CHE-TVMAMR02","CHE-TVMAMR03","CHE-TVMAMR04","CHE-TVMAMR05","CHE-TVMAMR06","CHE-TVMAMR07","CHE-TVMAMR08","CHE-TVMAMR09","CHE-TVMAMR10","CHE-TVMAMR11","CHE-TVMAMR12","CHE-TVMAMR13","CHE-TVMAMR14","CHE-TVMAMR15","CHE-TVMAMR16","CHE-TVMAMR17","CHE-TVMAMR18","CHE-TVMAMR19","CHE-TVMAMR20","CHE-TVMAMR21","CHE-TVMAMR22","CHE-TVMAMR23","CHE-TVMAMR24","CHE-TVMAMR25","CHE-TVMAMR26","CHE-TVMAMR27","CHE-TVMAMR28","CHE-TVMAMR29","CHE-TVMAMR30","CHE-TVMAMR31","CHE-TVMAMR32","CHE-TVMAMR33","CHE-TVMAMR34","CHE-TVMAMR35","CHE-TVMAMR36","CHE-TVMAMR37","CHE-TVMAMR38","CHE-TVMAMR39","CHE-TVMAMR40","CHE-TVMAMR41","CHE-TVMAMR42","CHE-TVMAMR43","CHE-TVMAMR44","CHE-TVMAMR45","CHE-TVMAMR46","CHE-TVMAMR47","CHE-TVMAMR48","CHE-TVMAMR49","CHE-TVMAMR50","CHE-TVMAMR51","CHE-TVMAMR52","CHE-TVMAMR53","CHE-TVMAMR54","CHE-TVMEUR20","CHE-TVMEUR21","CHE-TVMEUR22","CHE-TVMEUR23","CHE-TVMEUR24","CHE-TVMEUR25","CHE-TVMEUR26","CHE-TVMEUR27","CHE-TVMEUR28","CHE-TVMEUR29","CHE-TVMEUR30","CHE-TVMEUR31","CHE-TVMEUR32","CHE-TVMEUR33","CHE-TVMEUR34","CHE-TVMEUR35","CHE-TVMEUR36","CHE-TVMEUR37","CHE-TVMEUR38","CHE-TVMEUR39","CHE-TVMEUR40","CHE-TVMEUR41","CHE-TVMEUR42","CHE-TVMEUR43","CHE-TVMEUR44","CHE-TVMEUR45","CHE-TVMEUR46","CHE-TVMEUR47","CHE-TVMEUR48","CHE-TVMEUR49","CHE-TVMEUR50","CHE-TVMEUR51","CHE-TVMEUR52","CHE-TVMEUR53","CHE-TVMEUR54","CHE-TVMEUR55","CHE-TVMEUR56","CHE-TVMEUR57","CHE-TVMEUR58","CHE-TVMEUR59","CHE-TVMEUR60","CHE-TVMEUR61","CHE-TVMEUR62","CHE-TVMEUR63","CHE-TVMEUR64","CHE-TVMEUR65","CHE-TVMEUR66","CHE-TVMEUR67","CHE-TVMEUR68","CHE-TVMEUR69","CHE-TVMEUR70","CHE-TVMEUR71","CHE-TVMEUR72","CHE-TVMEUR73","CHE-TVMEUR74","CHE-TVMEUR75","CHE-TVMEUR76","CHE-TVMEUR77","CHE-TVMEUR78","CHE-TVMEUR79","CHE-TVMEUR80","CHE-TVMEUR81","CHE-TVMEUR82","CHE-TVMEUR83","CHE-TVMEUR84","CHE-TVMEUR85","CHE-TVMEUR86","CHE-TVMEUR87","CHE-TVMEUR88","CHE-TVMEUR89","CHE-TVMEUR90","CHE-TVMEUR91","CHE-TVMEUR92","CHE-TVMEUR93","CHE-TVMEUR94","CHE-TVMEUR95","CHE-TVMEUR96","CHE-TVMEUR97","CHE-TVMEUR98","CHE-TVMEUR99","CHE-TVMAPC01","CHE-TVMAPC02","CHE-TVMAPC03","CHE-TVMAPC04","CHE-TVMAPC05","CHE-TVMAPC06","CHE-TVMWTE01","CHE-TVMWTE02","CHE-TVMWTE03","CHE-TVMWTE04","CHE-TVMWTE05","CHE-TVMWTE06","CHE-AIRINT01","CHE-AIRINT02","CHE-AIRINT03","CHE-AIRINT04","CHE-AIRINT05","CHE-AIRINT06","CHE-AIRINT07","CHE-AIRINT08","CHE-AIRINT09","CHE-AIRINT10","CHE-AIRINT11","CHE-AIRINT12","CHE-AIRINT13","CHE-AIRINT14","CHE-AIRINT15","CHE-AIRINT16","CHE-AIRINT17","CHE-AIRINT18","CHE-AIRINT19","CHE-AIRINT20","CHE-AIRINT21","CHE-AIRINT22","CHE-AIRINT23","CHE-AIRINT24","CHE-AIRINT25","CHE-AIRINT26","CHE-AIRINT27","CHE-AIRINT28","CHE-AIRINT29","CHE-AIRINT30","CHE-AIRINTEX00","CHE-AIRINTEX01","CHE-AIRINTEX02","CHE-AIRINTEX03","CHE-AIRINTEX04","CHE-AIRINTEX05","CHE-AIRINTEX06","CHE-AIRINTEX07","CHE-AIRINTEX08","CHE-AIRINTEX09")

For Each strComputer In arrComputers
   WScript.Echo
   WScript.Echo "=========================================="
   WScript.Echo "Computer: " & strComputer
   WScript.Echo "=========================================="


   Set objWMIService1 = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
   Set colItems1 = objWMIService1.ExecQuery("SELECT * FROM Win32_ComputerSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
   Set objWMIService2 = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
   Set colItems2 = objWMIService2.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
   Set objWMIService3 = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
   Set colItems3 = objWMIService3.ExecQuery("SELECT * FROM Win32_LogicalDisk", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
   Set objWMIService4 = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
   Set colItems4 = objWMIService4.ExecQuery("SELECT * FROM Win32_LogicalDiskToPartition", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

   For Each objItem1 In colItems1
      WScript.Echo "Processor Count: " & objItem1.NumberOfProcessors
      WScript.Echo "Physical Memory: " & objItem1.TotalPhysicalMemory
      strSystemStartupOptions = Join(objItem1.SystemStartupOptions, ",")
         WScript.Echo "SystemStartupOptions: " & strSystemStartupOptions
   Next

   For Each objItem2 In colItems2
      WScript.Echo "Serial Number: " & objItem2.IdentifyingNumber
      WScript.Echo "Server Model: " & objItem2.Name
   Next

   For Each objItem3 In colItems3
      WScript.Echo "Logical Disk: " & objItem3.DeviceID
      WScript.Echo "Size: " & objItem3.Size
   Next

   For Each objItem4 In colItems4
      WScript.Echo "Disk/Partition ID: " & objItem4.Antecedent
      WScript.Echo "Partition Name: " & objItem4.Dependent
      WScript.Echo "StartingAddress: " & objItem4.StartingAddress
      WScript.Echo "EndingAddress: " & objItem4.EndingAddress
   Next
Next