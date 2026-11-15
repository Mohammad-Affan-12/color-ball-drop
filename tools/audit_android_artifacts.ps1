param([string]$SdkRoot = 'D:/AndroidToolchain/android-sdk', [string]$BuildTools = '36.1.0', [string]$JavaSdk = 'D:/AndroidToolchain/jdk-17')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Add-Type -AssemblyName System.IO.Compression.FileSystem
$artifacts = @()
foreach ($name in @('CutAndCascade-AdMob-test.apk','CutAndCascade-unsigned-qa.aab')) {
    $artifactPath = Join-Path $projectRoot ('builds/' + $name)
    if (-not (Test-Path -LiteralPath $artifactPath)) { throw "Missing $name" }
    $archive = [IO.Compression.ZipFile]::OpenRead($artifactPath)
    $nativeLibraries = @()
    $signatureEntries = @($archive.Entries | Where-Object { $_.FullName -match '^META-INF/[^/]+\.(RSA|DSA|EC|SF)$' }).Count
    $hasBundleConfig = $null -ne $archive.GetEntry('BundleConfig.pb')
    if ($name.EndsWith('.aab') -and (-not $hasBundleConfig -or $signatureEntries -ne 0)) { throw 'QA AAB must be a real unsigned bundle' }
    $unwantedAssets = @($archive.Entries | Where-Object { $_.FullName -match 'assets/(marketing|tests|docs)/|assets/.*(music\.ogg|NotoSansSC)' })
    foreach ($entry in @($archive.Entries | Where-Object { $_.FullName -match '\.so$' })) {
        $stream = $entry.Open()
        $header = New-Object byte[] 65536
        $offset = 0
        while ($offset -lt $header.Length) {
            $read = $stream.Read($header,$offset,$header.Length-$offset)
            if ($read -eq 0) { break }
            $offset += $read
        }
        $stream.Dispose()
        if ($header[0] -ne 127 -or $header[1] -ne 69 -or $header[2] -ne 76 -or $header[3] -ne 70) { throw "Invalid ELF: $($entry.FullName)" }
        if ($header[5] -ne 1) { throw "Expected little-endian ELF: $($entry.FullName)" }
        $is64 = $header[4] -eq 2
        $programOffset = if ($is64) { [BitConverter]::ToUInt64($header,32) } else { [BitConverter]::ToUInt32($header,28) }
        $entrySize = [BitConverter]::ToUInt16($header, $(if($is64){54}else{42}))
        $entryCount = [BitConverter]::ToUInt16($header, $(if($is64){56}else{44}))
        $alignments = @()
        $congruent16K = $true
        for ($index=0; $index -lt $entryCount; $index++) {
            $position = [int]($programOffset + $index * $entrySize)
            if ($position + $entrySize -gt $offset) { throw "ELF program headers exceed read buffer: $($entry.FullName)" }
            if ([BitConverter]::ToUInt32($header,$position) -eq 1) {
                $alignment = if ($is64) { [BitConverter]::ToUInt64($header,$position+48) } else { [BitConverter]::ToUInt32($header,$position+28) }
                $alignments += $alignment
                $fileOffset = if ($is64) { [BitConverter]::ToUInt64($header,$position+8) } else { [BitConverter]::ToUInt32($header,$position+4) }
                $virtualAddress = if ($is64) { [BitConverter]::ToUInt64($header,$position+16) } else { [BitConverter]::ToUInt32($header,$position+8) }
                $congruent16K = $congruent16K -and ($fileOffset % 16384 -eq $virtualAddress % 16384)
            }
        }
        $valid16K = $alignments.Count -gt 0 -and @($alignments | Where-Object { $_ -lt 16384 }).Count -eq 0 -and $congruent16K
        if ($entry.FullName -match 'arm64-v8a' -and -not $valid16K) { throw "ARM64 ELF is not 16 KB aligned: $($entry.FullName)" }
        $nativeLibraries += [pscustomobject]@{path=$entry.FullName;load_segment_alignments=$alignments;offset_address_congruence_16k=$congruent16K;elf_load_alignment_16k=$valid16K}
    }
    $archive.Dispose()
    $artifacts += [pscustomobject]@{file=('builds/'+$name);bytes=(Get-Item -LiteralPath $artifactPath).Length;sha256=(Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLower();bundle_config_present=$hasBundleConfig;jar_signature_entries=$signatureEntries;unwanted_sample_or_marketing_assets=$unwantedAssets.Count;native_libraries=$nativeLibraries}
    if ($unwantedAssets.Count -gt 0) { throw "Unexpected sample/marketing assets remain in $name" }
}
$apkPath = Join-Path $projectRoot 'builds/CutAndCascade-AdMob-test.apk'
& (Join-Path $SdkRoot "build-tools/$BuildTools/zipalign.exe") -c -P 16 4 $apkPath
if ($LASTEXITCODE -ne 0) { throw 'APK ZIP alignment verification failed' }
$env:JAVA_HOME = $JavaSdk
$signatureOutput = @(& (Join-Path $SdkRoot "build-tools/$BuildTools/apksigner.bat") verify --verbose $apkPath 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
& (Join-Path $SdkRoot "build-tools/$BuildTools/aapt.exe") dump permissions $apkPath | Set-Content -LiteralPath (Join-Path $projectRoot 'docs/android-debug-permissions.txt')
if ($LASTEXITCODE -ne 0) { throw 'APK permission inspection failed' }
$result = [pscustomobject]@{note='Local debug signature, APK ZIP and native ELF alignment, exclusions and unsigned release-mode packaging audit; not Play approval or physical-device acceptance';apk_zip_alignment_16k_verified=$true;apk_signature_verified=$true;apk_signature_result=$signatureOutput;artifacts=$artifacts}
[IO.File]::WriteAllText((Join-Path $projectRoot 'docs/android-artifacts.json'),($result | ConvertTo-Json -Depth 8))
Write-Output 'Artifact hashes, exclusions, unsigned AAB structure, native ELF/ZIP alignment, APK signature and permissions verified; results saved in docs/android-artifacts.json.'
