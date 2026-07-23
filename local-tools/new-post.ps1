param(
  [string]$Title = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$posts = Join-Path $root 'source\_posts'
New-Item -ItemType Directory -Force -Path $posts | Out-Null

if (-not $Title) {
  $Title = Read-Host 'Post title'
}

if (-not $Title) {
  Write-Host 'Title is required.' -ForegroundColor Red
  exit 1
}

function Convert-ToSlug {
  param([string]$Value)
  $slug = $Value.ToLowerInvariant()
  $slug = $slug -replace '[\\/:*?"<>|]+', '-'
  $slug = $slug -replace '\s+', '-'
  $slug = $slug.Trim('-')
  if (-not $slug) {
    $slug = Get-Date -Format 'yyyyMMdd-HHmmss'
  }
  return $slug
}

$date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$defaultCategory = "$([char]0x968F)$([char]0x7B14)"
$defaultBody = "$([char]0x4ECE)$([char]0x8FD9)$([char]0x91CC)$([char]0x5F00)$([char]0x59CB)$([char]0x5199)$([char]0x6B63)$([char]0x6587)$([char]0x3002)"
$slug = Convert-ToSlug $Title
$path = Join-Path $posts "$slug.md"
$counter = 2
while (Test-Path -LiteralPath $path) {
  $path = Join-Path $posts "$slug-$counter.md"
  $counter += 1
}

$lines = @(
  '---',
  "title: ""$Title""",
  "date: ""$date""",
  "updated: ""$date""",
  "categories: [""$defaultCategory""]",
  'tags: []',
  'description: ""',
  'cover: "/images/henan-wheatfield-bg.png"',
  'top_img: "/images/henan-wheatfield-bg.png"',
  'sticky: 0',
  'top: false',
  '---',
  '',
  $defaultBody
)

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($path, $lines, $utf8)
Write-Host "Created: $path"
