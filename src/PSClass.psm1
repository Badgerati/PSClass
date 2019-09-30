$ErrorActionPreference = 'Stop'

# load private/public functions
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path

@('Private', 'Public') | ForEach-Object {
    $path = (Join-Path (Join-Path $root $_) "*.ps1")
    Get-ChildItem $path | Resolve-Path | ForEach-Object { . $_ }
}

# export the functions
$path = (Join-Path (Join-Path $root 'Public') "*.ps1")
$functions = @(Get-ChildItem -Path $path).BaseName
Export-ModuleMember -Function $functions