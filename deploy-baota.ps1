$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ProjectRoot '.baota-deploy.json'
$ManifestPath = Join-Path $ProjectRoot '.baota-manifest.json'
$ArchivePath = Join-Path $ProjectRoot 'baota-upload.tar.gz'
$StagingDir = Join-Path $ProjectRoot '.baota-staging'
$RemoteArchive = '/tmp/henan-blog-upload.tar.gz'
$PublicDir = Join-Path $ProjectRoot 'public'
$DeleteListName = '.deploy-delete-list.txt'
$SshKeyPath = Join-Path $ProjectRoot '.baota-ssh-key'

function Write-Title($Text) {
  Write-Host ''
  Write-Host "==== $Text ===="
}

function Read-Required($Prompt, $Default = '') {
  while ($true) {
    if ($Default) {
      $value = Read-Host "$Prompt [$Default]"
      if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
    } else {
      $value = Read-Host $Prompt
    }

    $value = "$value".Trim()
    if (-not [string]::IsNullOrWhiteSpace($value)) { return $value }
  }
}

function Normalize-Host($HostValue) {
  $text = "$HostValue".Trim()
  $text = $text -replace '^[a-zA-Z][a-zA-Z0-9+.-]*://', ''
  $text = ($text -split '/')[0]
  $text = ($text -split ':')[0]
  return $text.Trim()
}

function Normalize-SiteRoot($SiteRootValue) {
  $text = "$SiteRootValue".Trim()
  $text = $text -replace '\\', '/'
  $text = $text -replace '/+$', ''
  return $text.Trim()
}

function Assert-Deploy-Config($Config) {
  if ([string]::IsNullOrWhiteSpace($Config.host)) {
    throw 'Server host is empty.'
  }

  if ($Config.host -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
    throw 'Server host must not include http:// or https://.'
  }

  if ($Config.port -lt 1 -or $Config.port -gt 65535) {
    throw 'SSH port must be between 1 and 65535.'
  }

  if ([string]::IsNullOrWhiteSpace($Config.user)) {
    throw 'SSH user is empty.'
  }

  if ($Config.siteRoot -notlike '/www/wwwroot/*') {
    throw 'Baota site root must look like /www/wwwroot/blog. This prevents deleting a wrong directory.'
  }

  if ($Config.siteRoot -match '\s') {
    throw 'Baota site root must not contain spaces.'
  }
}

function Save-Config($Config) {
  $Config | ConvertTo-Json | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
  Write-Host ''
  Write-Host "Config saved: $ConfigPath"
}

function New-Config {
  Write-Title 'Deploy Config'
  Write-Host 'Fill SSH server info, not Baota panel login info.'
  Write-Host ''
  Write-Host 'Examples:'
  Write-Host 'Server host: 1.94.44.18'
  Write-Host 'SSH port:    22'
  Write-Host 'SSH user:    root'
  Write-Host 'Site root:   /www/wwwroot/blog'
  Write-Host ''

  $config = [ordered]@{
    host = Normalize-Host (Read-Required 'Server host or IP, no http://')
    port = [int](Read-Required 'SSH port, not Baota panel port' '22')
    user = Read-Required 'SSH user' 'root'
    siteRoot = Normalize-SiteRoot (Read-Required 'Baota site root' '/www/wwwroot/blog')
  }

  $configObject = [pscustomobject]$config
  Assert-Deploy-Config $configObject
  Save-Config $config
  return $configObject
}

function Load-Config {
  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    return New-Config
  }

  $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
  $config.host = Normalize-Host $config.host
  $config.siteRoot = Normalize-SiteRoot $config.siteRoot
  Assert-Deploy-Config $config
  return $config
}

function Reset-Config {
  if (Test-Path -LiteralPath $ConfigPath) {
    Remove-Item -LiteralPath $ConfigPath -Force
  }
  return New-Config
}

function Invoke-Checked($File, [string[]]$ArgsList) {
  & $File @ArgsList
  if ($LASTEXITCODE -ne 0) {
    throw "$File failed with exit code $LASTEXITCODE"
  }
}

function Show-Config($Config) {
  Write-Title 'Current Config'
  Write-Host "Server:   $($Config.host)"
  Write-Host "SSH port: $($Config.port)"
  Write-Host "SSH user: $($Config.user)"
  Write-Host "SiteRoot: $($Config.siteRoot)"
  Write-Host ''
}

function Confirm-Deploy($Config, $Mode) {
  Show-Config $Config
  Write-Host "Deploy mode: $Mode"
  Write-Host 'Remote .user.ini will be kept.'

  if ($Mode -eq 'full') {
    Write-Host 'Full mode will clear remote SiteRoot except .user.ini, then upload all public files.'
  } else {
    Write-Host 'Incremental mode uploads only changed files and removes deleted files.'
  }

  Write-Host ''
  $confirm = Read-Host 'Type YES to deploy'
  return $confirm -eq 'YES'
}

function Get-RelativePath($BaseDir, $FullPath) {
  $base = (Resolve-Path -LiteralPath $BaseDir).Path.TrimEnd('\') + '\'
  return $FullPath.Substring($base.Length).Replace('\', '/')
}

function Build-Manifest {
  if (-not (Test-Path -LiteralPath $PublicDir)) {
    throw 'public directory does not exist. Run hexo generate first.'
  }

  $manifest = @{}
  Get-ChildItem -LiteralPath $PublicDir -Recurse -File | ForEach-Object {
    $relative = Get-RelativePath $PublicDir $_.FullName
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    $manifest[$relative] = [pscustomobject]@{
      path = $relative
      hash = $hash
      length = $_.Length
    }
  }
  return $manifest
}

function Load-Manifest {
  $manifest = @{}
  if (-not (Test-Path -LiteralPath $ManifestPath)) {
    return $manifest
  }

  $items = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
  foreach ($item in $items) {
    $manifest[$item.path] = $item
  }
  return $manifest
}

function Save-Manifest($Manifest) {
  $items = foreach ($key in ($Manifest.Keys | Sort-Object)) {
    $Manifest[$key]
  }
  $items | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
  Write-Host "Manifest saved: $ManifestPath"
}

function Reset-Staging {
  if (Test-Path -LiteralPath $StagingDir) {
    Remove-Item -LiteralPath $StagingDir -Recurse -Force
  }
  New-Item -ItemType Directory -Path $StagingDir | Out-Null
}

function Copy-PublicFileToStaging($RelativePath) {
  $source = Join-Path $PublicDir ($RelativePath -replace '/', '\')
  $target = Join-Path $StagingDir ($RelativePath -replace '/', '\')
  $targetDir = Split-Path -Parent $target

  if (-not (Test-Path -LiteralPath $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  }

  Copy-Item -LiteralPath $source -Destination $target -Force
}

function Build-Incremental-Package($CurrentManifest, $PreviousManifest) {
  Reset-Staging

  $changed = New-Object System.Collections.Generic.List[string]
  $deleted = New-Object System.Collections.Generic.List[string]

  foreach ($path in ($CurrentManifest.Keys | Sort-Object)) {
    if (-not $PreviousManifest.ContainsKey($path) -or $PreviousManifest[$path].hash -ne $CurrentManifest[$path].hash) {
      $changed.Add($path)
      Copy-PublicFileToStaging $path
    }
  }

  foreach ($path in ($PreviousManifest.Keys | Sort-Object)) {
    if (-not $CurrentManifest.ContainsKey($path)) {
      $deleted.Add($path)
    }
  }

  $deleteListPath = Join-Path $StagingDir $DeleteListName
  $deleted | Set-Content -LiteralPath $deleteListPath -Encoding UTF8

  return [pscustomobject]@{
    changed = $changed
    deleted = $deleted
    packageDir = $StagingDir
  }
}

function Pack-Directory($Directory) {
  if (Test-Path -LiteralPath $ArchivePath) {
    Remove-Item -LiteralPath $ArchivePath -Force
  }

  Invoke-Checked 'tar.exe' @('-czf', $ArchivePath, '-C', $Directory, '.')
  $sizeMb = [math]::Round((Get-Item -LiteralPath $ArchivePath).Length / 1MB, 2)
  Write-Host "Package: $ArchivePath ($sizeMb MB)"
}

function Upload-Archive($Config) {
  $remote = "$($Config.user)@$($Config.host)"
  $args = @('-P', "$($Config.port)")
  if (Test-Path -LiteralPath $SshKeyPath) {
    $args += @('-i', $SshKeyPath, '-o', 'IdentitiesOnly=yes')
  }
  $args += @($ArchivePath, "${remote}:$RemoteArchive")
  Invoke-Checked 'scp.exe' $args
  return $remote
}

function Run-Remote-Full($Config, $Remote) {
  $remoteCommand = @"
set -e
mkdir -p '$($Config.siteRoot)'
find '$($Config.siteRoot)' -mindepth 1 -maxdepth 1 ! -name '.user.ini' -exec rm -rf -- {} +
tar -xzf '$RemoteArchive' -C '$($Config.siteRoot)'
rm -f '$RemoteArchive'
echo Full deploy finished: '$($Config.siteRoot)'
"@

  $args = @('-p', "$($Config.port)")
  if (Test-Path -LiteralPath $SshKeyPath) {
    $args += @('-i', $SshKeyPath, '-o', 'IdentitiesOnly=yes')
  }
  $args += @($Remote, $remoteCommand)
  Invoke-Checked 'ssh.exe' $args
}

function Run-Remote-Incremental($Config, $Remote) {
  $remoteCommand = @"
set -e
SITE='$($Config.siteRoot)'
TMP=`$(mktemp -d /tmp/henan-blog.XXXXXX)
mkdir -p "`$SITE"
tar -xzf '$RemoteArchive' -C "`$TMP"
if [ -f "`$TMP/$DeleteListName" ]; then
  while IFS= read -r rel || [ -n "`$rel" ]; do
    case "`$rel" in
      ''|.*|/*|*'..'*) continue ;;
    esac
    rm -rf -- "`$SITE/`$rel"
  done < "`$TMP/$DeleteListName"
  rm -f "`$TMP/$DeleteListName"
fi
tar -C "`$TMP" -cf - . | tar -C "`$SITE" -xf -
rm -rf "`$TMP" '$RemoteArchive'
echo Incremental deploy finished: "`$SITE"
"@

  $args = @('-p', "$($Config.port)")
  if (Test-Path -LiteralPath $SshKeyPath) {
    $args += @('-i', $SshKeyPath, '-o', 'IdentitiesOnly=yes')
  }
  $args += @($Remote, $remoteCommand)
  Invoke-Checked 'ssh.exe' $args
}

function Deploy($Config, $Mode) {
  Set-Location -LiteralPath $ProjectRoot

  Write-Title 'Sync Typora assets'
  Invoke-Checked 'powershell' @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '.\sync-typora-assets.ps1')

  Write-Title 'Hexo Generate'
  Invoke-Checked '.\node_modules\.bin\hexo.cmd' @('generate')

  $currentManifest = Build-Manifest

  if ($Mode -eq 'incremental') {
    $previousManifest = Load-Manifest
    if ($previousManifest.Count -eq 0) {
      Write-Host 'No previous manifest. Switching to full deploy for the first baseline.'
      $Mode = 'full'
    }
  }

  if ($Mode -eq 'full') {
    Write-Title 'Pack full public'
    Pack-Directory $PublicDir

    Write-Title 'Upload'
    $remote = Upload-Archive $Config

    Write-Title 'Remote full deploy'
    Run-Remote-Full $Config $remote
  } else {
    Write-Title 'Build incremental package'
    $previousManifest = Load-Manifest
    $delta = Build-Incremental-Package $currentManifest $previousManifest
    Write-Host "Changed files: $($delta.changed.Count)"
    Write-Host "Deleted files: $($delta.deleted.Count)"

    if ($delta.changed.Count -eq 0 -and $delta.deleted.Count -eq 0) {
      Write-Host 'No changes to deploy.'
      return
    }

    Pack-Directory $delta.packageDir

    Write-Title 'Upload'
    $remote = Upload-Archive $Config

    Write-Title 'Remote incremental deploy'
    Run-Remote-Incremental $Config $remote
  }

  Save-Manifest $currentManifest

  Write-Title 'Done'
  Write-Host 'Deploy completed. Open your domain to check the latest blog.'
}

Set-Location -LiteralPath $ProjectRoot

Write-Title 'Baota Deploy'
Write-Host '1. Incremental deploy (recommended)'
Write-Host '2. Full deploy'
Write-Host '3. Reset config and incremental deploy'
Write-Host '4. Show current config'
Write-Host '0. Exit'
Write-Host ''

$choice = Read-Host 'Choose'

switch ($choice) {
  '1' {
    $config = Load-Config
    if (Confirm-Deploy $config 'incremental') {
      Deploy $config 'incremental'
    } else {
      Write-Host 'Deploy canceled.'
    }
  }
  '2' {
    $config = Load-Config
    if (Confirm-Deploy $config 'full') {
      Deploy $config 'full'
    } else {
      Write-Host 'Deploy canceled.'
    }
  }
  '3' {
    $config = Reset-Config
    if (Confirm-Deploy $config 'incremental') {
      Deploy $config 'incremental'
    } else {
      Write-Host 'Config saved, deploy canceled.'
    }
  }
  '4' {
    $config = Load-Config
    Show-Config $config
  }
  '0' {
    Write-Host 'Exit.'
  }
  default {
    Write-Host 'Invalid choice.'
    exit 1
  }
}
