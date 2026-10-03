$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assetRoot = $PSScriptRoot
$manifest = @()
foreach ($device in @('iphone-6.5', 'ipad-13')) {
  $files = Get-ChildItem -LiteralPath (Join-Path $assetRoot $device) -Filter '*.png' | Sort-Object Name
  foreach ($file in $files) {
    $source = [System.Drawing.Image]::FromFile($file.FullName)
    $rgb = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($rgb)
    $graphics.DrawImageUnscaled($source, 0, 0)
    $source.Dispose()
    $graphics.Dispose()
    $rgb.Save($file.FullName, [System.Drawing.Imaging.ImageFormat]::Png)
    $manifest += [PSCustomObject]@{file="$device/$($file.Name)";width=$rgb.Width;height=$rgb.Height;format='RGB PNG, no alpha';sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
    $rgb.Dispose()
  }
  $thumbWidth = if ($device -eq 'iphone-6.5') {310} else {420}
  $thumbHeight = if ($device -eq 'iphone-6.5') {671} else {560}
  $sheet = [System.Drawing.Bitmap]::new(($thumbWidth*4+60),($thumbHeight+24),[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($sheet)
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#e7e8df'))
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  for ($i=0; $i -lt $files.Count; $i++) {
    $img=[System.Drawing.Image]::FromFile($files[$i].FullName)
    $g.DrawImage($img,(12+$i*($thumbWidth+12)),12,$thumbWidth,$thumbHeight)
    $img.Dispose()
  }
  $g.Dispose()
  $sheet.Save((Join-Path $assetRoot "preview-$device.jpg"),[System.Drawing.Imaging.ImageFormat]::Jpeg)
  $sheet.Dispose()
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $assetRoot 'manifest.json') -Encoding utf8
Compress-Archive -Path (Join-Path $assetRoot 'iphone-6.5'),(Join-Path $assetRoot 'ipad-13') -DestinationPath (Join-Path $assetRoot 'PriceMate-AppStore-ja.zip') -Force
Write-Output $manifest
