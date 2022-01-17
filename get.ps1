<#

To install 'goo' in your project, start Powershell in your main project folder and run:-
    
iwr get.goo.dev | iex
    
#>

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'stop' 

if (($PSVersionTable.PSVersion.Major) -lt 7) {
    Write-Output "PowerShell 7 or later is required to run goo."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows"
    break
}

# show notification to change execution policy:
$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run goo."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
    break
}

if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
    Write-Output "goo requires at least .NET Framework 4.5"
    Write-Output "Please download and install it first:"
    Write-Output "https://www.microsoft.com/net/download"
    break
}

# get goo

$projectReleaseUri = 'https://github.com/andresharpe/goo/releases/download/latest/publish.zip'
$tempFile = New-TemporaryFile
Invoke-WebRequest -Method Get -Uri $projectReleaseUri -OutFile $tempFile
Expand-Archive -Path $tempFile -DestinationPath '.' -Force
Remove-Item $tempFile -Force

# copy goo.ps1 to user app directory if needed
$homePath = $env:HOME ?? $env:USERPROFILE
$gooPath = "$homePath\AppData\Local\Programs\goo\bin"
if( -not (Test-Path $gooPath) ) { 
    New-Item $gooPath -ItemType Directory | Out-Null
}
$gooPath = (Get-Item $gooPath).FullName

if( -not (Test-Path "$gooPath\goo.ps1") ) { 
    Copy-Item .\.goo\goo.ps1 $gooPath | Out-Null
}

# ensure it's in the PATH
$splitChar = ($null -eq $env:HOME ? ';' : ':')
if( -not (($env:PATH -split $splitChar).Contains($gooPath))){
    $env:PATH = $env:PATH+$splitChar+$gooPath
    [Environment]::SetEnvironmentVariable("PATH", $env:PATH, [System.EnvironmentVariableTarget]::User)
}

# create default .goo.ps1 if it doesn't exist

if(-not (Test-Path '.\.goo.ps1')) {
    Copy-Item -Path '.\.goo\templates\.goo.default.template.ps1' -Destination '.\.goo.ps1'
}

Write-Host ""
Write-Host -ForegroundColor Magenta -BackgroundColor Black -Object " goo> Success!" 
Write-Host ""
Write-Host -ForegroundColor DarkGray -BackgroundColor Black -Object "edit '.\.goo.ps1' to set your project preference."
Write-Host ""

$width = $global:Host.UI.RawUI.WindowSize.Width
Write-Host -ForegroundColor White -BackgroundColor DarkMagenta -Object "".PadRight($width)
Write-Host -ForegroundColor White -BackgroundColor DarkMagenta -Object "Type 'goo' to view your project supported commands.".PadRight($width)
Write-Host -ForegroundColor White -BackgroundColor DarkMagenta -Object "".PadRight($width)
Write-Host ""

$ErrorActionPreference = $oldErrorActionPreference 