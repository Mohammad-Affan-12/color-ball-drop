# Measurement and revenue operations

Implemented transport: direct HTTPS PostHog batch Capture API; no Firebase project, measurement secret, paid endpoint, session replay or automatic screen capture. Remote ingestion is intentionally unconfigured pending owner account and policy decisions. Analytics collection is independently opt-in and off by default. Nothing in this repository contains actual installs, revenue, retention cohorts or country performance.

## Event contract

| Event | Trigger | Important properties |
| --- | --- | --- |
| session_start | App process starts with consent, or explicit opt-in | App version, locale, development_build; random install distinct_id and per-process session UUID |
| session_resume | OS app resume | Same session identity; use distinct IDs for active-user counts, not event totals |
| level_start | Real level load | level, daily_challenge |
| level_complete | Real controller win signal | level, stars, moves, coins_awarded, attempt within this process, duration_seconds, daily_challenge |
| level_fail | Real controller failure signal | level, attempt, duration_seconds; no free-text user input |
| level_restart / hint_used | Actual user action | level |
| tutorial_complete | First stored level-1 completion | level |
| cosmetic_unlocked | Local coin unlock | Cosmetic ID; **not a currency purchase or revenue** |
| ad_impression | Native SDK impression callback | format, placement, test_ad |
| ad_revenue | Native SDK paid callback, deduplicated per shown ad | currency, value_micros, precision, format, original placement, test_ad |
| rewarded_ad_completed | Native earned-reward callback | placement; dismissing/skipping is not completion |

Buffers are capped at 200 in memory, 20 events per upload, at most 150 events per app process, one upload opportunity per 30 seconds, 5-second request timeout. Failed batches retain the same UUID for deduplication and return to the bounded memory queue. Unsent events are intentionally lost on process termination to minimize offline work, storage and identifiers. Events are never used to block gameplay. Very short sessions, offline users, opted-out users and sessions past the event cap are undercounted; reports are not a census. A public project key cannot enforce global spend alone: the account's free-only billing/ingestion cap is required.

The initial privacy text is English with English fallback; native-language legal and consent review is required before marketing a locale as fully translated. For child audiences, keep analytics off until the audience-specific consent/eligibility design is approved.

## Dashboard setup after account activation

1. Exclude `development_build=true` and `test_ad=true` from production dashboards; use a separate free test project if needed. Native test callbacks are for QA, never revenue reporting.
2. DAU/WAU/MAU: unique distinct IDs with session_start/session_resume or gameplay activity, grouped by event date; use the dashboard's declared timezone consistently. These count installations, not identified people. Reinstall/withdrawal creates a new identity.
3. Retention: first session_start cohort returning with real gameplay activity on D1/D7/D30. Use country dimension from server GeoIP enrichment, not device language. Confirm country is populated and document unknown/VPN buckets. Separate new-player and returning-player cohorts; opt-in after first play is a measurement limitation.
4. First-session funnel: session_start → level_start(level 1) → tutorial_complete → level_complete(level 3) → level_complete(level 5). Show numerator/denominator and sample size. Compare starts to completions and fail/retry distributions per level. Within-process attempts and duration include some menu/background time, so do not label duration as pure interaction time.
5. Ad funnel: real impressions by format/country; rewarded completions per rewarded impression; fill/match/show rate from the **AdMob console**, not guessed from local availability. Use AdMob country reporting as the authoritative monetization geography source. No bans on offline play or forced retry ads.
6. Revenue: sum only SDK-reported `value_micros / 1,000,000`, partitioned by currency and precision; exclude tests. Never combine different currencies without documented conversion. Reconcile with AdMob estimated earnings by country, ad source, format and day. SDK paid events are estimates with callback loss/consent bias, not settled cash. If paid callbacks are unavailable, show unavailable and use AdMob reports; never synthesize revenue from impression counts.
7. eCPM = actual estimated ad earnings / actual impressions × 1,000 (matching currency/date/source). ARPDAU = matched estimated earnings / measured active installs, with measurement bias disclosed. Retention and puzzle success remain guardrails when adjusting ad frequency.

No BigQuery, Cloud Functions, subscription, paid dashboard or ad campaign has been enabled. Firebase Analytics is a possible future free-tier alternative, but is **not integrated** here; do not report it as installed. [PostHog's official Capture API](https://posthog.com/docs/api/capture) documents the chosen ingestion transport. [Pricing and billing caps](https://posthog.com/pricing) must be verified at account setup.
