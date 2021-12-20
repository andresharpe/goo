# goo.ps1 stub - searches for and launches first '.goo.ps1' script in all parent folder heirarchy
Push-Location
$folder = (Get-Item -Path '.')
while (-not (Test-Path ".goo.ps1") ) {
    Set-Location -Path $folder.Parent.FullName 
    $folder = (Get-Item -Path '.')
    if ($null -eq $folder.Parent) {
        Write-Host "[goo] No .goo.ps1 found in the current or parent folder(s)." -ForegroundColor "Magenta"
        Pop-Location
        exit
    }
}
$params = if($args.Count -eq 0) {""} else {'"'+($args -join '" "')+'"'}
Invoke-Expression ".\.goo.ps1 $params"

### eof goo.ps1