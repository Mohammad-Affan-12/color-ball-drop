param(
    [string]$Godot = 'D:/Godot_v4.7.2-stable_win64_console.exe',
    [string]$OutputPath = 'builds/ColorBallDrop-release.aab'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$privateSettings = Join-Path $projectRoot '.tools/android-release-signing.local.json'
$requiredNames = @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')
$previousValues = @{}
$localSettings = $null
try {
    foreach ($name in $requiredNames) {
        $previousValues[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    }
    if (@($requiredNames | Where-Object { [string]::IsNullOrEmpty($previousValues[$_]) }).Count -gt 0 -and (Test-Path -LiteralPath $privateSettings)) {
        try { $localSettings = Get-Content -LiteralPath $privateSettings -Raw | ConvertFrom-Json } catch { throw 'Local signing settings could not be read' }
    }
    foreach ($name in $requiredNames) {
        if ([string]::IsNullOrEmpty($previousValues[$name]) -and $null -ne $localSettings) {
            $property = $localSettings.PSObject.Properties[$name]
            if ($null -ne $property) { [Environment]::SetEnvironmentVariable($name, [string]$property.Value, 'Process') }
        }
        if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name, 'Process'))) { throw "Missing signing environment variable: $name" }
    }
    if (-not (Test-Path -LiteralPath $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -PathType Leaf)) { throw 'Release keystore file is unavailable' }
    & $Godot --headless --path $projectRoot --editor --export-release 'Android Release AAB' $OutputPath
    if ($LASTEXITCODE -ne 0) { throw 'Android release export failed' }
} finally {
    foreach ($name in $requiredNames) {
        if ($previousValues.ContainsKey($name)) { [Environment]::SetEnvironmentVariable($name, $previousValues[$name], 'Process') }
    }
}
