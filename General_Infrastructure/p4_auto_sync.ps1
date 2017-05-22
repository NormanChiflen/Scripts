function amail ($from, $mailto, $subject, $body)
  {$smtpHost = "chelsmtp01.karmalab.net"
    $email = New-Object System.Net.Mail.MailMessage
    $email.IsBodyHtml = $true
    $email.From = $from
    $mailto | foreach {$email.To.Add($_)}
      #-old email string to single recepient- $email.To.Add($to)
    $email.Subject = $subject
    $email.Body = $body
    # Send the mail
      $client = New-Object System.Net.Mail.SmtpClient $smtpHost
      $client.UseDefaultCredentials = $true
      $client.Send($email)
    }
    
# Start of the script
$Logfile = "C:\CCT_OPS\1986_LastSync.log"
$PossibleError = "C:\CCT_OPS\trash.log"

#pushd C:\depot\depot_1986
(gc $Logfile | select -last 1000 ) | out-file $Logfile
"=====================================================" | out-file $Logfile  -append
get-date | out-file $Logfile  -append


gc $PossibleError | out-file $Logfile  -append
	
p4 sync ...

if ($LASTEXITCODE -ne 0)
	{
	start-process -filepath p4 -argumentlist "sync ..." -NoNewWindow -RedirectStandardError $PossibleError -wait
	gc $PossibleError | out-file $Logfile  -append
		
	$mailbody = "Please inspect full log file here: " + $Logfile.replace("C:","\\chelappsbx001\c$")
	$mailbody += "`nError: `n"
	$mailbody += gc $PossibleError

	if ((gc $PossibleError) -match "clobber"){
		$mailbody += "attempted to auto clean by deleting the unclobberable file"
		del -literalpath $PossibleError.replace("Can't clobber writable file ","").replace("/","\").trimend()
		}
	Elseif((gc $PossibleError) -match "denied"){
		try{
			try {
				#Killing handle to JUST the affected file
				$b = gc $PossibleError
				$b -match '.:\\.*? '
				$a=c:\localbin\handle.exe -accepteula $matches[0]
				$a[5..$a.count] -gt 0 | %{c:\localbin\handle.exe -p $_.substring(24,7).trim() -c $_.substring(31.4).trim() -y}
				$mailbody += "action taken: attempted to kill handle to the file: $matches[0]"
				}
			catch{"cant close handle for $matches[0] - $_.error" | out-file $Logfile -append}
			}
		catch{
			#Killing handle to the whole tree
			"Access Denied error detected - Kill any open handles in DeploymentAutomation folder" | out-file $Logfile -append
			$a=c:\localbin\handle.exe -accepteula D:\depot\depot_1986\sait\DeploymentAutomation_selfDeployApp
			try{$a[5..$a.count] -gt 0|%{c:\localbin\handle.exe -p $_.substring(24,7).trim() -c $_.substring(31.4).trim() -y}}
			catch{"cant close handle for $_.error"| out-file $Logfile -append}
			$mailbody += "action taken: attempted to kill all handles under $a"
			}
		}
	Else{
		$asubject = "p4 auto sync script on $env:computername might be broken"
		$mailto = "cctrel@expedia.com"
		amail "avinyar@expedia.com" $mailto $asubject $mailbody
		}
	}