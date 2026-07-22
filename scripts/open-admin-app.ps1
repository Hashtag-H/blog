param(
  [string]$Url = "http://localhost:8088/admin",
  [int]$WaitSeconds = 90
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$programFiles = [Environment]::GetFolderPath("ProgramFiles")
$programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")

function Test-CommandAvailable {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Wait-ForDocker {
  param([int]$TimeoutSeconds)

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      docker info *> $null
      return $true
    } catch {
      Start-Sleep -Seconds 2
    }
  }

  return $false
}

function Open-DockerDesktop {
  $candidates = @(
    "D:\docker\Docker Desktop.exe",
    (Join-Path $programFiles "Docker\Docker\Docker Desktop.exe"),
    (Join-Path $programFilesX86 "Docker\Docker\Docker Desktop.exe")
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      Start-Process -FilePath $candidate -WindowStyle Hidden
      return $true
    }
  }

  return $false
}

function Wait-ForHttp {
  param(
    [string]$TargetUrl,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri $TargetUrl -TimeoutSec 5
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return $true
      }
    } catch {
      Start-Sleep -Seconds 2
    }
  }

  return $false
}

function Find-AppBrowser {
  $commands = @("msedge", "chrome")
  foreach ($command in $commands) {
    $found = Get-Command $command -ErrorAction SilentlyContinue
    if ($found) {
      return $found.Source
    }
  }

  $paths = @(
    (Join-Path $programFiles "Microsoft\Edge\Application\msedge.exe"),
    (Join-Path $programFilesX86 "Microsoft\Edge\Application\msedge.exe"),
    (Join-Path $programFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path $programFilesX86 "Google\Chrome\Application\chrome.exe")
  )

  foreach ($path in $paths) {
    if ($path -and (Test-Path -LiteralPath $path)) {
      return $path
    }
  }

  return $null
}

Set-Location -LiteralPath $repoRoot

if (-not (Test-CommandAvailable "docker")) {
  Write-Host "Docker command was not found. Please install or start Docker Desktop first." -ForegroundColor Red
  Start-Sleep -Seconds 4
  exit 1
}

try {
  docker info *> $null
} catch {
  Open-DockerDesktop | Out-Null
  if (-not (Wait-ForDocker -TimeoutSeconds 90)) {
    Write-Host "Docker Desktop did not become ready in time. Start Docker manually, then try again." -ForegroundColor Red
    Start-Sleep -Seconds 4
    exit 1
  }
}

docker compose --env-file .env up -d | Out-Host

if (-not (Wait-ForHttp -TargetUrl $Url -TimeoutSeconds $WaitSeconds)) {
  Write-Host "The admin service did not respond in time. Please check the Docker container status." -ForegroundColor Red
  Start-Sleep -Seconds 4
  exit 1
}

$browser = Find-AppBrowser
if ($browser) {
  Start-Process -FilePath $browser -ArgumentList @("--app=$Url", "--new-window")
} else {
  Start-Process $Url
}
