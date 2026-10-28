# Dead Mile 0.2.0 — Android debug build

[Download APK](dead-mile-v0.2.0-android-arm64.apk?raw=true) · [Download ZIP](dead-mile-v0.2.0-android-arm64.zip?raw=true)

Source commit: [ae6c6ac721b6f2af0d495a795af6a3bd0ab18c3b](https://github.com/vdwMarius/zombie-highway-reimagined/commit/ae6c6ac721b6f2af0d495a795af6a3bd0ab18c3b)

This build adds a detailed clear-coat car, environmental reflections, a furnished home garage, textured mountain highway and Vulkan graphics. The source README includes current screenshots.

## Install

1. Open the APK link in a browser and download the file. If the browser refuses APK downloads, use the ZIP and extract the APK first.
2. Open the APK on your Android phone. Android may ask you to allow installation from the browser/file manager you are using. This is a development/debug build, not a Play Store release.
3. Start Dead Mile. Hold the phone in landscape, enter the highway and use CALIBRATE while holding it comfortably.

ARM64, Android 7/API 24 minimum, target API 36, compatible Vulkan graphics required. The Samsung Galaxy S26 Ultra is the intended first test phone; no physical device was attached during cloud validation. No Internet permission is requested.

Controls: tilt or hold bottom left/right to steer; FIRE shoots; RELOAD replenishes the magazine; PAUSE or Android Back pauses. LIVE/STATIC reflections can be compared in settings. Existing 0.1 progress is compatible when installed with the same debug signature.

Validated: 36 headless checks, 40 Vulkan-rendered checks, independent APK v2/v3 signature verification. Physical tilt, audio, installation, thermal behavior and sustained frame rate still need device testing. The software renderer reports an exit-time texture cleanup warning; see source development notes for known limitations.

## Integrity and attribution

Verify the downloaded APK/ZIP against SHA256SUMS.txt if needed. The ZIP contains the same signed APK plus attribution/license files.

Car Concept: Eric Chadwick / Darmstadt Graphics Group GmbH (2024), CC BY 4.0; based on a public-domain concept by Unity Fan. Adapted materials, paint, sample branding, wheel motion and modular parts. Full source: https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CarConcept. Barlow fonts: SIL OFL 1.1. Godot: MIT, https://godotengine.org/license/.
