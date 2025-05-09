if ($host.Name -ne "ConsoleHost") {
    return
}

$modules = "PSReadLine", "PSFzf"
$modules | ForEach-Object {
    if (-not (Get-Module $_ -ListAvailable)) {
        Write-Output "Installing $_"
        Install-Module $_
    }
}

$modules | ForEach-Object {
    Import-Module $_
}

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' `
                -PSReadlineChordReverseHistory 'Ctrl+r'

# carapace autocomplete
if ($IsLinux) {
    $env:CARAPACE_BRIDGES = 'fish'
}

Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# direnv
Invoke-Expression "$(direnv hook pwsh)"
