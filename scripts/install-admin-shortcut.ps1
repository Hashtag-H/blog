$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$target = Join-Path $repoRoot "scripts\open-admin-app.cmd"
$icon = Join-Path $repoRoot "frontend\public\favicon.ico"
$desktop = [Environment]::GetFolderPath("Desktop")

$shortcutName = "$([char]0x6CB3)$([char]0x5357)$([char]0x5A03)$([char]0x7684)$([char]0x5C0F)$([char]0x7A9D)$([char]0x540E)$([char]0x53F0).lnk"
$shortcutPath = Join-Path $desktop $shortcutName

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $repoRoot
$shortcut.Description = "Open local blog admin app"
if (Test-Path -LiteralPath $icon) {
  $shortcut.IconLocation = $icon
}
$shortcut.Save()

Write-Host "Created desktop shortcut: $shortcutPath"
