<# goo.psm1 #>

using module '.\modules\goo-io.psm1'
using module '.\modules\goo-command.psm1'
using module '.\modules\goo-console.psm1'
using module '.\modules\goo-choco.psm1'
using module '.\modules\goo-network.psm1'
using module '.\modules\goo-sql.psm1'
using module '.\modules\goo-dotnet.psm1'
using module '.\modules\goo-benchmark.psm1'
using module '.\modules\goo-git.psm1'
using module '.\modules\goo-docker.psm1'
using module '.\modules\goo-version.psm1'

# ensure goo.ps1 in this folder is in path
if( -not( $env:Path.Contains('\.goo') ) ) {
    $thisPath = (Split-Path -Path $PSCommandPath -Parent) + ';'
    $env:Path = $thisPath+$env:Path
}

<# GOO CLASS IMPLEMENTATION #>

class Goo {

    [string]$Arguments
    
    [GooIO]$IO
    [GooConsole]$Console
    [GooCommand]$Command
    [GooChoco]$Choco
    [GooNetwork]$Network
    [GooSql]$Sql
    [GooDotnet]$Dotnet
    [GooBenchmark]$Benchmark
    [GooGit]$Git
    [GooDocker]$Docker
    [GooVersion]$Version

    Goo( [Object[]]$arguments ){
        
        $this.Arguments = $arguments

        # install modules
        $this.IO = [GooIO]::new( $this )
        $this.Console = [GooConsole]::new( $this )
        $this.Command = [GooCommand]::new( $this, $arguments )
        $this.Choco = [GooChoco]::new( $this )
        $this.Network = [GooNetwork]::new( $this )
        $this.Sql = [GooSql]::new( $this )
        $this.Dotnet = [GooDotnet]::new( $this )
        $this.Benchmark = [GooBenchmark]::new( $this )
        $this.Git = [GooGit]::new( $this )
        $this.Docker = [GooDocker]::new( $this )
        $this.Version = [GooVersion]::new( $this )

    }


    [void] Start() {

        $startTime = $(get-date)
        $oldProgressPreference = $global:ProgressPreference
        $global:ProgressPreference = "SilentlyContinue"
        $this.Console.WriteBanner()
        
        try {

            switch ($this.Command.MainCommand)
            {
                "help"             { $this.Console.WriteHelp(); return; }
                "goo-release"      { $this.GooRelease(); return; }
                "goo-version"      { $this.GooGetVersion() ; return; }
                "goo-bump-build"   { $this.GooBumpVersion('build') ; return; }
                "goo-bump-patch"   { $this.GooBumpVersion('patch') ; return; }
                "goo-bump-minor"   { $this.GooBumpVersion('minor') ; return; }
                "goo-bump-major"   { $this.GooBumpVersion('major') ; return; }
                "goo-update"       { $this.GooUpdate(); return; }
            }

            try {
                $this.Console.WriteInfo("Environment is [$Env:ENVIRONMENT]")
                $this.Command.Run()
                $elapsedTime = $(get-date) - $startTime
                $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
                $this.Console.WriteInfo("Success! ($totalTime)")
        
            } catch {
                Pop-Location
                $this.Console.WriteError("Error - $PSItem :(")
            }
    
        }
        finally {
            $global:ProgressPreference = $oldProgressPreference
        }
    }

    [void] Error( [string]$message ) {
        throw $message
    }

    [void] GooRelease()
    {
        $this.IO.EnsureFolderExists('.\dist')
        Compress-Archive -Path '.\.goo' -CompressionLevel Optimal -DestinationPath '.\dist\publish.zip' -Force

        $this.Command.RunExternal('gh','release delete latest --yes' )

        $ver = $this.Version.Get('.\.goo\goo.version')
        
        $this.Command.RunExternal('gh','release create latest --notes "latest release" --title "v'+"$($ver.Major).$($ver.Minor).$($ver.Patch)"+'" .\dist\publish.zip' )
        $this.StopIfError("Failed to create latest release on GitHub (gh cli)")

        $this.Command.RunExternal('gh', 'release list --limit 3')
    }

    [void] GooUpdate()
    {
        $this.Console.WriteInfo("Updating...")
        Invoke-WebRequest -Method Get -Uri 'https://github.com/andresharpe/goo/releases/download/latest/publish.zip' -OutFile '.\goo-latest.zip'
        Expand-Archive -Path '.\goo-latest.zip' -DestinationPath '.' -Force
        Remove-Item '.\goo-latest.zip' -Force
        $this.GooGetVersion();
    }

    [void] GooBumpVersion([string] $part)
    {
        $newVersion = $this.Version.Bump( '.\.goo\goo.version', $part )
        $this.Console.WriteInfo("Bumped Goo $part version. The new version is $newVersion")
    }

    [void] GooGetVersion()
    {
        $currentVersion = $this.Version.CurrentVersion('.\.goo\goo.version')
        $this.Console.WriteInfo("The current version of Goo is $currentVersion")
    }

    [void] StopIfError( [string]$message ) {
        if ($this.Command.LastExitCode -gt 0) {
            $this.Error($message)
        }
    }

    [bool] IsAdminSession() {
        return ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
       ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    [void] Sleep( [int]$seconds ) {
        Start-Sleep -Seconds $seconds
    }

}



