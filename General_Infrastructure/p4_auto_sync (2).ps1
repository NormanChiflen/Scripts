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
"-Kill any open handles for CCT_Self_Service_Builds.exe" | out-file $Logfile -append

killHandle.bat CCT_Self_Service_Builds.exe
gc $PossibleError | out-file $Logfile  -append
	
p4 sync ...

if ($LASTEXITCODE -ne 0)
	{
	start-process -filepath p4 -argumentlist "sync ..." -NoNewWindow -RedirectStandardError $PossibleError -wait
	gc $PossibleError | out-file $Logfile  -append
		
	$mailbody = "Error: `n"
	$mailbody += gc $PossibleError
	if ((gc $PossibleError) -match "clobber"){
		$mailbody += "attempted to auto clean by deleting the unclobberable file"
		del -literalpath $PossibleError.replace("Can't clobber writable file ","").replace("/","\").trimend()
		}
	
	$asubject = "p4 auto sync script on $env:computername might be broken"
	$mailto = "cctrel@expedia.com"
	amail "avinyar@expedia.com" $mailto $asubject $mailbody
	}