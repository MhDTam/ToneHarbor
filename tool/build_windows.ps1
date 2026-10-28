[CmdletBinding()]
param([string]$OutputDirectory = 'dist/ToneHarbor', [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$taskOutput = [IO.Path]::GetFullPath((Join-Path $taskRoot $OutputDirectory))
if (-not $taskOutput.StartsWith($taskRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Output must be inside this workspace.' }
if (Test-Path -LiteralPath $taskOutput) { throw "Refusing to overwrite: $taskOutput" }
Push-Location $taskRoot
try {
    flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
    if (-not $SkipChecks) {
        flutter analyze --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
        flutter test --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
    }
    flutter build windows --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
    if (-not (Test-Path -LiteralPath 'third_party/dependencies.json')) { throw 'Run tool/collect_licenses.ps1 before packaging.' }
    New-Item -ItemType Directory -Path $taskOutput | Out-Null
    Get-ChildItem -LiteralPath 'build/windows/x64/runner/Release' | Copy-Item -Destination $taskOutput -Recurse
    foreach ($taskName in @('LICENSE','THIRD_PARTY_NOTICES.md','third_party')) { Copy-Item -LiteralPath $taskName -Destination $taskOutput -Recurse }
    New-Item -ItemType Directory -Path (Join-Path $taskOutput 'tools') | Out-Null
    Copy-Item -LiteralPath 'tools/README.md' -Destination (Join-Path $taskOutput 'tools')
    @'
ToneHarbor portable build

Keep the executable, DLLs and data/ together. This build is unsigned.
FFmpeg is not bundled. Put a suitable ffmpeg.exe in tools/ or add ffmpeg to PATH
for waveform decoding, conversion and audio editing. Retain the actual build's
license/source materials if you redistribute FFmpeg.

See LICENSE, THIRD_PARTY_NOTICES.md and third_party/ for notices.
'@ | Set-Content -LiteralPath (Join-Path $taskOutput 'README.txt') -Encoding utf8
    Write-Output $taskOutput
} finally { Pop-Location }
