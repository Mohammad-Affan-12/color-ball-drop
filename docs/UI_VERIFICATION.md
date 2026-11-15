# Cut & Cascade UI and platform verification

Verified with Godot **4.7.2 stable (official)** on Windows. Screenshots are actual desktop Godot OpenGL renders from SubViewports at the stated pixel dimensions. Touch checks inject Godot screen-touch events through the existing SliceController. **No physical Android/iOS device or mobile emulator testing was performed.**

The current navy, teal and gold design is preserved. The header's nominal height is reduced from 180 to 158 logical units. The instruction and 96-unit action buttons share a VBoxContainer, so wrapping instructions push upward without intersecting the buttons. The camera fits the measured level geometry between the actual header and footer rectangles. Bounds include container labels, support hints, the arena travel corridor and moving-part envelopes. The bounds are sampled once per level, and the frame changes only on layout/viewport changes; it never follows falling balls.

Readability improvements affect drawing only: stronger platform highlights, ball rims, thicker rope strokes, larger upright hint numbers, clearer bucket counters and a short objective-counter color pulse. Ball radii, collision shapes, masses, gravity, release impulses, level definitions, solution steps and save format remain unchanged.

| Verification | Actual result |
| --- | --- |
| Existing regression suite | **100/100 levels passed**, plus save/checksum/backup recovery, economy, services, move accounting, steel rejection, wrong-color/decoy failures and restart/next-level navigation |
| Added platform checks | Both original three-cut solutions passed; static collisions, rope freeze/release states, gate collision removal, trigger connections and ramp rotation checked |
| All 100 real level layouts at six resolutions | **39,270 assertions, zero failures** |
| Rendered screen checks | **14,535 assertions, zero failures, 21 screenshots** |
| Platform capture checks | **106 assertions, zero failures, four before/after screenshots** |
| Requested portrait sizes | 540×960, 720×1280, 1080×1920 |
| Additional portrait sizes | 540×1170, 1080×2400, 768×1024 |
| Safe area coverage | Simulated notch/home-indicator insets; physical device safe-area behavior remains unverified |

Layout checks load every actual level at every size, exercising the real title and instruction. They check label fit, instruction/button separation, modal bounds and scrolling access, button text fit, retained ball/container collision properties, stable camera transforms and world/screen coordinate round trips. Renderer checks also dispatch a real touch swipe at each resolution. The full regression suite independently exercises original solution timings, including touch input for the first five levels and chapter endpoints.

The central V is intentionally different between the two onboarding levels:

| Part | Intended behavior | Observed behavior |
| --- | --- | --- |
| Level 1 return ramps at (250,555) and (470,555) | Stay fixed at −20° and +20° after cuts | Stayed fixed; original solution won in three cuts |
| Level 3 central ramps | Start at +12°/−12°, then rotate to −20°/+20° after the steel striker activates the trigger | Both ramps reached the target angles and their collision transforms followed |
| Gold beam supports | Break and disable their static collision, rather than become rigid-body debris | Collision layers cleared and shapes disabled after cutting/triggering |
| Rope-held balls | Freeze in place before cutting; unfreeze on release | Freeze states and collection validated |
| Joints/anchors | Ramps are StaticBody2D nodes; no Joint2D or rigid-body hinge participates in this construction | No missing joint or stuck ramp freeze state was found |
| Trigger wiring | Sensor body_entered → trigger → linked beams/ramps → level chain signal | Connections and activation verified |

**No platform physics change was needed.** Adding a gravity collapse would alter the existing solution and was not done.

Visual evidence:

- [Gameplay, 540×960](screenshots/corrected_gameplay_540x960.png)
- [Gameplay, 720×1280](screenshots/corrected_gameplay_720x1280.png)
- [Gameplay, 1080×1920](screenshots/corrected_gameplay_1080x1920.png)
- [Tall portrait, 1080×2400](screenshots/corrected_gameplay_1080x2400.png)
- [Chapter 5 composition](screenshots/corrected_mastery_720x1280.png)
- [Upright hints](screenshots/corrected_hints_720x1280.png)
- [Level 1 before cuts](screenshots/corrected_platform_level1_before_720x1280.png) / [after cuts](screenshots/corrected_platform_level1_after_720x1280.png)
- [Level 3 before trigger](screenshots/corrected_platform_level3_before_720x1280.png) / [after trigger](screenshots/corrected_platform_level3_after_720x1280.png)

Raw evidence: [regression log](screenshots/regression-validation.log), [all-level layout log](screenshots/layout-validation.log), [rendered verification JSON](screenshots/corrected-verification.json), [platform verification JSON](screenshots/platform-verification.json), [platform renderer log](screenshots/platform-capture.log).

Run from the project directory, replacing the executable path as needed:

```powershell
& 'D:\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_runner.gd --fixed-fps 60 --log-file .tools/regression.log
& 'D:\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/capture_ui_screenshots.gd --fixed-fps 60 --log-file .tools/layout.log
& 'D:\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --audio-driver Dummy --disable-render-loop --script res://tests/capture_ui_screenshots.gd --fixed-fps 60 -- --capture
& 'D:\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --audio-driver Dummy --disable-render-loop --script res://tests/capture_ui_screenshots.gd --fixed-fps 60 -- --capture --platform-capture
```

Tests use isolated saves in the ignored .test-user directory; the player's normal save is not used by these runs.
