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

    [void] CheckoutFeature([string]$featureName)
    {
        git checkout -b feature/$featureName
        if($?) { git push --set-upstream origin feature/$featureName }
        if($?) { git pull }
    }

    [void] CheckoutMain()
    {
        git checkout main
        if($?) { git pull --prune }
        if($?) { git fetch origin }
        if($?) { git reset --hard origin/main }
        if($?) { git clean -f -d }
    }
}

