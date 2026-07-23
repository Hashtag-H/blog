$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot '.baota-deploy.json'
$KeyPath = Join-Path $ProjectRoot '.baota-ssh-key'
$PubKeyPath = "$KeyPath.pub"

function Normalize-Host($HostValue) {
  $text = "$HostValue".Trim()
  $text = $text -replace '^[a-zA-Z][a-zA-Z0-9+.-]*://', ''
  $text = ($text -split '/')[0]
  $text = ($text -split ':')[0]
  return $text.Trim()
}

function Load-Config {
  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw 'No .baota-deploy.json found. Run deploy-baota.bat once and fill config first.'
  }

  $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
  $config.host = Normalize-Host $config.host
  return $config
}

function Invoke-Checked($File, [string[]]$ArgsList) {
  & $File @ArgsList
  if ($LASTEXITCODE -ne 0) {
    throw "$File failed with exit code $LASTEXITCODE"
  }
}

function New-Local-Key {
  if (Test-Path -LiteralPath $KeyPath) {
    Remove-Item -LiteralPath $KeyPath -Force
  }
  if (Test-Path -LiteralPath $PubKeyPath) {
    Remove-Item -LiteralPath $PubKeyPath -Force
  }

  $command = "ssh-keygen.exe -q -t ed25519 -f `"$KeyPath`" -N `"`" -C `"henan-blog-baota-deploy`""
  & cmd.exe /c $command
  if ($LASTEXITCODE -ne 0) {
    throw "ssh-keygen.exe failed with exit code $LASTEXITCODE"
  }

  if (-not (Test-Path -LiteralPath $KeyPath) -or -not (Test-Path -LiteralPath $PubKeyPath)) {
    throw 'SSH key generation did not create expected key files.'
  }
}

$config = Load-Config

Write-Host ''
Write-Host '==== SSH Key Setup ===='
Write-Host "Server: $($config.user)@$($config.host):$($config.port)"
Write-Host 'This setup needs your SSH password once.'
Write-Host 'After it succeeds, deploy-baota.bat should not ask for password again.'
Write-Host ''

if (-not (Test-Path -LiteralPath $KeyPath) -or -not (Test-Path -LiteralPath $PubKeyPath)) {
  Write-Host '[Key] Creating local SSH key...'
  New-Local-Key
} else {
  Write-Host '[Key] Existing local SSH key found.'
}

$publicKey = (Get-Content -LiteralPath $PubKeyPath -Raw).Trim()
$escapedPublicKey = $publicKey.Replace("'", "'\''")
$remote = "$($config.user)@$($config.host)"
$remoteCommand = "umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; grep -qxF '$escapedPublicKey' ~/.ssh/authorized_keys || echo '$escapedPublicKey' >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"

Write-Host ''
Write-Host '[Upload] Installing public key on server...'
Invoke-Checked 'ssh.exe' @('-p', "$($config.port)", $remote, $remoteCommand)

Write-Host ''
Write-Host '[Test] Testing key login...'
Invoke-Checked 'ssh.exe' @('-i', $KeyPath, '-p', "$($config.port)", '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes', $remote, 'echo SSH key login OK')

Write-Host ''
Write-Host '[Done] SSH key login is ready.'
