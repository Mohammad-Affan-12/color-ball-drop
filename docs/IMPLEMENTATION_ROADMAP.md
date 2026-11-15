# CUT & CASCADE: COLOR PUZZLE — AUDIT, FEATURE SPEC & IMPLEMENTATION ROADMAP

**Document Purpose:** Honest audit of the existing Godot 4.7.2 repository, prioritized feature specifications (`P0`–`P3`), critical risk analysis, and milestone-based engineering roadmap.

---

## 1. Existing Codebase Audit & Feature Inventory

Every file in `d:\cut-and-cascade` was inspected line-by-line. Below is the verified status of all project files and features:

### 1.1 File-by-File Codebase Inventory

| File Path | Lines | Current Status | Audit Findings & Technical Notes |
| :--- | :--- | :--- | :--- |
| `project.godot` | 41 | **Implemented (Needs Aspect Tweak)** | Configured for Godot 4.7.2, `720x1280` portrait (`540x960` override), `emulate_touch_from_mouse=true`, `stretch/aspect="keep"`. Needs `stretch/aspect="expand"` + camera centering to avoid black bars on 20:9 Android phones. |
| `scripts/game_colors.gd` | 54 | **Implemented (Needs Distinct Emblems)** | Defines `RED`, `BLUE`, `YELLOW`, `GREEN`, `STEEL` colors and names. Currently `ball.gd` draws identical twin arcs for all 4 colored balls; needs distinct per-color geometric emblems for full colorblind accessibility. |
| `scripts/ball.gd` + `scenes/components/ball.tscn` | 109 | **Implemented** | `PuzzleBall` (`RigidBody2D`) with `CCD_MODE_DISABLED`, glossy 3D-like draw layers, motion trail, and heavier mass (`4.5`) for `STEEL` strikers. Working and verified. |
| `scripts/container_bucket.gd` + `scenes/components/container_bucket.tscn` | 243 | **Implemented** | `ColorContainer` with flared `StaticBody2D` walls, `Area2D` collector, animated liquid fill, particle burst, match signal, and wrong-color fail signal. Working and verified. |
| `scripts/cuttable_base.gd` | 52 | **Implemented** | Base class for sliceable nodes with `check_segment_cut`, `perform_cut`, and pulsed hint badge drawing. |
| `scripts/cuttable_beam.gd` + `scenes/components/cuttable_beam.tscn` | 154 | **Implemented** | Sliceable barrier (`StaticBody2D`) with `13 px` mobile grazing tolerance, particle burst, and tumbling split-half animation. |
| `scripts/cuttable_rope.gd` + `scenes/components/cuttable_rope.tscn` | 124 | **Implemented** | Sliceable tether (`14 px` grazing tolerance) that holds a `RigidBody2D` via `FREEZE_MODE_KINEMATIC` and unfreezes/launches it on cut. |
| `scripts/ramp.gd` + `scenes/components/ramp.tscn` | 130 | **Implemented** | Angled chute with rounded end-caps, optional left/right backstop lips, and tweened rotation/movement helpers. |
| `scripts/chain_trigger.gd` + `scenes/components/chain_trigger.tscn` | 109 | **Implemented** | Impact sensor (`Area2D`) that breaks linked `CuttableBeam`s, rotates linked `Ramp`s, and optionally absorbs `STEEL` strikers. |
| `scripts/slice_controller.gd` | 242 | **Partially Integrated (Signal Mismatch)** | Upgraded with valid vs. invalid swipe tracking (`valid_move_performed`, `invalid_swipe_performed`), shockwave flashes, haptics, and `dispatch_real_touch_swipe()`. **Issue:** Emits `object_sliced(item, cut_point, cuts_in_swipe)` (3 args), while `main.gd` line 236 still expects 2 args (`_on_object_sliced(_item, _pt)`). |
| `scripts/sfx_manager.gd` | 109 | **Partially Integrated** | Upgraded with `muted`, `volume_percent`, `PROCESS_MODE_ALWAYS`, and `slice_beam` / `slice_rope` / `ui_click` streams, but `main.gd` has not yet wired UI controls to `muted` or `volume_percent`. |
| `scripts/save_manager.gd` | 81 | **Partially Implemented (Unwired)** | File exists and implements `ConfigFile` load/save for `highest_unlocked_level`, `level_stars`, `level_best_moves`, `tutorial_completed`, and audio settings, but is **not yet instantiated or called** by `main.gd` or `level_controller.gd`, and lacks `.bak` corruption recovery. |
| `scripts/level_controller.gd` | 298 | **Implemented (Missing Move/Star Tracking)** | Manages arena walls, confetti, win/fail states, out-of-bounds, and settled-ball timeouts. Does not yet track `moves_used`, `par_moves`, or 1–3★ calculation, nor spawn the Level 1 interactive tutorial guide. |
| `scripts/level_data.gd` + `scenes/levels/level_1..5.tscn` | 267 | **Implemented (5 Levels)** | Contains 5 verified, solvable levels (`Twin Cascades`, `Triple Streams`, `Chain Reaction`, `Four-Color Spectrum`, `Grand Cascade`). Needs `par_moves` metadata and expansion to Levels 6–20+. |
| `scripts/main.gd` + `scenes/main.tscn` | 334 | **Partially Implemented** | Has Top HUD, Level 1–5 buttons, Hint toggle, Restart, Camera2D shake, and Win/Fail modal. **Missing:** `SaveManager` integration, locked-level enforcement, Pause & Sound Settings modal, Home screen, Level Select grid, Star display, and responsive `expand` aspect centering. |
| `tests/test_runner.gd` | 147 | **Implemented (Needs Expansion)** | Verifies Levels 1–5 via `simulate_swipe`, wrong-color fail detection, and Next/Restart buttons. Needs expansion to test real `InputEventScreenTouch` / `InputEventScreenDrag` input, invalid swipe move preservation, `SaveManager` persistence, and pause/settings state. |

---

## 2. Complete Prioritized Feature Specification (`P0` – `P3`)

### 2.1 P0 — Essential Commercial Release Features (Gameplay Quality & Mobile-Readiness)

#### P0-1: Valid vs. Invalid Swipe Move Accounting & Enhanced Slice Feedback
- **Purpose:** Ensure accidental or exploratory swipes never penalize the player, while making valid cuts feel deeply satisfying.
- **Player Experience:** Swiping empty space shows a cyan trail and costs `0` moves. Slicing one or more beams/ropes in a single stroke flashes gold, triggers a shockwave ring, plays distinct wood/rope audio + micro-haptics, and increments `Cuts` by `1`.
- **Functional Behavior:** Connect `SliceController.object_sliced` (3 args) and `SliceController.valid_move_performed` to `Main` and `LevelController`. Increment `LevelController.moves_used` only on `valid_move_performed`.
- **Required Godot Systems:** `SliceController`, `LevelController`, `SfxManager`, `Input.vibrate_handheld()`.
- **Dependencies:** Fix 3-arg signal signature in `scripts/main.gd`.
- **Acceptance Criteria:** Automated test dispatches 3 empty-space swipes (`moves_used == 0`), 1 swipe across an already-cut beam (`moves_used == 0`), and 1 swipe slicing 2 ropes simultaneously (`moves_used == 1`).
- **Priority:** **P0**

#### P0-2: Interactive Gameplay Tutorial (Level 1)
- **Purpose:** Teach swipe-to-cut mechanics through immediate action rather than text-heavy instructions.
- **Player Experience:** On Level 1, an animated glowing hand/scissor guide slides across Target 1 (`"SWIPE TO CUT"`), then glides to Target 2 (`"CUT THE ROPE"`), then Target 3. Disappears automatically once cut.
- **Functional Behavior:** `TutorialGuide` node added to `LevelController` when `level_number == 1`. Tracks the first uncut `CuttableBase` ordered by `hint_order` and animates a sliding pointer between `center - 45 px` and `center + 45 px`.
- **Required Godot Systems:** `Node2D._draw()`, `LevelController.cut_made` signal, `SaveManager.tutorial_completed`.
- **Dependencies:** `CuttableBase.get_cut_center_global()`.
- **Acceptance Criteria:** Loading Level 1 displays the active tutorial guide; slicing all 3 targets completes the tutorial and marks `tutorial_completed = true` in `SaveManager`.
- **Priority:** **P0**

#### P0-3: Local Progress Saving, Star Ratings & Level Unlocking
- **Purpose:** Persist player progression, earned stars (`1–3★`), best move counts, and settings reliably across app restarts while remaining 100% offline.
- **Player Experience:** Level 1 starts unlocked; Levels 2+ show a lock icon (`🔒`) until the preceding level is won. Completing a level awards `1–3★` based on `moves_used` vs. `par_moves`, saves immediately, and unlocks the next level.
- **Functional Behavior:** Wire `SaveManager` into `Main`, add `.bak` backup file recovery on load/save, compute star rating in `LevelController._check_win_condition()`, and disable locked level buttons in the UI.
- **Required Godot Systems:** `ConfigFile`, `FileAccess`, `DirAccess`, `SaveManager`.
- **Dependencies:** `P0-1` (move counting).
- **Acceptance Criteria:** Automated test verifies levels 2–5 are locked on fresh state, winning Level 1 unlocks Level 2 and records 3 stars, and reloading `SaveManager` from disk restores exact state.
- **Priority:** **P0**

#### P0-4: Pause Menu & Sound / Haptic Settings
- **Purpose:** Give mobile players full control over pausing gameplay, audio volume/mute, haptics, and progress reset.
- **Player Experience:** Tapping `⏸` (or pressing Android Back / `ESC`) pauses physics, opens a clean modal with `Resume`, `Restart`, `Sound: ON/OFF`, `Volume: 25%..100%`, `Vibration: ON/OFF`, and `Reset Progress`.
- **Functional Behavior:** Set `get_tree().paused = true` when Pause modal opens; Pause modal runs under `PROCESS_MODE_ALWAYS`; updates `SfxManager.muted`, `SfxManager.volume_percent`, `SliceController.vibration_enabled`, and saves to `SaveManager`.
- **Required Godot Systems:** `SceneTree.paused`, `CanvasLayer`, `SfxManager`, `SaveManager`, `NOTIFICATION_WM_GO_BACK_REQUEST`.
- **Dependencies:** `P0-3` (`SaveManager`).
- **Acceptance Criteria:** Automated test verifies pausing freezes falling balls (`velocity` and `position` unchanged over 20 frames while paused), resuming unfreezes them, and toggling mute/volume persists to disk.
- **Priority:** **P0**

#### P0-5: Android Portrait Responsive Layout & Multi-Aspect Optimization
- **Purpose:** Ensure crisp, centered presentation without black bars or clipped UI across 16:9, 18.5:9, 20:9, and tablet/foldable portrait screens.
- **Player Experience:** Background cosmic grid fills the entire screen on tall 20:9 phones and wide foldables; the `720x1280` puzzle arena stays centered; top HUD respects camera notch safe areas.
- **Functional Behavior:** Set `window/stretch/aspect="expand"` in `project.godot`. In `Main`, compute viewport size and safe area insets on startup and `size_changed`, adjusting `_camera.offset` (base offset + shake offset) and HUD container margins dynamically.
- **Required Godot Systems:** `Window.size_changed`, `DisplayServer.get_display_safe_area()`, `Camera2D`, `Control` containers.
- **Dependencies:** `SliceController.screen_to_world()` (already uses `get_canvas_transform().affine_inverse()`).
- **Acceptance Criteria:** Automated test resizes root viewport to `720x1600` (20:9) and `900x1280` (tablet) and verifies `dispatch_real_touch_swipe()` still slices targets with 100% accuracy.
- **Priority:** **P0**

#### P0-6: Colorblind-Safe Geometric Ball & Container Emblems
- **Purpose:** Make all 4 ball colors (`RED`, `BLUE`, `YELLOW`, `GREEN`) and containers effortlessly distinguishable for players with deuteranopia, protanopia, or tritanopia.
- **Player Experience:** Each color displays a unique inner geometric emblem on both the rolling ball and the target container (`RED` = Twin Arcs, `BLUE` = Diamond, `YELLOW` = 4-Point Star, `GREEN` = Triangle).
- **Functional Behavior:** Update `PuzzleBall._draw()` and `ColorContainer._draw()` to draw `GameColors.draw_color_emblem(canvas_item, pos, radius, color_type, col)`.
- **Required Godot Systems:** `CanvasItem.draw_*` vector primitives.
- **Dependencies:** `scripts/game_colors.gd`.
- **Acceptance Criteria:** All 5 levels render distinct emblems per color with zero FPS impact.
- **Priority:** **P0**

---

### 2.2 P1 — Strong Engagement & Content Expansion Features

| ID | Feature Name | Purpose & Player Experience | Functional Behavior & Godot Systems | Dependencies | Acceptance Criteria | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P1-1** | **Chapter 1 Expansion (Levels 6–20)** | Expands playable campaign to 20 handcrafted levels introducing order-dependent bridges, decoy supports, pendulum launches, and `BumperPin` ricochets. | Add `BumperPin` (`StaticBody2D`, `bounce=0.85`) and level definitions `6..20` in `LevelData` + level selection grid screen. | `P0-1..P0-5` | All 20 levels pass automated headless touch-swipe solvability test (`test_runner.gd`) in `< 6.5 s` per level. | **P1** |
| **P1-2** | **Home Screen & Chapter Level Select Grid** | Provides a polished commercial front-end with total star count (`★ X / 60`) and scrollable level cards. | Add `HomeOverlay` and `LevelSelectModal` in `Main._ui_layer` with smooth fade/scale transitions. | `P0-3` | Player can navigate Home -> Level Select -> Any Unlocked Level -> Pause -> Home cleanly. | **P1** |
| **P1-3** | **Star Milestone Chest & Blade Trail Cosmetics** | Rewards players for earning 3★ ratings by unlocking new visual blade trails (*Solar Flame*, *Emerald Plasma*, *Rainbow Ribbon*) offline. | Store `unlocked_trails` and `selected_trail` in `SaveManager`; `SliceController._draw()` uses the selected trail palette. | `P0-3` | Earning threshold stars unlocks trail in UI and changes swipe trail color in gameplay. | **P1** |
| **P1-4** | **Chapters 2–3 Mechanics (`ColorFilterGate`, `ColorDyeRing`, `SeesawBridge`)** | Powers Levels 21–60 with color-sorting gates, ball-repainting rings, and tipping seesaw bridges. | Implement `ColorFilterGate` (collision mask filtering), `ColorDyeRing` (`Area2D` setting `ball.color_type`), and `SeesawBridge` (`Ramp` flipping angle on pass). | `P1-1` | Automated unit tests verify each new obstacle routes/blocks/repaints balls deterministically. | **P1** |
| **P1-5** | **Procedural Ambient Music Loop** | Adds a soothing, non-repetitive background synth pad with independent `Music: ON/OFF` setting. | Generate seamless looping ambient chord buffer in `SfxManager` on a dedicated low-volume `AudioStreamPlayer`. | `P0-4` | Music toggle mutes/unmutes ambient stream independently of SFX and persists in `SaveManager`. | **P1** |

---

### 2.3 P2 — Monetization, Retention & Live Readiness Features

| ID | Feature Name | Purpose & Player Experience | Functional Behavior & Godot Systems | Dependencies | Acceptance Criteria | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P2-1** | **Offline-Safe Ad & Billing Service Adapters** | Provides clean hooks for Rewarded Hints, Skip-Level after 3 fails, capped Interstitials (Lvl 11+, 180s cooldown), and `remove_ads` IAP without breaking offline play. | Implement `AdService`, `BillingService`, and `AnalyticsService` under `res://scripts/services/` with offline fallback defaults. | `P0-3`, `P0-4` | Simulated ad-load failure and offline state never block level progression or hint fallback. | **P2** |
| **P2-2** | **Daily Cascade Challenge (Offline Seeded)** | Gives players a fresh daily puzzle with a streak counter using the local calendar date. | Deterministic daily level selector using `Time.get_date_dict_from_system()` seed; tracks `daily_streak` in `SaveManager`. | `P1-1` | Daily level loads offline and records completion for the current date in `SaveManager`. | **P2** |
| **P2-3** | **Privacy & Consent Modal (GDPR / CCPA / UMP)** | Ensures full legal compliance in US states, UK, EU, and Australia before initializing ad SDKs. | Settings button + first-run consent check wrapper before `AdService.initialize()`. | `P2-1` | Consent state is stored locally and respected by `AdService` and `AnalyticsService`. | **P2** |

---

### 2.4 P3 — Future Expansion Features (Post-Launch Data-Driven)

| ID | Feature Name | Purpose & Player Experience | Functional Behavior & Godot Systems | Dependencies | Acceptance Criteria | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P3-1** | **Chapters 4–5 (`PortalPair`, Moving Deflectors, Levels 61–100)** | Completes the 100-level master campaign for long-term players. | Implement `PortalPair` (`Area2D` teleporter preserving velocity vector) and levels `61..100`. | `P1-4` | All 100 levels pass automated headless verification. | **P3** |
| **P3-2** | **Custom Level Sandbox / Shareable Level Codes** | Lets enthusiasts build and share compact base64 puzzle strings offline. | Serialize/deserialize level dictionary to base64 clipboard string. | `P1-1` | Exported level string imports and plays identically. | **P3** |

---

## 3. Critical Assessment, Risks & Recommended Design Improvements

As requested, here is a candid critical evaluation of the current game, challenging assumptions that could hurt commercial quality:

### 3.1 Critical Weaknesses in the Current Prototype & How to Fix Them
1. **Risk — "Swipe Everything Blindly" Syndrome (Low Cognitive Challenge in Levels 1–5):**
   - *Critique:* In the current 5 prototype levels, cutting all supports in almost any order (or swiping across the whole screen rapidly) still succeeds. If levels 6–100 work like that, players will get bored within 10 minutes because there is no *puzzle*, only chores.
   - *Design Improvement:* Starting in Level 6, **every level must include at least one meaningful wrong action**—either (a) an **Order Dependency** (e.g., cutting Beam A before Trigger B flips a bridge routes Red balls into the Blue container), or (b) a **Decoy / Trap Support** (a beam or rope holding a mismatched ball or blocker that must *not* be cut).
2. **Risk — Naive Procedural Level Generation Would Ruin Puzzle Quality:**
   - *Challenge to Common Assumption:* Many physics games attempt to auto-generate 100 levels with random ramp angles. In a 2D physics game, random angles produce frustrating edge-bounces, 50/50 luck outcomes, and visual mess.
   - *Design Improvement:* Do **not** use random runtime level generation. Instead, use **parameterized, handcrafted level templates validated by our headless physics test runner** (`test_runner.gd`) where every level has a verified `solution_steps` array that must win 100% deterministically in headless simulation.
3. **Risk — Kinematic Rope Hold vs. Dynamic Pendulum Physics:**
   - *Critique:* Currently, `CuttableRope` holds its attached ball using `FREEZE_MODE_KINEMATIC` (`freeze = true`) until cut. While this is great for determinism, a rope that cannot swing at all feels stiff if overused.
   - *Design Improvement:* Keep `FREEZE_MODE_KINEMATIC` for stationary vertical ropes (so resting states never drift), AND use `CuttableRope.release_impulse` (already supported in `cuttable_rope.gd` line 9!) plus an optional gentle visual sway animation on pendulum ropes so cutting a swinging rope launches the ball along a predictable arc!
4. **Risk — Mobile Thumb Occlusion & Top HUD Crowding:**
   - *Critique:* Currently, the top HUD in `main.gd` puts Level buttons `1..5` inside a small `34x28 px` strip on Row 2, which will not fit 20–100 levels and is too small for comfortable thumb tapping on a `6.1"` phone.
   - *Design Improvement:* Keep the in-game top HUD ultra-clean (`Level Title`, `Balls: X/Y`, `Cuts: X/Par`, `Hint 💡`, `Restart ↻`, `Pause ⏸` with `>= 44 px` touch targets) and move level browsing into a dedicated **Level Select Grid Overlay** accessible from the Pause Menu and Win/Fail screens (while keeping quick `1..5` buttons or a `Levels` button on the HUD).
5. **Risk — Existing Technical Debt (Signal Mismatch & Unwired SaveManager):**
   - *Critique:* As identified in Section 1.1, `slice_controller.gd` currently emits `object_sliced` with 3 arguments while `main.gd` listens with 2 arguments, and `save_manager.gd` is not yet wired into `main.gd`.
   - *Design Improvement:* Milestone M1 immediately resolves this wiring before adding any new features.

---

## 4. Milestone-Based Implementation Plan

*(Organized strictly by engineering milestones—no calendar-day estimates.)*

### Milestone M1: Core Gameplay Quality, Move Accounting & Save/Unlock Wiring (P0)
- **Objective:** Complete and verify all 10 requirements of the Gameplay Quality & Mobile-Readiness Phase on the existing 5-level project.
- **Features Included:**
  - Fix `object_sliced` signal signature between `slice_controller.gd` and `main.gd`.
  - Wire valid vs. invalid swipe move accounting (`moves_used`, `par_moves`, 1–3★ calculation).
  - Wire `SaveManager` (level unlocking `1..5`, star persistence, `.bak` corruption recovery).
  - Add interactive Level 1 `TutorialGuide` (animated swipe hand teaching cutting through gameplay).
  - Add Pause Menu & Sound/Haptic Settings modal (`Resume`, `Restart`, `Mute`, `Volume`, `Vibration`, `Reset Progress`).
  - Add colorblind-safe geometric emblems to `PuzzleBall` and `ColorContainer`.
  - Optimize portrait layout for diverse Android aspect ratios (`stretch/aspect="expand"` + dynamic camera centering).
- **Files to Modify / Create:**
  - Modify: `project.godot`, `scripts/main.gd`, `scripts/level_controller.gd`, `scripts/level_data.gd`, `scripts/game_colors.gd`, `scripts/ball.gd`, `scripts/container_bucket.gd`, `scripts/save_manager.gd`, `tests/test_runner.gd`.
  - Create: `scripts/tutorial_guide.gd`.
- **Dependencies:** Existing 5-level prototype.
- **Testing Requirements:** Headless test runner must verify: (1) all 5 levels solved via real `InputEventScreenTouch`/`InputEventScreenDrag` events, (2) invalid swipes consume `0` moves, (3) `SaveManager` unlocks levels sequentially and recovers from backup, (4) Pause menu freezes physics and saves audio settings, (5) multi-aspect viewport resize (`720x1600` and `900x1280`) preserves touch accuracy.
- **Acceptance Criteria:** `Godot_v4.7.2-stable_win64_console.exe --headless --path "d:\cut-and-cascade" -s "res://tests/test_runner.gd"` exits with code `0` and all M1 assertions pass.
- **Deliverables:** Fully playable, mobile-ready 5-level build with tutorial, pause/settings, save/unlock, and star ratings.
- **Risks:** Viewport transform changes under `expand` aspect ratio could shift touch coordinates if `screen_to_world()` is bypassed—mitigated by routing all touch tests through `dispatch_real_touch_swipe()`.

---

### Milestone M2: Front-End UI Polish, Home Screen, Level Select Grid & Chapter 1 Levels 6–20 (P1)
- **Objective:** Expand content to 20 handcrafted levels (introducing order-dependent puzzles, trap/decoy supports, and `BumperPin`s) and add commercial Home & Level Select screens.
- **Features Included:** `P1-1` (Levels 6–20 + `BumperPin`), `P1-2` (Home Screen + 20-Level Grid Overlay), `P1-5` (Procedural Ambient Music loop + toggle).
- **Files to Modify / Create:**
  - Create: `scripts/bumper_pin.gd`, `scenes/components/bumper_pin.tscn`, `scenes/levels/level_6.tscn` .. `level_20.tscn`.
  - Modify: `scripts/level_data.gd`, `scripts/level_controller.gd`, `scripts/main.gd`, `scripts/sfx_manager.gd`, `tests/test_runner.gd`.
- **Dependencies:** Milestone M1.
- **Testing Requirements:** Automated headless verification of all 20 levels (both pre-cut stability and touch-swipe solvability) + verification that cutting trap beams in decoy levels triggers `level_failed`.
- **Acceptance Criteria:** All 20 levels pass automated solvability tests with 3★ par moves verified.

---

### Milestone M3: Mid-Game Mechanics & Cosmetic Progression (Levels 21–60) (P1)
- **Objective:** Add Chapter 2 & 3 mechanics (`ColorFilterGate`, `ColorDyeRing`, `SeesawBridge`, uncuttable steel chains) and offline Star Chest / Blade Trail cosmetic unlocks.
- **Features Included:** `P1-3` (Blade Trail Cosmetics), `P1-4` (Chapters 2–3 obstacles & Levels 21–60).
- **Files to Modify / Create:**
  - Create: `scripts/color_filter_gate.gd`, `scripts/color_dye_ring.gd`, `scripts/seesaw_bridge.gd` + corresponding `.tscn` prefabs.
  - Modify: `scripts/level_data.gd`, `scripts/slice_controller.gd`, `scripts/save_manager.gd`, `scripts/main.gd`, `tests/test_runner.gd`.
- **Dependencies:** Milestone M2.
- **Testing Requirements:** Unit and integration tests for color filtering, ball repainting, seesaw tipping, and cosmetic trail unlocking.
- **Acceptance Criteria:** Levels 1–60 pass headless solvability suite with `< 16.6 ms` frame time.

---

### Milestone M4: Offline-Safe Monetization, Analytics & Privacy Adapters (P2)
- **Objective:** Integrate decoupled `AdService`, `BillingService`, `AnalyticsService`, Daily Cascade Challenge, and GDPR/CCPA/UMP privacy UI without breaking offline play.
- **Features Included:** `P2-1`, `P2-2`, `P2-3`.
- **Files to Modify / Create:**
  - Create: `scripts/services/ad_service.gd`, `scripts/services/billing_service.gd`, `scripts/services/analytics_service.gd`.
  - Modify: `scripts/main.gd`, `scripts/save_manager.gd`, `tests/test_runner.gd`.
- **Dependencies:** Milestone M2.
- **Testing Requirements:** Automated tests simulating offline mode, ad-load timeout, interstitial cooldown enforcement, and entitlement caching.
- **Acceptance Criteria:** Game remains 100% playable offline; ad/IAP failures never block UI or gameplay.

---

### Milestone M5: Master Campaign Completion (Levels 61–100) & Performance Hardening (P3)
- **Objective:** Add `PortalPair` teleporters, moving deflectors, Levels 61–100, and low-end Android particle/frame-time auto-scaling.
- **Features Included:** `P3-1` + low-end Android performance monitor.
- **Dependencies:** Milestone M3.
- **Acceptance Criteria:** Full 100-level automated solvability suite passes with zero memory leaks or orphan nodes.

---

### Milestone M6: Android Production Export, Device QA & Store Submission Readiness
- **Objective:** Configure Android export presets (`export_presets.cfg`), generate signed debug `.apk` and release `.aab` bundles, and complete physical device QA + Google Play store assets.
- **Dependencies:** Milestones M1–M4 + Developer Account/Keystore credentials from stakeholder.
- **Acceptance Criteria:** Signed `.aab` passes Google Play Internal Testing track upload and physical Android device lifecycle/safe-area checklist.

---

## 5. Items Requiring Your Explicit Approval

Before I begin implementing code in **Milestone M1**, please review and confirm:
1. **Approval of the 3 Specification Documents:** Confirm whether [GAME_DESIGN_SPEC.md](file:///d:/cut-and-cascade/docs/GAME_DESIGN_SPEC.md), [TECHNICAL_ARCHITECTURE.md](file:///d:/cut-and-cascade/docs/TECHNICAL_ARCHITECTURE.md), and [IMPLEMENTATION_ROADMAP.md](file:///d:/cut-and-cascade/docs/IMPLEMENTATION_ROADMAP.md) match your vision.
2. **Authorization to Begin Milestone M1 Implementation:** Confirm if you want me to proceed immediately with **Milestone M1** (completing the Gameplay Quality & Mobile-Readiness Phase: fixing the `object_sliced` signal signature, wiring `SaveManager` level unlocking & star ratings, adding the interactive Level 1 swipe tutorial, adding the Pause & Sound Settings menu, ensuring invalid swipes consume 0 moves, adding colorblind emblems, optimizing Android portrait aspect adaptation, and running the expanded automated test suite).
3. **Package / Application ID Preference (for Milestone M6):** Confirm if `com.cutandcascade.colorpuzzle` is acceptable as the default Android package identifier or if you prefer a custom domain namespace.
