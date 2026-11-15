# Pinned dependencies

Poing Studios Godot AdMob v5.1.0, MIT license retained at `addons/admob/LICENSE`.

- Source release: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0
- Source ZIP: `poing-godot-admob-v5.1.0.zip`, SHA-256 `8c53ff52719edf6a81cc7d32a9cdaad2d9e11693c85faca25008a1c19355726f`.
- Native release: `android-template-v4.7.2.zip`, SHA-256 `f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee`.
- Only `ads` with `ads`/`core` debug/release AARs and package version metadata were installed. No mediation adapter binaries or iOS binaries are installed. The AARs are intentionally versioned; do not restore the upstream `/bin` ignore if expecting clean-checkout builds to work.
- Native transitive dependency declared by upstream: `com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0`, plus AndroidX constraintlayout 2.2.0. Resolve/audit the full Gradle dependency tree and merged manifest for the actual release; Maven dependencies are fetched free during build, not copied into GDScript.

Two local upstream patches are deliberate: `admob.gd` does not auto-download binaries on editor/headless startup; `MobileSingletonPlugin.gd` returns null on desktop instead of creating simulated ad plugins. Production integration is entirely in `scripts/services/ad_service.gd`. Test doubles exist only under tests. Do not overwrite these patches during an upgrade without reviewing offline behavior and reward correctness.

The official Godot 4.7.2 Android Gradle build template is extracted locally under ignored `android/build/` from the engine's official export template archive. It is not a rebuilt engine. `tools/install_android_template.ps1` can reproduce the extraction if the archive is available. Godot engine licenses/notices remain the upstream distribution's responsibility and should be included as required.

Portable FFmpeg/FFprobe used for development-only capture conversion are from https://github.com/imageio/imageio-binaries/tree/master/ffmpeg (win64 v4.2.2 / v4.1 named downloads); they stay in ignored `.tools/`, are not distributed in the Android app, and do not call paid encoding APIs. Preserve source/license obligations if redistributing those executables. Source AVI recordings are ignored; final reviewed MP4s are marketing artifacts outside the app export.
