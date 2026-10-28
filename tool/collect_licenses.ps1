[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskConfigPath = Join-Path $taskRoot '.dart_tool/package_config.json'
if (-not (Test-Path -LiteralPath $taskConfigPath)) { throw 'Run flutter pub get first.' }
$taskConfig = Get-Content -LiteralPath $taskConfigPath -Raw | ConvertFrom-Json
$taskFlutter = $taskConfig.packages | Where-Object name -EQ 'flutter'
$taskFlutterPackage = ([Uri]$taskFlutter.rootUri).LocalPath
$taskSdk = Split-Path -Parent (Split-Path -Parent $taskFlutterPackage)
$taskOutput = Join-Path $taskRoot 'third_party/licenses/packages'
New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $taskSdk 'LICENSE') -Destination (Join-Path $taskRoot 'third_party/licenses/flutter-LICENSE.txt')
$taskInventory = @()
$taskMissing = @()
foreach ($taskPackage in ($taskConfig.packages | Sort-Object name)) {
    if ($taskPackage.name -eq 'toneharbor') { continue }
    $taskUri = [Uri]::new($taskPackage.rootUri, [UriKind]::RelativeOrAbsolute)
    $taskPackageRoot = if ($taskUri.IsAbsoluteUri -and $taskUri.IsFile) { $taskUri.LocalPath } else {
        [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $taskConfigPath) $taskPackage.rootUri))
    }
    $taskSpec = Get-Content -LiteralPath (Join-Path $taskPackageRoot 'pubspec.yaml') -Raw
    $taskVersion = [regex]::Match($taskSpec, '(?m)^version:\s*[''"]?([^\s''"]+)').Groups[1].Value
    $taskNotices = @()
    foreach ($taskLicense in (Get-ChildItem -LiteralPath $taskPackageRoot -File | Where-Object Name -Match '^(LICENSE|LICENCE|COPYING|NOTICE)([.-].*)?$')) {
        $taskName = "$($taskPackage.name)-$taskVersion-$($taskLicense.Name).txt"
        Copy-Item -LiteralPath $taskLicense.FullName -Destination (Join-Path $taskOutput $taskName)
        $taskNotices += "licenses/packages/$taskName"
    }
    $taskIsSdk = $taskPackageRoot.StartsWith($taskSdk.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    if ($taskNotices.Count -eq 0 -and $taskIsSdk) { $taskNotices += 'licenses/flutter-LICENSE.txt' }
    if ($taskNotices.Count -eq 0) { $taskMissing += $taskPackage.name }
    $taskInventory += [ordered]@{
        name = $taskPackage.name
        version = $taskVersion
        origin = $(if ($taskIsSdk) { 'Flutter SDK' } else { 'pub.dev (see pubspec.lock)' })
        notices = @($taskNotices)
    }
}
$taskDocument = [ordered]@{ scope = 'All resolved packages, including development dependencies; not a shipped-binary manifest'; packages = @($taskInventory); missingNotices = @($taskMissing) }
$taskDocument | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $taskRoot 'third_party/dependencies.json') -Encoding utf8
if ($taskMissing.Count -gt 0) { throw "Missing package license notices: $($taskMissing -join ', ')" }
Write-Output "Collected notices for $($taskInventory.Count) resolved packages."
