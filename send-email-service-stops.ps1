#I have followed the tutorial here: http://sqlish.com/alert-when-sql-server-agent-service-stops-or-fails/

Command ‘Send-MailMessage -To nfletcher@expedia.com -Subject \”chelt2bld01:Service has Stopped-test\” -Body \”Please look into the issue; Scheduled Jobs will not run if the SQL Server Agent Service remains stopped.\” -SmtpServer  smtp.gmail.com -From chiflensystems@gmail.com’