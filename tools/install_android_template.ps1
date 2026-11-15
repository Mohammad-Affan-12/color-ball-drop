param(
    [Parameter(Mandatory=$true)][string]$SourceZip,
    [string]$GodotVersion = '4.7.2.stable'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$androidRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'android'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $androidRoot 'build'))
if (-not $buildRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Build directory must remain in this project' }
if (-not (Test-Path -LiteralPath $SourceZip -PathType Leaf)) { throw 'Provide the official matching android_source.zip from Godot export templates' }
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
Expand-Archive -LiteralPath $SourceZip -DestinationPath $buildRoot -Force
Set-Content -LiteralPath (Join-Path $androidRoot '.build_version') -Value $GodotVersion -Encoding ascii
Set-Content -LiteralPath (Join-Path $buildRoot '.gdignore') -Value '' -Encoding ascii
Write-Output "Installed Android Gradle template for $GodotVersion in $buildRoot"
Write-Output 'Configure the Android SDK and JDK in Godot Editor Settings. No network download or publication was performed by this script.'
