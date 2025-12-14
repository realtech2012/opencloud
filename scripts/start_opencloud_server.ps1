param(
    [string]$Image = "opencloud/opencloud:custom",
    [string]$Name = "oc-dev",
    [switch]$Detach
)

Set-StrictMode -Version Latest

$cwd = (Get-Location).Path
$vol = "$cwd\dev-data:/root/.opencloud"
$args = @('run')
if ($Detach) { $args += '-d' } else { $args += '--rm' }
$args += @('--name', $Name, '-v', $vol, '-p', '9200:9200', '-p', '5200:5200', '-p', '9174:9174', $Image, 'server')

Write-Host "Running: docker $($args -join ' ')"
& docker @args
