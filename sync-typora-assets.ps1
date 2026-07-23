$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PostsDir = Join-Path $ProjectRoot 'source\_posts'
$StaticPostsDir = Join-Path $ProjectRoot 'source\posts'
$SourceDir = Join-Path $ProjectRoot 'source'

function Ensure-Inside($BasePath, $TargetPath) {
  $base = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\'
  $target = [System.IO.Path]::GetFullPath($TargetPath)
  if (-not $target.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside $base"
  }
}

if (-not (Test-Path -LiteralPath $PostsDir)) {
  Write-Host '[Assets] No source/_posts directory found.'
  exit 0
}

if (-not (Test-Path -LiteralPath $StaticPostsDir)) {
  New-Item -ItemType Directory -Path $StaticPostsDir | Out-Null
}

$assetDirs = Get-ChildItem -LiteralPath $PostsDir -Directory -Filter '*.assets' -ErrorAction SilentlyContinue

if (-not $assetDirs -or $assetDirs.Count -eq 0) {
  Write-Host '[Assets] No Typora .assets folders to sync.'
  exit 0
}

$count = 0
foreach ($assetDir in $assetDirs) {
  $slug = $assetDir.Name -replace '\.assets$', ''
  $postTargetDir = Join-Path $StaticPostsDir (Join-Path $slug $assetDir.Name)
  $rootTargetDir = Join-Path $SourceDir $assetDir.Name

  Ensure-Inside $StaticPostsDir $postTargetDir
  Ensure-Inside $SourceDir $rootTargetDir

  if (Test-Path -LiteralPath $postTargetDir) {
    Remove-Item -LiteralPath $postTargetDir -Recurse -Force
  }

  if (Test-Path -LiteralPath $rootTargetDir) {
    Remove-Item -LiteralPath $rootTargetDir -Recurse -Force
  }

  New-Item -ItemType Directory -Path (Split-Path -Parent $postTargetDir) -Force | Out-Null
  Copy-Item -LiteralPath $assetDir.FullName -Destination $postTargetDir -Recurse -Force
  Copy-Item -LiteralPath $assetDir.FullName -Destination $rootTargetDir -Recurse -Force

  $fileCount = (Get-ChildItem -LiteralPath $assetDir.FullName -Recurse -File | Measure-Object).Count
  $count += $fileCount
  Write-Host "[Assets] Synced $($assetDir.Name) -> source/posts/$slug/$($assetDir.Name) and source/$($assetDir.Name) ($fileCount files)"
}

Write-Host "[Assets] Done. Synced $count files."
