<# GooDocker.psm1 #>

class GooDocker {

    [string]$Name
    [Object]$Goo

    GooDocker( [Object]$goo ){
        $this.Name = "Docker"
        $this.Goo = $goo
    }

    [string] ToString()
    {
        return "Goo"+$this.Name+"Module"
    }

    [void] Up() {
        $this.Up((Get-Location).Path) 
    }

    [void] Up( [string]$folder ) {
        $this.Goo.Command.RunExternal( 'docker-compose', 'up -d', $folder ) 
    }

    [void] Down(){
        $this.Down((Get-Location).Path)
    }

    [void] Down( [string]$folder ) {
        if ($null -ne (docker-compose --project-directory $folder ps -q)) {
            $this.Goo.Command.RunExternal( 'docker-compose', "down", $folder ) 
        }   
    }

    [void] StopAllRunningContainers()
    {
        #$obj = $this.Goo.Command.RunExternalExt( 'docker','ps -q' )
        #$containers = $obj.Output -split "`n"
        #docker kill $containers
        docker kill $(docker ps -q)
    }

}
