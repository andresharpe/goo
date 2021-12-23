<# GooVersion.psm1 #>

class GooVersion {

    [string]$Name
    [Object]$Goo

    GooVersion( [Object]$goo ){
        $this.Name = "Version"
        $this.Goo = $goo
    }

    [string] ToString()
    {
        return "Goo"+$this.Name+"Module"
    }

    [string] Bump([string]$versionInfoFile, [string]$part)
    {

        $version = $this.Get($versionInfoFile)

        [string]$element = 'Build'

        switch -wildcard ($part)
        {
            "ma*"   { $element = 'Major' }
            "mi*"   { $element = 'Minor' }
            "p*"    { $element = 'Patch' }
            "b*"    { $element = 'Build' }
            default { $this.Goo.Error('Version part parameter should be: minor, major, patch or build!')}
        }

        $version.$element = (([int]$version.$element)+1)

        switch ($element)
        {
            'Major' { $version.Minor = 0; $version.Patch = 0 }
            'Minor' { $version.Patch = 0 }
        }

        $this.Set($version)

        return "$($version.Major).$($version.Minor).$($version.Patch) (build $($version.Build))"

    }

    [string] CurrentVersion([string]$versionInfoFile)
    {
        $version = $this.Get($versionInfoFile)
        return "$($version.Major).$($version.Minor).$($version.Patch) (build $($version.Build))"
    }

    [string] BumpBuild([string]$versionInfoFile)
    {
        return $this.Bump($versionInfoFile,'Build')
    }

    [string] BumpPatch([string]$versionInfoFile)
    {
        return $this.Bump($versionInfoFile,'Patch')
    }

    [string] BumpMinor([string]$versionInfoFile)
    {
        return $this.Bump($versionInfoFile,'Minor')
    }

    [string] BumpMajor([string]$versionInfoFile)
    {
        return $this.Bump($versionInfoFile,'Major')
    }

    [object] Get([string]$versionInfoFile)
    {
    	
    	$versionPattern = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'

        if(Test-Path $versionInfoFile) {
            $versionInfo = Get-ChildItem $versionInfoFile 
        }
        else {
            $versionInfo = Get-ChildItem -Recurse | 
                Where-Object {$_.Name -eq $versionInfoFile} | 
                Select-Object -First 1
        }

    	if(!$versionInfo)
    	{
    		$this.Goo.Error("Could not find version info file")
    	}

    	$matchedLine = Get-Content $versionInfo.FullName |
    	    Where-Object { $_ -match $versionPattern } |
    		Select-Object -First 1

    	if(!$matchedLine)
    	{
    		$this.Goo.Error("Could not find line containing version in version info file")
    	}					   

    	$major, $minor, $patch, $build = 
            ([regex]$versionPattern).matches($matchedLine) |
    		ForEach-Object {$_.Groups } | 
    		Select-Object -Skip 1

    	return New-Object PSObject -Property @{
            FileName = $versionInfo.FullName
    		Major = $major.Value
    		Minor = $minor.Value
    		Patch = $patch.Value
    		Build = $build.Value
    	}
    }

    [void] Set([object]$version)
    {
    	$versionPattern = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
        $newVersion = "$($version.Major).$($version.Minor).$($version.Patch).$($version.Build)"

  		$currentFile = $version.FileName
        $tempFile = ("$currentFile.tmp")
  		
        Get-Content $currentFile | ForEach-Object {
  			ForEach-Object { $_ -Replace $versionPattern, $newVersion }
   		} | Set-Content $tempFile
   		
        Remove-Item $currentFile
   		
        Rename-Item $tempFile $currentFile
    }
}
