# Cut & Cascade release-readiness report

Assessment: 2026-11-16; Godot **4.7.2.stable.official.ed1daf0bf**. **Implemented and locally verified; production launch remains gated by owner configuration and physical-device acceptance.** Nothing was published, no outreach/social content was sent, and no paid service/API/campaign was enabled.

## Audit and preserved work

The existing game had 100 puzzles across five chapters, deterministic solutions, daily campaign selection, stars/best cuts, coins/cosmetic trails, v2 checksum/backup saves, procedural audio, reusable UI, and Android presets. No rebuild was needed. Existing modifications to project.godot/export_presets.cfg and pre-existing builds/screenshots were treated as the working baseline.

Risks found: fake rewarded coin grants; combined privacy defaulting to allowed; memory-only analytics stub; unverified purchase entitlements; outdated API 34 release target; Godot logo as launcher icon; color-symbol toggle not wired to gameplay; daily streaks increasing after gaps; unnecessary redraws on stationary balls/buckets.

## Completed implementation

| Area | Result |
| --- | --- |
| Continuity | Existing scenes, levels, geometry/solutions, v2 save filename/checksum version, progress and cosmetics preserved. No account, energy system or required network. |
| Ads | Real pinned Poing AdMob v5.1.0 GDScript and Godot 4.7.2 Android ads/core AARs. AdService owns UMP, inventory, reward/impression/paid callbacks, expiry and frequency policy. No fake desktop/offline rewards. Debug forces test unit IDs. |
| Placements | Optional +25 coins only after earned callback, once; unavailable offers hidden. Interstitial only at Next after completion, level 11+, three distinct completions and 180-second startup/cooldown gap. Unready/offline/ad-free users continue immediately. No banners, app-open/retry ads or paid hints. |
| Consent | Fresh UMP at safe menu/result breaks; no delayed consent form over active gameplay. Consent-first initialization, privacy-options entry. Audience review defaults off; child/under-age defaults conservative. Legacy combined consent never authorizes either service. |
| Analytics | Separate default-off opt-in, bounded allowlisted PostHog HTTPS transport, random install/session IDs, clear/cancel/delete local analytics ID on withdrawal. Remote account/token absent. No invented revenue or country data. |
| Privacy | In-app explanation and choices; configurable public policy link disabled until provided. Data Safety worksheet and policy draft reflect game and SDK behavior. Actual merged permissions recorded. |
| Android/performance | Compatibility renderer, 60-fps cap with physics unchanged, ARM64 plus ARMv7 release splits, min SDK 24 / target 36, native Gradle exports. Tests/marketing/vendor sample assets excluded. New Android saves default to particle saver. Held balls and idle buckets avoid unnecessary redraws. |
| Retention/accessibility | First-level tutorial completion persisted; free Hint/Retry retained; streak resets after gaps; symbol preference now updates balls/containers. Save on OS pause and pause play during background/full-screen forms. Existing stars, best cuts, cosmetic and daily replay loops retained. |
| Store | Original vector icon/adaptive launcher assets, 512×512 Play PNG, 1024×500 feature graphic with real gameplay, eight genuine 1080×1920 screenshots, truthful titles/descriptions/keyword research seeds. |
| Organic | Two real silent H.264 vertical gameplay clips, ten concepts with scripts/captions/tags, platform packaging, reproducible recording/export tools and milestone strategy. Publishing stays manual. |
| Architecture | Ads remain in AdService; telemetry transport in AnalyticsService; persistence/economy in SaveManager; privacy rendering in PrivacyModal; puzzle rules in LevelController/components. Main composes/navigates. No secrets embedded. |
| Billing | Existing ad-free ownership respected. Unverified purchase offer hidden; sandbox purchases default off and cannot run in release. No real billing integration claimed or required. |

Core controls/HUD support English, Spanish, Brazilian Portuguese, French, German and Indonesian with OS locale, English fallback and saved override. This is an initial localization pass: level names, many mechanic messages and legal text still need translation/native review. Do not advertise complete six-language localization. See LOCALIZATION.md.

## Verification

- Godot headless editor import and real renderer startup succeeded. Initial restricted runs produced Windows certificate/editor-settings access errors; normal-access verification removed that environmental noise. Upstream automatic editor-start dependency downloads were disabled.
- **100/100 puzzles solved**, plus 15 component scenes, real-touch representative swipes, move accounting, chain/platform collisions, wrong-color failures, pause/resume, save/checksum/backup/cosmetic tests and next/restart. Final log: `.tools/release-regression.log`.
- **38 service checks**, including default-off events, local identity removal, native-callback test doubles, no fake reward, duplicate/skip/dismiss behavior, stale callbacks across subsequent ads/UMP forms, inventory invalidation after privacy changes, original paid-event attribution/deduplication, offline continuation, caps/safe breaks, daily gaps/replays, v2 migration and Spanish translation. These test doubles do not prove native behavior on a phone. `.tools/release-services.log`.
- **39,126 layout checks, zero failures** across 100 puzzles and six viewport sizes. `.tools/release-layout.log` and `docs/screenshots/corrected-verification.json`. Real Android insets/edge-to-edge remain untested.
- **Native debug APK exported successfully** with actual SDK dependencies. Inspected package `com.cutandcascade.colorpuzzle`, versionCode 1/name 1.0.0, min SDK 24, target/compile SDK 36, ARM64. Signature v2 verified; `zipalign -c -P 16 -v 4` passed. ZIP alignment does not prove every ELF segment or Play gate. Initial debug artifact: 90,927,297 bytes, mostly uncompressed native engine; this is not a Play download-size measurement.
- **Unsigned release-mode AAB exported successfully**, including both ARM architectures and upstream R8 configuration. Initial artifact: 59,315,793 bytes. It has no owner upload signature, remains in test/audience-gated configuration, and is for packaging QA only. Final refreshed artifacts and sizes are recorded in `docs/android-artifacts.json`.
- Real movies: level 3 solved in 3 cuts; level 61 in 6 cuts. Movie input **540×960/60 fps**, export **720×1280/30 fps**, silent. Level 3: **9.534 s, 518,918 bytes**; level 61: **10.000 s, 436,363 bytes**. Contact sheets reviewed. These are automated genuine-gameplay demonstrations, not human playtests. Provenance/hashes: `marketing/asset-manifest.json`.
- Desktop synthetic performance probe samples levels 1/41/61/100; static engine memory was about 75–76 MiB in the initial run. Initial timings were collected while Gradle was active and are not mobile frame-budget validation. See performance-desktop.json and DEVICE_ACCEPTANCE.md. No claim of achieved low-end FPS, thermal/battery targets or production revenue.
- Development preflight passes. Production preflight deliberately reports **seven configuration blockers**. No ADB device was connected.

## Owner/account/device gates

1. **AdMob:** owner's registered app ID, rewarded/interstitial units, account/app readiness, privacy messages and actual publisher/app-ads.txt identity. Public ad IDs are configuration, not passwords. Keep test units throughout QA; never click live ads for testing.
2. **Audience:** decide ages/Families applicability; review child/under-age flags and implement any required neutral age flow. Only then set `release/ads/audience_reviewed`. Intended age range was not guessed.
3. **Policy and disclosures:** fill legal name/contact, actual retention/region/deletion process, host completed policy on public free HTTPS, set `release/privacy_policy_url`, approve final Data Safety against resolved SDKs/manifest. Drafts are not a legal approval.
4. **Analytics:** optionally create a free PostHog regional project without a payment method/paid products, enforce $0/free-tier limits, confirm GeoIP and retention, then add only the public ingestion host/token. Until tested/configured there is no live retention/country dashboard. See ANALYTICS.md.
5. **Signing/Play:** owner upload key via environment secrets, package/version continuity, Play access/verification, required testing, IARC, Contains ads/Data Safety/audience and territory selection. Keep Free and manually choose intended eligible worldwide territories. [Google currently requires API 36 for new apps/updates after August 31, 2026](https://support.google.com/googleplay/android-developer/answer/11926878); recheck at submission.
6. **Device tests:** native UMP geography/reject/withdraw/offline, earned/skipped/click/failed-show callbacks, suspend/resume, process recreation, long-session inventory, actual analytics delivery/country, CPU/GPU/memory/thermal behavior. No physical-device results are claimed. Follow DEVICE_ACCEPTANCE.md; native lifecycle failures block ad-enabled distribution.
7. **Final artifact acceptance:** owner-signed production AAB, full ELF 16 KB compatibility, store-delivered splits, release permissions, Play pre-launch reports and device performance. A debug APK/unsigned QA AAB is not a production release. No upload occurred.

The seven production-preflight failures are: test mode on, audience review off, policy URL missing, owner app ID missing, two unit IDs missing, upload keystore missing. Remote analytics is an additional optional measurement gate. SDK manifests add advertising IDs, basic phone state, wake-lock and foreground-service declarations; those actual permissions are documented in PRIVACY_AND_DATA_SAFETY.md and android-debug-permissions.txt.

## Reproduce

```powershell
$godot = 'D:/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --editor --path . --import --quit
& $godot --headless --path . --script tests/release_services.gd
& $godot --headless --path . --fixed-fps 60 --script tests/test_runner.gd
& $godot --headless --path . --fixed-fps 60 --script tests/capture_ui_screenshots.gd
& $godot --headless --path . --script tools/release_preflight.gd -- --development
& $godot --headless --path . --script tools/release_preflight.gd
& $godot --headless --editor --path . --export-debug 'Android Debug APK' builds/CutAndCascade-AdMob-test.apk
& $godot --headless --editor --path . --export-release 'Android Unsigned QA AAB' builds/CutAndCascade-unsigned-qa.aab
# After owner configuration/signing and all acceptance gates pass:
& $godot --headless --editor --path . --export-release 'Android Release AAB' builds/CutAndCascade-release.aab
```

Use matching Godot Android build templates, JDK 17 and current SDK tools. The optional local installer accepts official android_source.zip; no build script publishes. Free development downloads included official templates, Android tools, Gradle/Maven dependencies and FFmpeg/FFprobe, excluded from game content. No paid plan/billing activation was performed.

The strategy in `marketing/GROWTH_MILESTONES.md` follows evidence gates: trustworthy first play → credible worldwide listing → repeatable content → retention → responsible monetization/regional iteration. There are no ranking, download or earnings guarantees.
