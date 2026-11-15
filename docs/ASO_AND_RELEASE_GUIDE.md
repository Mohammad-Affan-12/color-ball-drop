# Cut & Cascade: Color Puzzle — App Store Optimization (ASO) & Release Engineering Guide

## 1. Google Play Store Listing (US & Australia Primary Markets)

### Title Options (Max 30 Characters)
1. **Cut & Cascade: Color Puzzle** *(27 chars — Recommended)*
2. **Cut & Cascade: Physics Drop** *(27 chars)*
3. **Cut & Cascade: Slice Puzzle** *(27 chars)*

### Short Description Options (Max 80 Characters)
1. **Swipe to slice ropes & beams! Trigger chain reactions & sort colorful balls!** *(76 chars — Recommended)*
2. **Slice supports, trigger physics chain reactions, and match every colored ball!** *(78 chars)*
3. **100 offline physics puzzles! Swipe to cut ropes, warp portals & sort colors.** *(76 chars)*

### Full Store Description (Google Play & Apple App Store)
**One swipe can set off the ultimate chain reaction!**

Welcome to **Cut & Cascade: Color Puzzle**, a tactile 2D physics puzzle game where timing, order of operations, and precision slicing turn complex contraptions into deeply satisfying cascades.

Swipe your finger across wooden beams and taut ropes to release vibrant Red, Blue, Yellow, and Green balls. Watch gravity take over as balls ricochet off bumper pins, pass through color-selective laser gates, transform inside dye rings, tip dynamic seesaws, and warp through dimensional portals on their way to their matching collection buckets!

**KEY FEATURES:**
- **100 Hand-Crafted Physics Levels:** Progress through 5 distinct chapters—*The First Cut*, *Color Control*, *Physics Workshop*, *Cascade Factory*, and *Cascade Master*—with zero filler.
- **Tactile One-Finger Controls:** Designed from the ground up for portrait mobile play. Slice single supports or line up multi-cut combos in a single fluid swipe.
- **Rich Mechanical Depth:** Master 10 interactive contraptions including Steel Striker balls, Chain Reaction Triggers (⚡), Bumper Pins, Color Filter Gates, Color Dye Rings, Seesaw Bridges, Uncuttable Steel Chains, Linked Portals, and Moving Deflectors.
- **Fair, Player-First Design:** Invalid swipes in empty air or against uncuttable steel chains never waste a move. Earn up to 3 Stars per level by solving puzzles within par cuts!
- **Unlockable Blade Trails & Star Chests:** Customize your swipe with 8 vibrant blade trails (*Classic Slash*, *Neon Blue*, *Golden Spark*, *Rainbow*, *Electric*, *Crystal*, *Fire*, and *Cosmic*) earned through gameplay coins and Star Chest milestones.
- **Daily Cascade Challenge:** Test your mastery every day with a deterministic daily puzzle for bonus coin rewards and streak milestones.
- **100% Offline Playable:** No Wi-Fi? No problem. Every level, cosmetic, and daily challenge works completely offline on flights, commutes, and subways.
- **Colorblind Accessible:** Built-in geometric emblems (`●`, `◆`, `★`, `▲`, `⚙`) ensure every ball, gate, and container is crystal clear for all players.

---

## 2. Visual Store Assets & Creative Concepts

### App Icon Concept (`512×512`)
- **Foreground:** A glowing cyan/gold diagonal blade slash cutting through a taut amber rope, releasing a glossy crimson-red sphere (`●`) and cobalt-blue sphere (`◆`) surrounded by golden sparks.
- **Background:** Deep midnight-indigo rounded square (`#0F1424`) with a subtle radial glow so the vibrant spheres pop on both light and dark mobile home screens.

### 8 Store Screenshot Concepts (`1080×1920` Portrait)
1. **"SLICE TO TRIGGER THE CASCADE!"** — Action shot of a glowing blade slicing a beam on Level 1 while Red and Blue balls cascade down neon-trimmed ramps.
2. **"SET OFF CHAIN REACTIONS!"** — A heavy Steel Striker hitting a glowing cyan `⚡` Chain Trigger, shattering two gate beams simultaneously.
3. **"SORT EVERY COLOR!"** — Four color-coded buckets (`RED ●`, `BLUE ◆`, `YELLOW ★`, `GREEN ▲`) filling with celebratory confetti bursts.
4. **"TRANSFORM & FILTER!"** — Balls passing through a spinning Color Dye Ring and laser Color Filter Gates in Chapter 2.
5. **"WARP ACROSS PORTALS!"** — Cross-screen teleportation through linked violet and gold Portal Pairs in Chapter 4.
6. **"OUTSMART TRAPS & STEEL CHAINS!"** — Highlighting uncuttable Steel Chains and decoy supports (`✖`) that reward smart planning.
7. **"100 HAND-CRAFTED PUZZLES!"** — Clean view of the Chapter Selection screen showing 3-star ratings and Star Chest milestones.
8. **"CUSTOMIZE YOUR BLADE!"** — Showcase of the 8 unlockable Blade Trails (*Rainbow*, *Fire*, *Cosmic*) and offline play badge.

### 15–30 Second Promo Video Storyboard
- **0:00–0:03 (Hook):** Split-second close-up of a single swipe slicing two ropes at once (`MULTI-CUT x2!`), dropping a Steel Striker onto a `⚡` trigger.
- **0:03–0:10 (Core Loop):** Fast-cut montage of balls bouncing off Bumper Pins, changing color in Dye Rings, and warping through Portals into matching buckets.
- **0:10–0:16 (Tension / "Look Before You Cut"):** Show a player almost slicing a `✖` decoy rope, pausing, and instead slicing the true trigger rope to win 3 Stars (`★★★`).
- **0:16–0:22 (Progression & Cosmetics):** Rapid showcase of *Rainbow* and *Cosmic* blade trails slicing through Chapter 5 contraptions.
- **0:22–0:28 (Call to Action):** End card with **Cut & Cascade: Color Puzzle** logo, *"Play 100 Levels Free — Offline Ready"*, and Google Play / App Store badges.

### 3 Paid UA Ad Creative Concepts (US & Australia)
1. **"98% Fail Level 14!" (Order-of-Operations Hook):** Shows someone cutting the ramp beam before the bridge trigger (balls miss), followed by the correct 2-swipe sequence that lands a satisfying 3-star win.
2. **"One Swipe Multi-Cut Satisfaction" (ASMR / Tactile Hook):** Emphasizes crisp synthesized slice audio, spark bursts, and chain reactions with zero voiceover clutter.
3. **"Can You Solve the Portal Dye Puzzle?" (Brain-Teaser Hook):** Highlights Chapter 5's cross-screen portal + dye ring contraption, inviting puzzle fans to test their logic.

---

## 3. Android & iOS Build, Signing & Release Instructions

### Configured Project Export (`export_presets.cfg`)
- **Package ID:** `com.cutandcascade.colorpuzzle`
- **Version:** `1.0.0` (`version/code = 1`)
- **Target / Min SDK:** `target_sdk = 34`, `min_sdk = 24` (Android 7.0+)
- **Orientation:** Portrait (`window/handheld/orientation = 1`)
- **Permissions:** `VIBRATE` enabled; no unnecessary camera/microphone/location permissions requested.
- **Presets Included:**
  - `Preset 0`: `Android Debug APK` (`build/android/CutAndCascade-debug.apk`)
  - `Preset 1`: `Android Release AAB` (`build/android/CutAndCascade-release.aab`)

### Installing Godot 4.7.2 Export Templates (Required for Binary Packaging)
On this workstation, Android SDK (`C:\Users\Personal\AppData\Local\Android\Sdk`) and the debug keystore (`C:\Users\Personal\AppData\Roaming\Godot\keystores\debug.keystore`) are already configured in Godot 4.7 editor settings, while the `C:\Users\Personal\AppData\Roaming\Godot\export_templates\4.7.2.stable` folder is currently empty.
1. In the Godot 4.7.2 Editor, open **Editor → Manage Export Templates…** and click **Download and Install** (or place `Godot_v4.7.2-stable_export_templates.tpz` contents into `%APPDATA%\Godot\export_templates\4.7.2.stable\`).
2. Once installed, build the Debug APK from the command line:
   ```powershell
   & "D:\Godot_v4.7.2-stable_win64_console.exe" --headless --path "d:\cut-and-cascade" --export-debug "Android Debug APK" "build/android/CutAndCascade-debug.apk"
   ```
3. For Google Play production upload, generate a private release upload keystore (never commit `.keystore` files or passwords to Git):
   ```powershell
   keytool -genkey -v -keystore release-upload.keystore -alias cutandcascade -keyalg RSA -keysize 2048 -validity 10000
   ```
   Supply the keystore path, user, and password via environment variables (`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`) and run:
   ```powershell
   & "D:\Godot_v4.7.2-stable_win64_console.exe" --headless --path "d:\cut-and-cascade" --export-release "Android Release AAB" "build/android/CutAndCascade-release.aab"
   ```

### iOS Preparation Checklist (macOS + Xcode)
- All gameplay, audio synthesis (`SfxManager`), local persistence (`SaveManager`), and touch handling (`SliceController`) use 100% cross-platform Godot 4.7 APIs with zero Android-exclusive dependencies in core scenes.
- When building on macOS with Xcode 16+:
  1. Add an **iOS** export preset in Godot with Bundle Identifier `com.cutandcascade.colorpuzzle`.
  2. Configure Apple Developer Team ID and Provisioning Profile in Xcode.
  3. Wire `StoreKit 2` plugin signals to `scripts/services/billing_service.gd` (`restore_purchases()` button is already exposed in the Settings screen as required by App Store Review Guideline 3.1.1).
