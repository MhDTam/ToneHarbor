[CmdletBinding()]
param([string]$Destination = 'OpenSource/ToneHarbor')
$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$taskDestination = [IO.Path]::GetFullPath((Join-Path $taskRoot $Destination))
if (-not $taskDestination.StartsWith($taskRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Source export destination must be inside this workspace.'
}
$taskZip = Join-Path (Split-Path -Parent $taskDestination) 'ToneHarbor-source.zip'
$taskManifestPath = Join-Path (Split-Path -Parent $taskDestination) 'source-manifest.json'
foreach ($taskExisting in @($taskDestination, $taskZip, $taskManifestPath)) {
    if (Test-Path -LiteralPath $taskExisting) { throw "Refusing to overwrite: $taskExisting" }
}
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'LICENSE'))) { throw 'A project license is required.' }
if (-not (Test-Path -LiteralPath (Join-Path $taskRoot 'third_party/dependencies.json'))) { throw 'Run tool/collect_licenses.ps1 first.' }
$taskFiles = [Collections.Generic.List[IO.FileInfo]]::new()
$taskRootFiles = @('.gitignore','.gitattributes','.flutter-version','.metadata','pubspec.yaml','pubspec.lock','analysis_options.yaml','l10n.yaml','README.md','README.ar.md','LICENSE','CONTRIBUTING.md','SECURITY.md','CHANGELOG.md','THIRD_PARTY_NOTICES.md')
foreach ($taskName in $taskRootFiles) { $taskFiles.Add((Get-Item -LiteralPath (Join-Path $taskRoot $taskName))) }
$taskPending = [Collections.Generic.Stack[string]]::new()
foreach ($taskDirectory in @('.github','assets','docs','lib','test','third_party','tool','tools','windows')) { $taskPending.Push((Join-Path $taskRoot $taskDirectory)) }
while ($taskPending.Count -gt 0) {
    foreach ($taskItem in (Get-ChildItem -LiteralPath $taskPending.Pop() -Force)) {
        if (($taskItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        if ($taskItem.PSIsContainer) {
            if ($taskItem.Name -notmatch '^(ephemeral|build|\.git|\.dart_tool|\.pub-cache|\.idea|\.vscode|__pycache__)$') { $taskPending.Push($taskItem.FullName) }
        } elseif ($taskItem.Name -notmatch '(?i)(\.(exe|dll|so|dylib|zip|7z|pdb|log|isar|db|sqlite\w*|jks|keystore|pem|pfx|p12|mp3|mp4|wav|flac|ogg|opus|webm|m4a|aac|wma|mkv|avi|mov)$|^\.env|^credentials\.json$|^key\.properties$)') {
            $taskFiles.Add($taskItem)
        }
    }
}
# Fail before copying if a high-confidence credential or machine-specific user path is found.
foreach ($taskFile in $taskFiles) {
    if ($taskFile.Length -gt 50MB) { throw "Oversized source file: $($taskFile.Name)" }
    if ($taskFile.Extension -match '^\.(dart|arb|json|yaml|yml|md|txt|ps1|cpp|cc|h|rc|cmake|lock)$') {
        $taskText = [IO.File]::ReadAllText($taskFile.FullName)
        if ($taskText -match '(-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[A-Z0-9]{16})') { throw "Potential credential in: $($taskFile.Name)" }
        if ($taskText -match '(?i)\bC:[\\/]+Users[\\/]+|\bM:[\\/]+Codex[\\/]+|\bF:[\\/]+Important Programs[\\/]+') { throw "Machine-local path in: $($taskFile.Name)" }
    }
}
New-Item -ItemType Directory -Path $taskDestination | Out-Null
$taskManifest = foreach ($taskFile in ($taskFiles | Sort-Object FullName)) {
    $taskRelative = [IO.Path]::GetRelativePath($taskRoot, $taskFile.FullName)
    $taskTarget = Join-Path $taskDestination $taskRelative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($taskTarget)) | Out-Null
    Copy-Item -LiteralPath $taskFile.FullName -Destination $taskTarget
    [ordered]@{ path = $taskRelative.Replace('\','/'); bytes = $taskFile.Length; sha256 = (Get-FileHash -LiteralPath $taskTarget -Algorithm SHA256).Hash }
}
$taskManifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $taskManifestPath -Encoding utf8
# ZipFile includes dot-directories such as .github; Compress-Archive can omit them.
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($taskDestination, $taskZip, [IO.Compression.CompressionLevel]::Optimal, $true)
Write-Output "Exported $($taskFiles.Count) files."
Write-Output $taskDestination
Write-Output $taskZip
