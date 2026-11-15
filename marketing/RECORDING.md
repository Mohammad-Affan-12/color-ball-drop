# Reproducible genuine gameplay captures

These tools replay the project's real solution swipes through the running physics game, with an isolated `.test-user/marketing_capture.cfg` save. They are automated demonstrations, not recordings of a human playtest. No player's progress is modified. Analytics, ads, hints and sound are disabled in capture runs. Do not describe failed captures as finished clips.

## Generated files verified locally

| File | Genuine recorded solution | Encoded output | Duration / size |
| --- | --- | --- | --- |
| [videos/level-3.mp4](videos/level-3.mp4) | Level 3, three cuts, solved | Silent H.264, 720×1280, 30 fps | 9.534 seconds / 518,918 bytes |
| [videos/level-61.mp4](videos/level-61.mp4) | Level 61, six cuts, solved | Silent H.264, 720×1280, 30 fps | 10.000 seconds / 436,363 bytes |

These generated movies were captured at 540×960 and 60 fps, then scaled and encoded to the output sizes above. Source and export resolutions are deliberately distinguished. FFprobe verified the final video streams; [asset-manifest.json](asset-manifest.json) records matching SHA-256 hashes. Contact sheets under `videos/review-level-*.png` show recorded progress and a real win. Suggested narration, hook text, captions and hashtags in CONTENT.md are editorial drafts and have not been added to these silent masters. No videos have been published.

## Reproduce or record variants

From the repository root in PowerShell (replace tool paths on another machine):

```powershell
$godot = 'D:/Godot_v4.7.2-stable_win64_console.exe'
& $godot --path . --rendering-method gl_compatibility --fixed-fps 60 --script tools/record_gameplay.gd -- --screenshots
& $godot --path . --rendering-method gl_compatibility --script tools/build_store_art.gd
& $godot --path . --resolution 720x1280 --rendering-method gl_compatibility --fixed-fps 60 --write-movie marketing/videos/level-3.avi --script tools/record_gameplay.gd -- --level=3
& .tools/ffmpeg.exe -y -i marketing/videos/level-3.avi -vf 'scale=720:1280:flags=lanczos,setsar=1' -r 30 -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p -an -movflags +faststart marketing/videos/level-3.mp4
& .tools/ffprobe.exe -v error -show_entries format=duration:stream=width,height,r_frame_rate -of json marketing/videos/level-3.mp4
```

For the portal clip, repeat the movie command with `--level=61` and `marketing/videos/level-61.avi`, then encode/probe `level-61` using the same FFmpeg settings. The explicit `--resolution 720x1280` in the example requests that input size for a new capture; verify what the movie writer actually reports rather than assuming it matches the original captures.

Use a real renderer, not `--headless`, for movie/image capture. `--fixed-fps 60` preserves the puzzle simulation timing regardless of encoding speed. FFmpeg output is 720×1280 at 30 fps; check the recorded input resolution rather than claiming it was captured at that resolution. The CLI must print `solved=true` and exit 0. Review the entire MP4 for dropped cuts, clipped text and a genuine win; inspect source and final frame counts. A recording may spend several seconds on the result screen: trim the silent hold for posting, without changing the order/speed of the puzzle solution. Raw AVI is a local intermediate, not a social upload asset.

For a phone recording: connect a personally owned test device, install the debug APK manually, disable analytics, enable airplane mode, hide notifications, set portrait orientation and record 1080×1920 using Android's screen recorder. Keep in-game controls visible. For ADB use `adb shell screenrecord --size 720x1280 --bit-rate 6000000 /sdcard/cascade.mp4`, stop after the attempt, then `adb pull /sdcard/cascade.mp4 marketing/videos/`. Get permission before recording anyone else's device or voice.

Add hook text in the safe top area without obscuring the puzzle, 2–6 words per beat. Keep subtitles clear of platform overlays at the bottom/right. Upload separate clean files to YouTube Shorts, TikTok and Instagram Reels manually; no platform watermark. Use original voice or platform-cleared music only. Do not use misleading autoplay footage or show paid ad screens. The scripts/captions in CONTENT.md are drafts for owner review.
