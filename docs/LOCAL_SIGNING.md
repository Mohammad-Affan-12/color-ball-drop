# Local Android signing

Release signing values are empty in tracked export presets. The previously configured values were preserved in `.tools/android-release-signing.local.json`, which is ignored by Git. Do not copy that local file into commits, release artifacts or logs.

`tools/export_android_release.ps1` supplies Godot's signing environment variables from your existing process environment, falling back to the ignored local file. It restores the previous process environment on exit and never uploads or publishes. Run it only when you intend to create a signed local release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./tools/export_android_release.ps1
```

The execution-policy argument applies only to this process; no machine policy is changed. On another machine or CI, supply `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` through local environment settings or a secret store. The private signing file is not needed if all three are supplied this way. Debug builds continue to use the existing debug key.

Removing a credential from current files does not remove it from previous Git commits. Previous history was not rewritten; change the previously committed password before sharing the repository. The signing keystore itself has not been changed.
