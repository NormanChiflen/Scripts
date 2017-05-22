if($args.count -ne 2)
{
    write-host You should give two parameters!
    return
}

$input = Get-Content $args[1]
$samplpe = Get-Content $args[0]

foreach($line in $input)
{       
        name= $line | %{"$($_.Split('t')[1])"}
        date= $line | %{"$($_.Split('t')[2])"}
        place= $line | %{"$($_.Split('t')[3])"}
        write-host cat $sample | Select-String [-"<NAME>"] | %{$_ -replace "<NAME>", "$name"}`
        write-host cat $sample | Select-String [-"<NAME>"] | %{$_ -replace "<DATE>", "$date"}
        write-host cat $sample | Select-String [-"<NAME>"] | %{$_ -replace "<PLACE>", "$place"}

}