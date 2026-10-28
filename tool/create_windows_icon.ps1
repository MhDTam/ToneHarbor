# Regenerate the multi-resolution Windows icon from the approved ToneHarbor logo.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskSource = [Drawing.Bitmap]::new((Join-Path $taskRoot 'assets/images/harbor/brand-glossy-v9.png'))
$taskSizes = @(256,128,64,48,32,16)
$taskImages = @()
try {
    foreach ($taskSize in $taskSizes) {
        $taskBitmap = [Drawing.Bitmap]::new($taskSize,$taskSize,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $taskGraphics = [Drawing.Graphics]::FromImage($taskBitmap)
        $taskStream = [IO.MemoryStream]::new()
        try {
            $taskGraphics.Clear([Drawing.Color]::Transparent)
            $taskGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $taskGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $taskGraphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $taskScale = [Math]::Min($taskSize / $taskSource.Width,$taskSize / $taskSource.Height)
            $taskWidth = [int][Math]::Round($taskSource.Width * $taskScale)
            $taskHeight = [int][Math]::Round($taskSource.Height * $taskScale)
            $taskGraphics.DrawImage($taskSource,[Drawing.Rectangle]::new(
                [int](($taskSize-$taskWidth)/2),[int](($taskSize-$taskHeight)/2),$taskWidth,$taskHeight))
            $taskBitmap.Save($taskStream,[Drawing.Imaging.ImageFormat]::Png)
            $taskImages += ,$taskStream.ToArray()
        } finally { $taskStream.Dispose(); $taskGraphics.Dispose(); $taskBitmap.Dispose() }
    }
} finally { $taskSource.Dispose() }
$taskPath = Join-Path $taskRoot 'windows/runner/resources/app_icon.ico'
$taskWriter = [IO.BinaryWriter]::new([IO.File]::Create($taskPath))
try {
    $taskWriter.Write([uint16]0); $taskWriter.Write([uint16]1); $taskWriter.Write([uint16]$taskSizes.Count)
    $taskOffset = 6 + 16 * $taskSizes.Count
    for ($taskIndex=0; $taskIndex -lt $taskSizes.Count; $taskIndex++) {
        $taskDimension = if ($taskSizes[$taskIndex] -eq 256) { 0 } else { $taskSizes[$taskIndex] }
        $taskWriter.Write([byte]$taskDimension); $taskWriter.Write([byte]$taskDimension)
        $taskWriter.Write([byte]0); $taskWriter.Write([byte]0)
        $taskWriter.Write([uint16]1); $taskWriter.Write([uint16]32)
        $taskWriter.Write([uint32]$taskImages[$taskIndex].Length); $taskWriter.Write([uint32]$taskOffset)
        $taskOffset += $taskImages[$taskIndex].Length
    }
    foreach ($taskBytes in $taskImages) { $taskWriter.Write([byte[]]$taskBytes) }
} finally { $taskWriter.Dispose() }
Write-Output $taskPath
