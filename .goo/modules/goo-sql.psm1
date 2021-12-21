<# GooSql.psm1 #>

class GooSql {

    [string]$Name
    [Object]$Goo

    GooSql( [Object]$goo ){
        $this.Name = "Sql"
        $this.Goo = $goo
    }

    [string] ToString()
    {
        return "Goo"+$this.Name+"Module"
    }

    [void] Query( [string]$connString, [string]$sql ){
        if( -not ((Get-Module -ListAvailable -Name "SqlServer"))) {
            $this.Goo.Error("Module not found. Please run 'Install-Module -Name SqlServer' as admin")
        }
        Invoke-Sqlcmd -ConnectionString $connString -Query $sql | Format-Table -AutoSize | Out-Host
        if( -not $? ) { $this.Goo.Error( "Sql error." ) }
    }



}
