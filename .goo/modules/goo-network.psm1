<# GooNetwork.psm1 #>

class GooNetwork {

    [string]$Name
    [Object]$Goo

    GooNetwork( [Object]$goo ){
        $this.Name = "Network"
        $this.Goo = $goo
    }

    [string] ToString()
    {
        return "Goo"+$this.Name+"Module"
    }

    [void] EnsureConnectionTo( [string]$deviceAddress ) {
        if (-not (Test-Connection -ComputerName $deviceAddress -Count 1 -ErrorAction 0 -Quiet) ) {
            $this.Goo.Error( "Please connect to the VPN before running an init." )
        }
    }

}
