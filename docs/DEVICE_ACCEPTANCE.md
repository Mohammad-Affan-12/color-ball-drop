# Android acceptance gates

No device was connected during implementation. These are required manual tests, not completed results. A passing desktop solver is not a substitute for Android ad lifecycle or performance testing.

## Installation and offline play

- Fresh install and upgrade an existing signed test build on a low-end 2 GB ARM device, a 32-bit ARM device if supported by the final ABI bundle, and a recent 64-bit Android device. Use the correct signing key for upgrades. Verify existing stars, coins, unlocked levels and cosmetics survive; never reset a real player's data for QA.
- Start in airplane mode; play levels 1–5, retry, use Hint, choose an unlocked level, play daily, unlock/equip a cosmetic, restart the app. All must work without accounts/ads/network. Remove-ads owned saves must still suppress interstitials. Test daily streak with consecutive dates, gaps and duplicate completions on an isolated test save.
- Test short/tall portrait and tablet aspect ratios with cutouts, gesture/three-button navigation, font scaling and Android 16 edge-to-edge behavior. Check safe areas against actual device insets; do not rely only on desktop geometry. Test adaptive icon masks, launcher title and notification interruptions.
- Background/resume during a cascade, during a menu, during UMP and during full-screen ads. Lock/unlock and low-memory process recreation. Verify no hidden gameplay continues behind a consent/ad form, no duplicate navigation or lost rewards, and no black screen. Android Back behavior needs a device check.

## Ads and privacy

- Owner audience and policy review first; keep test mode and Google sample units throughout QA. No live clicks by developers. Configure UMP debug test device/geographies using the vendor tools only in debug, never ship forced geography.
- Consent needed/accepted/rejected/not required, privacy-options reopening and withdrawal, no network, no fill, airplane toggle after preload, app process killed while loading, ad click returning from browser, dismiss and skipped reward, SDK failed-to-show, long ad and resume.
- A bonus is granted only once on earned-reward callback. No reward for opening/skipping/error; no fake desktop rewards. Offer does not show without loaded inventory. The campaign, Hint and Retry remain free. Next must continue immediately when no interstitial is eligible/ready.
- Verify no interstitial before level 11, no active-puzzle ad, at least 3 distinct completion breaks, at least 180 seconds since startup/last display, and no repeating the same completion to inflate the counter. Confirm ad error dismisses gracefully and native callbacks always restore navigation. AdMob's native callback completion is still a device-level release gate.
- Verify PostHog opt-in sends the allowlisted events, actual country enrichment works, test traffic is excluded, disabling stops requests and clears the local ID/buffer. Inspect traffic/dependency behavior and final merged permissions before final Data Safety approval. Previously sent records need the reviewed provider deletion process.

## Measured performance and distribution

- On the low-end target, measure 5+ minutes of real play across simple, moving/portal and mastery puzzles, then repeat after thermal load. Record device/OS/ABI, build hash and release/debug status. Use Android profiler/Perfetto, Godot monitors and Play Android vitals. Record p50/p95 frame times, missed frames, peak PSS/RSS, startup, battery/thermal observations, APK/AAB installed/download sizes, crash/ANR logs.
- Acceptance targets to validate, not measured claims: stable gameplay at 30 fps (33.3 ms frame budget) on the chosen minimum device; prefer 60 fps on capable devices, bounded memory across repeated level loads, no ANR/crash or sustained thermal collapse. The 60 Hz physics solution timing must stay unchanged. Particle saver is user-selectable; no geometry/physics shortcuts to gain frames.
- Inspect the final bundle with bundletool and Play pre-launch reports. Validate 16 KB page-size compatibility of native libraries and ZIP alignment. Audit 64-bit support, current target API, SDK quality/safety warnings, signing/upload key, store-delivered splits, denied-consent behavior and package/version continuity. A debug APK is not a Play-ready signed release AAB.
