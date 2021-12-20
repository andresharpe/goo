<# GooGit.psm1 #>

class GooGit {

    [string]$Name
    [Object]$Goo

    GooGit( [Object]$goo ){
        $this.Name = "Git"
        $this.Goo = $goo
    }

    [string] ToString()
    {
        return "Goo"+$this.Name+"Module"
    }
}

