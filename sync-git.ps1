param(
  [string]$RemoteUrl = 'https://github.com/Hashtag-H/blog.git',
  [string]$Branch = 'main',
  [string]$Message = ''
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
  return $code
}

function Test-GitOk([string[]]$Arguments) {
  & git @Arguments *> $null
  return $LASTEXITCODE -eq 0
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
  Invoke-Git @('checkout', $Branch) -AllowFailure | Out-Null
  if ($LASTEXITCODE -ne 0) {
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

$hasHead = Test-GitOk @('rev-parse', '--verify', 'HEAD')
$remoteBranchExists = Test-GitOk @('ls-remote', '--exit-code', '--heads', 'origin', $Branch)

if ($hasHead -and $remoteBranchExists) {
  Write-Host 'Pulling latest remote changes with autostash...'
  Invoke-Git @('pull', '--rebase', '--autostash', 'origin', $Branch)
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

Write-Host 'Pushing to GitHub...'
Invoke-Git @('push', '-u', 'origin', $Branch)

Write-Host 'Git sync finished.'
