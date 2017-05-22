#Gets the Server Name
$server = [System.Environment]::MachineName 

#Domain Name
$domain = "MyCompany" 

import-csv UserAccounts.txt |
    foreach{ 
        #Create the ID
        $id = $("$domain"+"\"+$_.Account);
        $alias = $_.Account 

        #Get the first character of the first name
        $str =$_.First.substring(0,1)
        $Database="" 

        #Set the Database based on the first character of the first name
        #You might need to change the name of the Storage Group and Database based on        #your environment. 

        switch -regex ($str.ToLower()) 
         { 
                "[a-b]" {$Database = $server+"\A-B Users\"+"Mailbox Database"} 
                "[c-d]" {$Database = $server+"\C-D Users\"+"Mailbox Database"} 
                "[e-f]" {$Database = $server+"\E-F Users\"+"Mailbox Database"} 
                "[g-h]" {$Database = $server+"\G-H Users\"+"Mailbox Database"} 
                "[i-j]" {$Database = $server+"\I-J Users\"+"Mailbox Database"} 
                "[k-l]" {$Database = $server+"\K-L Users\"+"Mailbox Database"} 
                "[m-n]" {$Database = $server+"\M-N Users\"+"Mailbox Database"} 
                "[o-p]" {$Database = $server+"\O-P Users\"+"Mailbox Database"} 
                "[q-r]" {$Database = $server+"\Q-R Users\"+"Mailbox Database"} 
                "[s-t]" {$Database = $server+"\S-T Users\"+"Mailbox Database"} 
                "[u-v]" {$Database = $server+"\U-V Users\"+"Mailbox Database"} 
                "[w-x]" {$Database = $server+"\W-X Users\"+"Mailbox Database"} 
                "[y-z]" {$Database = $server+"\Y-Z Users\"+"Mailbox Database"}
                default {$Database = $server+"\First Storage Group\"+"Mailbox Database"}
         }
        # Run the actual command to enable the mailbox.
        enable-Mailbox -Identity $id -Database $Database -Alias $alias        -DisplayName $($_.First+ " " + $_.Last)

  }
#http://blogs.msdn.com/b/akashb/default.aspx?PageIndex=1&PostSortBy=MostViewed&Redirected=true