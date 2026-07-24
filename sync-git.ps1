param(
  [string]$RemoteUrl = 'https://github.com/Hashtag-H/blog.git',
  [string]$Branch = 'main',
  [string]$Message = '',
  [ValidateSet('Auto', 'Direct', 'Proxy')]
  [string]$ProxyMode = 'Auto',
  [string[]]$Proxy = @(),
  [switch]$DryRun,
  [switch]$WhatIf,
  [switch]$FailOnOffline
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $ProjectRoot

function Write-Title($Text) {
  Write-Host ''
  Write-Host "==== $Text ===="
}

function Invoke-Git([string[]]$Arguments, [switch]$AllowFailure) {
  & git @Arguments
  $code = $LASTEXITCODE
  if ($code -ne 0 -and -not $AllowFailure) {
    throw "git $($Arguments -join ' ') failed with exit code $code"
  }
  if ($AllowFailure) {
    return $code
  }
}

function Test-GitOk([string[]]$Arguments) {
  & git @Arguments *> $null
  return $LASTEXITCODE -eq 0
}

function Normalize-Proxy($Value) {
  $text = "$Value".Trim()
  if ([string]::IsNullOrWhiteSpace($text)) {
    return ''
  }
  if ($text -match '^(http|https|socks5)://') {
    return $text
  }
  return "http://$text"
}

function Add-ProxyCandidate([System.Collections.Generic.List[string]]$List, [string]$Value) {
  $proxyValue = Normalize-Proxy $Value
  if (-not $List.Contains($proxyValue)) {
    $List.Add($proxyValue) | Out-Null
  }
}

function Get-WindowsProxyCandidates {
  $items = @()
  try {
    $settings = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
    if ($settings.ProxyEnable -eq 1 -and -not [string]::IsNullOrWhiteSpace($settings.ProxyServer)) {
      foreach ($part in ("$($settings.ProxyServer)" -split ';')) {
        $value = $part
        if ($value -match '=') {
          $value = ($value -split '=', 2)[1]
        }
        if (-not [string]::IsNullOrWhiteSpace($value)) {
          $items += $value
        }
      }
    }
  } catch {
  }
  return $items
}

function Get-ProxyCandidates {
  $candidates = New-Object 'System.Collections.Generic.List[string]'

  if ($ProxyMode -ne 'Proxy') {
    Add-ProxyCandidate $candidates ''
  }

  if ($ProxyMode -ne 'Direct') {
    foreach ($item in $Proxy) {
      Add-ProxyCandidate $candidates $item
    }

    foreach ($name in @('HTTPS_PROXY', 'HTTP_PROXY', 'ALL_PROXY', 'https_proxy', 'http_proxy', 'all_proxy')) {
      $value = [Environment]::GetEnvironmentVariable($name)
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        Add-ProxyCandidate $candidates $value
      }
    }

    foreach ($item in Get-WindowsProxyCandidates) {
      Add-ProxyCandidate $candidates $item
    }

    foreach ($port in @(7890, 7897, 7899, 10809, 10808, 1080, 20171, 2080)) {
      Add-ProxyCandidate $candidates "127.0.0.1:$port"
      Add-ProxyCandidate $candidates "localhost:$port"
    }
  }

  return @($candidates)
}

function Get-GitProxyArguments($ProxyValue) {
  if ([string]::IsNullOrWhiteSpace($ProxyValue)) {
    return @('-c', 'http.proxy=', '-c', 'https.proxy=')
  }
  return @('-c', "http.proxy=$ProxyValue", '-c', "https.proxy=$ProxyValue")
}

function Invoke-GitNetwork([string[]]$Arguments, [string]$Title, [int]$RetriesPerRoute = 2) {
  $routes = Get-ProxyCandidates
  $lastCode = 1

  foreach ($route in $routes) {
    $routeName = if ([string]::IsNullOrWhiteSpace($route)) { 'direct' } else { $route }
    for ($attempt = 1; $attempt -le $RetriesPerRoute; $attempt++) {
      Write-Host "$Title via $routeName ($attempt/$RetriesPerRoute)"
      $proxyArgs = Get-GitProxyArguments $route
      & git @proxyArgs @Arguments
      $lastCode = $LASTEXITCODE
      if ($lastCode -eq 0) {
        return $true
      }

      if ($attempt -lt $RetriesPerRoute) {
        Start-Sleep -Seconds 4
      }
    }
  }

  return $false
}

function Warn-Or-ThrowOffline($MessageText) {
  Write-Host ''
  Write-Host "[Warn] $MessageText"
  Write-Host '[Warn] Local commit is kept. Run sync-git.bat again after the network or proxy is available.'
  if ($FailOnOffline) {
    throw $MessageText
  }
}

Write-Title 'Git Sync'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Git is not installed or is not available in PATH.'
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) {
  Write-Host 'No .git directory found. Initializing repository...'
  Invoke-Git @('init')
}

$currentBranch = (& git branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
  Invoke-Git @('checkout', '-B', $Branch)
} elseif ($currentBranch -ne $Branch) {
  $checkoutCode = Invoke-Git @('checkout', $Branch) -AllowFailure
  if ($checkoutCode -ne 0) {
    Invoke-Git @('checkout', '-B', $Branch)
  }
}

$origin = (& git remote get-url origin 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($origin)) {
  Invoke-Git @('remote', 'add', 'origin', $RemoteUrl)
} elseif ($origin.Trim() -ne $RemoteUrl) {
  Write-Host "Updating origin remote: $RemoteUrl"
  Invoke-Git @('remote', 'set-url', 'origin', $RemoteUrl)
}

Write-Host "Remote: $RemoteUrl"
Write-Host "Branch: $Branch"
Write-Host "Proxy mode: $ProxyMode"

Invoke-Git @('config', '--local', 'http.version', 'HTTP/1.1')

if ($DryRun -or $WhatIf) {
  Write-Host 'Dry run only. These changes would be committed:'
  & git status --short
  Write-Host 'Dry run only. Network sync skipped.'
  return
}

Invoke-Git @('add', '-A')

$changes = (& git status --porcelain)
if ([string]::IsNullOrWhiteSpace(($changes -join "`n"))) {
  Write-Host 'No local changes to commit.'
} else {
  if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = 'chore: sync blog ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  }
  Write-Host "Committing changes: $Message"
  Invoke-Git @('commit', '-m', $Message)
}

$hasHead = Test-GitOk @('rev-parse', '--verify', 'HEAD')
if (-not $hasHead) {
  Warn-Or-ThrowOffline 'No local commit exists yet.'
  return
}

$remoteOk = Invoke-GitNetwork @('ls-remote', '--exit-code', '--heads', 'origin', $Branch) 'Checking remote'
if (-not $remoteOk) {
  Warn-Or-ThrowOffline 'Cannot connect to GitHub through direct connection or detected local proxies.'
  return
}

$pullOk = Invoke-GitNetwork @('pull', '--rebase', '--autostash', 'origin', $Branch) 'Pulling latest remote changes'
if (-not $pullOk) {
  Warn-Or-ThrowOffline 'Cannot pull from GitHub right now.'
  return
}

$pushOk = Invoke-GitNetwork @('push', '-u', 'origin', $Branch) 'Pushing to GitHub'
if (-not $pushOk) {
  Warn-Or-ThrowOffline 'Cannot push to GitHub right now.'
  return
}

Write-Host 'Git sync finished.'
