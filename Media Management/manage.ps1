Param(
  [Parameter(Position=0)] [ValidateSet('start','stop','restart','status','logs','update','urls','clean')] [string]$Command = 'status',
  [Parameter(Position=1)] [string]$Service = '',
  [switch]$VM
)

$ErrorActionPreference = 'Stop'

function Read-DotEnv($path) {
  if (-not (Test-Path $path)) { return @{} }
  $vars = @{}
  Get-Content $path | ForEach-Object {
    if ($_ -match '^[#\s]') { return }
    $k,$v = ($_ -split '=',2)
    if ($k -and $v) { $vars[$k.Trim()] = $v.Trim() }
  }
  return $vars
}

$envFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envFile)) {
  $example = Join-Path $PSScriptRoot '.env.example'
  if (Test-Path $example) { Copy-Item $example $envFile -Force }
}

$envVars = Read-DotEnv $envFile
foreach ($k in $envVars.Keys) { $env:$k = $envVars[$k] }

$compose = if ($VM) { 'docker-compose.vm.yml' } else { 'docker-compose.yml' }
$composePath = Join-Path $PSScriptRoot $compose
if (-not (Test-Path $composePath)) { Write-Error "Compose file not found: $composePath" }

function Invoke-Compose([string[]]$args) {
  $cmd = "docker compose -f `"$composePath`" $args"
  Write-Host "→ $cmd" -ForegroundColor Cyan
  & docker compose -f $composePath @args
}

switch ($Command) {
  'start'   { Invoke-Compose @('up','-d') }
  'stop'    { Invoke-Compose @('down') }
  'restart' { Invoke-Compose @('restart') }
  'status'  { Invoke-Compose @('ps') }
  'logs'    { if ($Service) { Invoke-Compose @('logs','-f',$Service) } else { Invoke-Compose @('logs','-f') } }
  'update'  { Invoke-Compose @('pull'); Invoke-Compose @('up','-d') }
  'clean'   { docker system prune -f }
  'urls'    {
    Write-Host 'Service URLs:' -ForegroundColor Cyan
    $map = @{
      'Prowlarr'='PROWLARR_PORT'; 'Sonarr'='SONARR_PORT'; 'Radarr'='RADARR_PORT';
      'Lidarr'='LIDARR_PORT'; 'Readarr'='READARR_PORT'; 'qBittorrent'='QBITTORRENT_PORT';
      'NZBGet'='NZBGET_PORT'; 'Bazarr'='BAZARR_PORT'; 'Jellyseerr'='JELLYSEERR_PORT';
      'Notifiarr'='NOTIFIARR_PORT'; 'Flaresolverr'='FLARESOLVERR_PORT'
    }
    foreach ($k in $map.Keys) {
      $port = $env:$($map[$k])
      if (-not $port) { $port = 'n/a' }
      Write-Host ("{0,-12} http://localhost:{1}" -f $k,$port)
    }
  }
}
