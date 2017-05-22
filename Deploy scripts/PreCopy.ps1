param($version,$source,$destination)

# $version = "7.4.1.0"
# $source = "\\CHELT2FIL01\DirectedBuilds\depot\bfsexpe\products\air\v7.4.1.0\deliverables\depot.bfsexpe.products.air\v7.4.1.0\travbin"
# $destination = "D:\travbin.new"

Function PreCopy
{
    param($src, $dest)
    
    if (-not (Test-Path $src))
    {
        write-host -foregroundcolor Red "$src does not exist"
        exit 1
    }
	  
    if (Test-Path $dest)
    {
        Write-Host "$dest already exists, removing..."
		try
		{
			remove-item -recurse -path $dest -force -erroraction "silentlycontinue"
		}
		catch
		{
			write-host -foregroundcolor Red "ERROR: $error[0].Exception.ToString()"
			write-host -foregroundcolor Red "`nRemoval of $dest failed."
			exit 1
		}

		if (Test-Path $dest)
		{
			write-host -foregroundcolor Red "Removal of $dest failed."
			exit 1
		}
    }
    
    Write-Host "Begin copying $src to $dest"
    
    Copy-Item $src $dest -recurse
    
    Write-Host "Finished copying $src to $dest"
    
    if (VerifyFileVersion $dest $version)
    {
        Write-Host "FileVersion $version verified"
    }
    else
    {
        write-host -foregroundcolor Red "FileVerion $version incorrect"
		exit 1
    }

    if (CompareDirectories $source $Destination)
	{
		Write-Host "CompareDirectories successful"
	}
	else
	{
		write-host -foregroundcolor Red "CompareDirectories failed"
		exit 1
	}

    exit 0
}

Function VerifyFileVersion
{
    Param($path, $expectedVer)
	Write-Host "Verifying file version..."
    $ver = (Get-ItemProperty $path\bfs\first.dll).VersionInfo.ProductVersion
    return $ver -eq  $expectedVer
}

Function CompareDirectories
{
    Param($dir1, $dir2)
	Write-Host "Comparing directories..."
    $dir1 = Get-ChildItem -Path $dir1           
    $dir2 = Get-ChildItem -Path $dir2            
    return Compare-Object -ReferenceObject $dir1 -DifferenceObject $dir2 -IncludeEqual -ExcludeDifferent
}


PreCopy $source $destination