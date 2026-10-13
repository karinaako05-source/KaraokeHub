# KaraokeHub Next 🎤✨

Modern Next-Gen Flutter Karaoke Player with Native BASS/MIDI Audio Engine.

## Features
- **Modern Glassmorphic UI:** OLED True Dark theme (`#090B10`) with vibrant cyan (`#00F2FE`) & neon purple (`#9B51E0`) accents.
- **Package ID:** `com.karaokehub.next` (Runs side-by-side with `com.karaokehub.pro` without conflict).
- **Native Audio Engine Bridge:** Connects Flutter UI via `MethodChannel` directly to high-performance C++ `libbass.so` and `libbassmidi.so` binaries.
- **Automated CI/CD:** Builds downloadable `.apk` files on every git push via GitHub Actions.

## Automated Builds
Check the **Actions** tab on GitHub to download the latest compiled `app-release.apk` artifact.

## Song Library and Essential Assets

The songbook loads real songs from device storage and `shubidx`/`shubblob`; no demo songs are bundled. Keep the matching index and blob files together in a supported storage directory and grant All Files Access.

Only keypad sounds (`num_0` through `num_9`) and the five score fanfares are bundled. The Cheer button reuses the existing perfect-score fanfare.

## Playback Verification

GitHub Actions runs Dart analysis and playback regression tests before producing the release APK. The tests cover playback failure, tuning resets, obsolete completion/lyrics events, score timer cancellation, silent/disabled scoring, catalog reload coalescing, automatic SoundFont persistence, and player disposal during polling.

The generated APK still needs playback verification on an Android device with the actual song library and SoundFont. Mocked Flutter tests do not exercise native audio output.
