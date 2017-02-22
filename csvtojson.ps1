creates JSON files from CSV for Seiso Node data.
#Where am I running from to fix relative paths ?
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
cd $dir

$csvfiles = dir "${dir}\in\*.csv"
foreach ($csvfiles in $csvfiles){

Write-Host "Processing ${csvfiles}"
$outjson= $csvfiles.BaseName

$csv = Import-Csv $csvfiles
$stream = [System.IO.StreamWriter] "${dir}\nodes-${outjson}.json"
#start bracket
$stream.WriteLine("{`"type`": `"nodes`" ,`"serviceInstance`": `"${outjson}`",  `"items`":[")


ForEach ($csv in $csv){
			$ip = $csv.ipAddress
			$machine = $csv.machine
			$name = $csv.name
			$port = $csv.port
			$si = $csv.serviceinstance
			$state = $csv.state	
			$stream.WriteLine("{")
			
			
			
			[string] $ipaddress = $csv.ipAddress
			[array]$ipaddress =$ipaddress -split ";"
			[int] $adapter=1
			[int] $ipcount= $ipaddress.Count
			
			
			
		
			
			
			$stream.WriteLine("`"name`" : `"${name}`",")
			#$stream.WriteLine("`"serviceInstance`" : `"${si}`",")
			$stream.WriteLine("`"machine`" : `"${machine}`",")
			
			#$stream.WriteLine("`"port`" : ${port},")
			
			#$stream.WriteLine("`"state`" : `"${state}`"")
			
				$stream.WriteLine("`"ipAddresses`" `: [")
			
			if ($ipaddress.Count -gt 1){
	
				foreach ($ipaddress in $ipaddress){
					if ($adapter -ne $ipcount){
				`		#Write-Host "adapter${adapter} ${ipaddress}"
						$stream.WriteLine("{ `"ipAddressRole`" : { `"name`" : `"default${adapter}`" }, `"ipAddress`" : `"${ipaddress}`"}")
						
					}
					else{
						$stream.WriteLine("{ `"ipAddressRole`" : { `"name`" : `"default${adapter}`" }, `"ipAddress`" : `"${ipaddress}`"},]")
					}
				$adapter = $adapter +1			
				}
				}

				else{
					$stream.WriteLine("{ `"ipAddressRole`" : `"default`", `"ipAddress`" :`"${ipaddress}`"}]")
					#Write-Host "adapter ${ipaddress}"
					}
			
			
			
			$stream.WriteLine("},")
			}
$stream.close()
$content = get-content ${dir}\nodes-${outjson}.json
$content[0..($content.length-2)] >${dir}\nodes-${outjson}.json
#End Bracket
echo "}]}" >> ${dir}\nodes-${outjson}.json


Get-ChildItem ${dir}\nodes-${outjson}.json | ForEach-Object {
  # get the contents and replace line breaks by U+000A
  $contents = [IO.File]::ReadAllText($_) -replace "`r`n?", "`n"
  # create UTF-8 encoding without signature
  $utf8 = New-Object System.Text.UTF8Encoding $false
  # write the text back
  [IO.File]::WriteAllText($_, $contents, $utf8)
}
gc ${dir}\nodes-${outjson}.json

}

