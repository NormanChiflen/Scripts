
param([string]$environment)
#$environment=$args[0]

#Loading config file (hard coded since there will be only one)
$defaultconfig ="environments.csv"
$DefaultCSV=Import-Csv .\$defaultconfig # -delimiter ~


Switch ($environment){
					#Was anything specified for environment?
""                        {Write-host -f yellow "Deployment environment not specified. ";
							write "example:  Script_name.ps1 Test01"; 
							write "list of all available environments in the config."
							foreach($i in $DefaultCSV){write $i.environment};break}
					#Does specified value exists in environments.
$environment              {if(-not($DefaultCSV | ? {$_.environment -eq $environment}))
							{"environment "+$environment+" not found in the $Defaultconfig"
							write "list of all available environments in the config."
							foreach($i in $DefaultCSV){write $i.environment};break}}
					#Finding values for correct environment.
$environment              {$arrayposition=-1    #need a correct way to find out where i am in an array or else.
							Foreach($i in $DefaultCSV){
							$arrayposition++
							if ($i.environment -eq $environment)
								{$EnvironmentServers= $i.Servers_in_Environment.split(";")
								$tokenproviderURL	= $i.Token_Provider_Url
								$CertName			= $i.Cert_Name
								$EndpointURL		= $i.End_Point_URL
								$App_Fabric_Cache	= $i.App_Fabric_Cache
								$App_Fabric_Hosts_a	= $i.App_Fabric_Hosts.split(";")
								$ADFSUrl			= $i.ADFS_Url
								$SSLThumbprint		= $i.SSLThumbprint
								$TrustURL			= $i.TrustURL
								$PFXfilename		= $i.PFXfilename
								$PFXPassword		= $i.PFXPassword
								$arrayposition
							write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
							}
						}
					}

"went past the loop" 

#Was anything specified for environment?
		# if($environment -eq "")
		# {Write-host -f yellow "Deployment environment not specified. ";
		# write "example:  Script_name.ps1 Test01"; 
		# write "list of all available environments in the config."
		# foreach($i in $DefaultCSV){write $i.environment}
		# break}
		# else {"Executing script for $environment"}

#"script ran past the IF LOOP";break   #debug code


#Testing if specified value exists in environments.
		# if(-not($DefaultCSV | ? {$_.environment -eq $environment})){"environment "+$environment+" not found in the $Defaultconfig";break}


#Finding values for correct environment.
		# $arrayposition=-1    #need a correct way to find out where i am in an array or else.
		# Foreach($i in $DefaultCSV){
			# $arrayposition++
			# if ($i.environment -eq $environment)
				# {$EnvironmentServers= $i.Servers_in_Environment.split(";")
				# $tokenproviderURL	= $i.Token_Provider_Url
				# $CertName			= $i.Cert_Name
				# $EndpointURL		= $i.End_Point_URL
				# $App_Fabric_Cache	= $i.App_Fabric_Cache
				# $App_Fabric_Hosts_a	= $i.App_Fabric_Hosts.split(";")
				# $ADFSUrl			= $i.ADFS_Url
				# $SSLThumbprint		= $i.SSLThumbprint
				# $TrustURL			= $i.TrustURL
				# $arrayposition
			# write "Environment $environment found, loading values: "; $DefaultCSV[$arrayposition]}
			# }
#$DefaultCSV[$arrayposition].Comment      # Debug code

#App Fabric hosts Hash table conversion.
#$AppFabricServers=@(($DefaultCSV[$arrayposition].Comment).tolower().split(","))    #Debug code
#$AppFabricServers                #Debug code.

# one liner -  $d=@{};foreach($r in $DefaultCSV[$arrayposition].app_fabric_hosts.split(",")){$d.add($r,"22233")}


#generic hash table for debugging.
#$states = @{"Washington" = "Olympia"; "Oregon" = "Salem"; California = "Sacramento"}


#more debug code
		# $a | ? {$_.environment -eq $userinput}
		# Foreach($i in $a){write $i.environment }
		# Foreach($i in $a){$i.environment -eq $UserInput}


		#$a[$arrayposition].environment
		#	else
		#	{write "environment $userinput not found in the $defaultconfig";break}



			# $App_Fabric_Hosts_h = @{}
			# foreach($r in $App_Fabric_Hosts_a)
			# {	Write-Host $r.server         #debug code
				# $App_Fabric_Hosts_h.add($r,"22233")
			# }
			# $App_Fabric_Hosts_h              #Debug code






#$name = Microsoft.PowerShell.Security
#if(-not(Get-Module -name applocker)) {Import-Module -Name applocker}else{"hello"}

#$name="Microsoft.Adfs.PowerShell"
#if(-not(foreach($i in get-pssnapin){write $i.name})) {Add-PSSnapin Microsoft.Adfs.PowerShell -Name $name}
#foreach($i in get-pssnapin){write $i.name}

 