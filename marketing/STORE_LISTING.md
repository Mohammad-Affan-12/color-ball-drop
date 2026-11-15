# Google Play listing drafts

## Positioning and metadata

Primary title (27/30 characters): **Cut & Cascade: Color Puzzle**

Title experiment candidates: **Cut & Cascade: Rope Puzzle** (26); **Cut & Cascade: Physics Game** (27). Use one title per listing experiment; never keyword-stack the live title. Brand, category and mechanic come from actual gameplay.

Short description (74/80 characters): **Cut ropes, match colors and solve 100 physics puzzles. Play offline, free.**

Full description draft (under 4,000 characters):

> A little cut. A colorful cascade.
>
> Swipe through gold ropes and supports, release the balls and guide every color into its matching container. A well-timed cut can set the whole puzzle in motion.
>
> Cut & Cascade is a free physics puzzle game with 100 levels across five chapters. Start with simple cuts, then discover steel strikers, chain triggers, bumper pins, color gates, dye rings, seesaws, portals and moving deflectors. Look carefully: some ropes are decoys, and the order of your cuts matters.
>
> • Solve every puzzle offline. No account or energy timer.
> • Retry freely and use free hints to see the recommended cut order.
> • Aim for three stars by solving puzzles with fewer cuts.
> • Replay favorites and earn coins for cosmetic blade trails.
> • Try the Daily Cascade, an offline daily selection from the existing campaign.
> • Use color symbols alongside colors, adjust sound and vibration, or reduce particles.
>
> The game works without an internet connection. Optional bonus-coin ads require internet and an available ad. Interstitial ads may appear between completed levels, never during a puzzle. Watching ads is not required to unlock campaign puzzles, hints or retries.
>
> Progress is stored on your device. Optional analytics is off until you choose to enable it in Settings. Google ad privacy choices are managed separately.
>
> Plan the cut. Match the colors. Enjoy the cascade.

The advertising paragraph describes the prepared integration **after** owner configuration and device acceptance; do not imply live ads or full localization have already been approved. Remove the claim about ads if publishing an intentionally SDK-free edition. Choose Games → Puzzle; Free; Contains ads when the final ad-enabled build is submitted. In-app purchases: no active purchase flow in this build. Owner must complete target audience and IARC accurately.

## Keyword research candidates

Natural-language candidates, not measured search-volume claims: rope puzzle, cut rope game, physics puzzle, color sorting puzzle, chain reaction puzzle, offline puzzle, ball sorting, logic puzzle, relaxing puzzle, brain puzzle, seesaw puzzle. Google Play has no standalone keyword field. Use only relevant phrases naturally in localized titles/descriptions. Avoid competing game names/trademarks, “best”, “#1”, “guaranteed”, fake download counts, or revenue claims.

Local research seeds for native review: Spanish `puzle de física`, `cortar cuerdas`, `sin conexión`; Portuguese `quebra-cabeça de física`, `cortar cordas`, `offline`; Indonesian `puzzle fisika`, `potong tali`, `offline`. These are research seeds, not completed store translations. Inspect Play autocomplete on actual target-country devices, compare listing conversion by country/language, and prioritize verified demand plus player retention over raw search impressions.

## Actual assets in store/

| File | Purpose | Content |
| --- | --- | --- |
| icon-512.png | Play icon, 512×512 opaque PNG | Original vector cut/balls/buckets motif; no Godot logo |
| icon.svg | Editable master | No baked corner rounding, badges or ratings |
| feature-1024x500.png | Feature graphic, opaque PNG | Brand + genuine level 3 screenshot; no fake gameplay |
| gameplay-level-01.png | First screenshot, 1080×1920 | Readable first puzzle / cut-and-match premise |
| gameplay-level-03.png | Second screenshot | Steel striker and chain trigger |
| gameplay-level-21.png | Third screenshot | Chapter 2 puzzle variety |
| gameplay-level-41.png | Fourth screenshot | Seesaw progression |
| gameplay-level-61.png | Fifth screenshot | Portal-era progression |
| gameplay-level-81.png | Sixth screenshot | Mastery puzzle |
| level-select.png | Optional screenshot | Actual five-chapter level selection |
| home.png | Optional screenshot | Actual local progress / daily challenge menu |

All eight screenshots are raw rendered gameplay/UI captures, not app mockups. Inspect on a phone before choosing 4–8 for the listing. Suggested editorial captions, if adding a localized caption band outside the game: “Plan your first cut”, “Trigger a chain reaction”, “Match every color”, “Master the moving pieces”. Never cover the controls or invent a mechanic. Use source screenshots again after any visible UI changes.

Launcher assets are separate: `resources/icons/launcher_foreground.svg` and `launcher_background.svg` are prepared for adaptive icon masking. Test circular, squircle and monochrome themed masks on-device before asserting final safe-area coverage. Release export should use the same background as debug (set in preset if absent). Tablet screenshots must be captured on an actual tablet layout; the phone screenshots are not claimed as tablet captures.

Preview requirements reference: [Google Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151). Recheck at upload: icon 512×512; feature graphic 1024×500; screenshot dimensions/format and portrait placement. Video files here are organic social drafts, not an automatically uploaded YouTube trailer. All publishing is manual.
