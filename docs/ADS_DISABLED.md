# Current advertising setting — 2026-11-17

The owner requested removal of the current ads/startup interruption and will configure Google advertising personally later, with a desired limit of three ads per day.

Current project behavior:

- `release/ads/enabled=false`: AdService does not attach/initialize the SDK.
- `admob/general/android/enabled=false`: fresh Android exports exclude native AdMob/UMP libraries and their manifest registrations.
- No automatic consent/ad preparation on home or level completion. Next goes directly to the next puzzle. Rewarded offers and Google ad-privacy controls are hidden.
- The in-game startup title overlay is no longer shown. Existing engine boot-splash settings and all saves/levels are preserved.
- SDK source remains available for the owner's future integration; it is inactive. A future three-per-day Google configuration has **not** been enabled or claimed as an enforced daily limit.

Install the newly rebuilt `builds/CutAndCascade-no-ads.apk` to use this behavior. Older installed APKs and earlier AdMob-test artifacts do not change when project source changes. Do not uninstall merely to upgrade if preserving local progress; use the matching signing key/package.

This update supersedes the active-monetization assumptions in the earlier release-readiness report and store listing drafts. Before adding ads again, review audience/consent, configure actual account IDs and the intended daily cap, and re-test the native integration on a device. Before publishing this no-ad edition, omit claims that it currently shows rewarded/interstitial ads and approve Data Safety against the actual rebuilt artifact.
