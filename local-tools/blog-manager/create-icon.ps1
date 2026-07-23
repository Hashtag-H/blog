param(
  [string]$OutFile = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\BlogManager.ico"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function New-IconBitmap {
  param([int]$Size)

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $scale = $Size / 256.0
  function S([float]$v) { return [int][Math]::Round($v * $scale) }

  $rect = New-Object System.Drawing.Rectangle (S 18), (S 18), (S 220), (S 220)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r = S 52
  $d = $r * 2
  $path.AddArc($rect.Left, $rect.Top, $d, $d, 180, 90)
  $path.AddArc($rect.Right - $d, $rect.Top, $d, $d, 270, 90)
  $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
  $path.AddArc($rect.Left, $rect.Bottom - $d, $d, $d, 90, 90)
  $path.CloseFigure()

  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(71,119,91)), ([System.Drawing.Color]::FromArgb(185,137,65)), 45
  $g.FillPath($bg, $path)
  $bg.Dispose()

  $field1 = @(
    (New-Object System.Drawing.Point (S 58), (S 177)),
    (New-Object System.Drawing.Point (S 108), (S 151)),
    (New-Object System.Drawing.Point (S 181), (S 143)),
    (New-Object System.Drawing.Point (S 238), (S 151)),
    (New-Object System.Drawing.Point (S 238), (S 238)),
    (New-Object System.Drawing.Point (S 58), (S 238))
  )
  $fieldBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(205,216,179,101))
  $g.FillPolygon($fieldBrush, $field1)
  $fieldBrush.Dispose()

  $field2 = @(
    (New-Object System.Drawing.Point (S 52), (S 198)),
    (New-Object System.Drawing.Point (S 117), (S 166)),
    (New-Object System.Drawing.Point (S 178), (S 161)),
    (New-Object System.Drawing.Point (S 238), (S 171)),
    (New-Object System.Drawing.Point (S 238), (S 238)),
    (New-Object System.Drawing.Point (S 52), (S 238))
  )
  $fieldBrush2 = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(165,244,209,130))
  $g.FillPolygon($fieldBrush2, $field2)
  $fieldBrush2.Dispose()

  $pageRect = New-Object System.Drawing.Rectangle (S 72), (S 56), (S 108), (S 136)
  $pagePath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $pr = S 18
  $pd = $pr * 2
  $pagePath.AddArc($pageRect.Left, $pageRect.Top, $pd, $pd, 180, 90)
  $pagePath.AddArc($pageRect.Right - $pd, $pageRect.Top, $pd, $pd, 270, 90)
  $pagePath.AddArc($pageRect.Right - $pd, $pageRect.Bottom - $pd, $pd, $pd, 0, 90)
  $pagePath.AddArc($pageRect.Left, $pageRect.Bottom - $pd, $pd, $pd, 90, 90)
  $pagePath.CloseFigure()
  $pageBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $pageRect, ([System.Drawing.Color]::FromArgb(255,253,246)), ([System.Drawing.Color]::FromArgb(238,243,232)), 90
  $g.FillPath($pageBrush, $pagePath)
  $pageBrush.Dispose()

  $linePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(71,119,91)), (S 13)
  $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawLine($linePen, (S 98), (S 92), (S 153), (S 92))
  $g.DrawLine($linePen, (S 98), (S 119), (S 153), (S 119))
  $g.DrawLine($linePen, (S 98), (S 146), (S 137), (S 146))
  $linePen.Dispose()

  $foldPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(245,255,253,246)), (S 10)
  $foldPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $foldPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawLine($foldPen, (S 174), (S 58), (S 174), (S 89))
  $g.DrawLine($foldPen, (S 174), (S 89), (S 205), (S 89))
  $foldPen.Dispose()

  $circleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255,253,246))
  $g.FillEllipse($circleBrush, (S 145), (S 143), (S 68), (S 68))
  $circleBrush.Dispose()

  $plusPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(71,119,91)), (S 12)
  $plusPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $plusPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawLine($plusPen, (S 179), (S 159), (S 179), (S 195))
  $g.DrawLine($plusPen, (S 161), (S 177), (S 197), (S 177))
  $plusPen.Dispose()

  $g.Dispose()
  return $bmp
}

function Get-DibBytes {
  param([System.Drawing.Bitmap]$Bitmap)
  $width = $Bitmap.Width
  $height = $Bitmap.Height
  $maskStride = [int]([Math]::Floor(($width + 31) / 32)) * 4
  $xorSize = $width * $height * 4
  $andSize = $maskStride * $height

  $ms = New-Object System.IO.MemoryStream
  $writer = New-Object System.IO.BinaryWriter $ms
  $writer.Write([UInt32]40)
  $writer.Write([Int32]$width)
  $writer.Write([Int32]($height * 2))
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]32)
  $writer.Write([UInt32]0)
  $writer.Write([UInt32]($xorSize + $andSize))
  $writer.Write([Int32]0)
  $writer.Write([Int32]0)
  $writer.Write([UInt32]0)
  $writer.Write([UInt32]0)

  for ($y = $height - 1; $y -ge 0; $y--) {
    for ($x = 0; $x -lt $width; $x++) {
      $pixel = $Bitmap.GetPixel($x, $y)
      $writer.Write([byte]$pixel.B)
      $writer.Write([byte]$pixel.G)
      $writer.Write([byte]$pixel.R)
      $writer.Write([byte]$pixel.A)
    }
  }

  for ($i = 0; $i -lt $andSize; $i++) {
    $writer.Write([byte]0)
  }

  $bytes = $ms.ToArray()
  $writer.Close()
  $ms.Dispose()
  return $bytes
}

$sizes = @(16, 24, 32, 48, 64, 128)
$images = @()
foreach ($size in $sizes) {
  $bitmap = New-IconBitmap $size
  [byte[]]$bytes = Get-DibBytes $bitmap
  $images += [pscustomobject]@{ Size = $size; Bytes = $bytes }
  $bitmap.Dispose()
}

$fs = [System.IO.File]::Create($OutFile)
$writer = New-Object System.IO.BinaryWriter $fs
$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]$images.Count)
$offset = 6 + ($images.Count * 16)

foreach ($image in $images) {
  $iconSize = $image.Size
  if ($iconSize -eq 256) {
    $iconSize = 0
  }
  $writer.Write([byte]$iconSize)
  $writer.Write([byte]$iconSize)
  $writer.Write([byte]0)
  $writer.Write([byte]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]32)
  $writer.Write([UInt32]$image.Bytes.Length)
  $writer.Write([UInt32]$offset)
  $offset += $image.Bytes.Length
}

foreach ($image in $images) {
  $writer.Write($image.Bytes)
}

$writer.Close()
$fs.Close()
Write-Host "Created icon: $OutFile"
