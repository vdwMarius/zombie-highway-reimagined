# Development notes — 0.2.0

## Current direction

Dead Mile targets a realistic automotive look on recent Vulkan-capable Android phones. The user's test device is a Samsung Galaxy S26 Ultra (16 GB RAM). This is a target, not a tested-device claim: no phone is attached to the cloud environment.

The renderer is now **Godot Forward Mobile / Vulkan**, with 4× MSAA and a 256-pixel reflection atlas. Compatibility screenshots from 0.1 do not validate this renderer. The hero vehicle uses detailed licensed geometry, normal/occlusion maps, clear-coat metallic paint, tinted glass and alloy materials. A moving local reflection probe captures the roadside surroundings; a separate box-projected interior probe captures the home workshop and lights. The car is excluded from its own capture layer. This is environment-probe reflection, not ray tracing or screen-space reflection.

The home garage has concrete/plaster/wood materials, practical ceiling lights, windows, storage, tools and a workbench. `GarageStyle` resources separate location identity, palette and lighting from gameplay; only the starting Cedar Lane garage is implemented/unlocked. Later locations need their own authored rooms and unlock rules.

The highway now uses textured asphalt, smooth shaded terrain, tree cutouts, rails and roadside lights. Surface textures and vegetation are original generated assets. Organic zombie stand-ins remain prototype art and need a production rig/animation pass. The one-weapon combat/upgrade loop from 0.1 remains intact.

## Source structure

- `scripts/game.gd`: first loop, camera, scene visibility, menus and combat. Split run/UI responsibilities into scenes before expanding content further.
- `scripts/art.gd`: licensed vehicle adaptation, wheel animation, modular parts, enemy stand-ins and geometry helpers.
- `scripts/scenery.gd`: outdoor environment, recycled highway and moving reflection probe.
- `scripts/home_garage.gd`, `scripts/garage_style.gd`, `data/garages/home.tres`: residential workshop and location configuration.
- `scripts/steering.gd`: shared landscape tilt, touch and keyboard input.
- `scripts/progression.gd`: purchases, calculated stats, one-time rewards and versioned atomic persistence.
- `tools/generate_surfaces.py`: optional asset regeneration using Python, NumPy and Pillow. Generated assets are committed; Python is not required to run/export the game.

## Run and validate

Use the existing checkout; do not create a worktree unless explicitly requested. From the repository root:

```sh
bash tools/godot.sh --headless --editor --import --quit
bash tools/godot.sh --headless --script tests/smoke.gd -- --test
bash tools/godot.sh --editor
bash tools/godot.sh --headless --export-debug Android builds/dead-mile-v0.2.0-android-arm64.apk
```

A rendered run needs Vulkan drivers plus a display. This cloud machine uses Xvfb and Mesa's software Vulkan driver. They verify rendering correctness only; their frame rates are not representative of the phone:

```sh
/workspace/tooling/xvfb/root/usr/bin/Xvfb :99 -screen 0 1440x900x24 -nolisten tcp -ac
# In another shell; use the existing server if :99 is already active:
VK_DRIVER_FILES=/workspace/tooling/vulkan/lvp.json DISPLAY=:99 \
  bash tools/godot.sh --audio-driver Dummy --script tests/smoke.gd -- --test --capture
```

The Vulkan ICD is extracted from Debian's `mesa-vulkan-drivers` package, obtained through its signed package index; the local ICD manifest points at the extracted library. First-time shader compilation under the software driver can take minutes. Captures wait for rendered frames and check image content rather than accepting a blank clear-color image. Shader caches live outside the checkout.

## Prepared Android tooling

- Godot 4.6.3: `/usr/local/bin/godot`.
- Writable XDG data/config/cache: `/workspace/tooling/xdg/`, selected by `tools/godot.sh`.
- Official Android debug/release templates: `/workspace/tooling/xdg/data/godot/export_templates/4.6.3.stable/`, verified against Godot's official SHA-512 release manifest.
- Android SDK: `/workspace/tooling/android-sdk/`. Verified command-line tools 19.0; platform-tools 37.0.1, build-tools 35.0.1, platform Android 35.
- Java: `/usr/lib/jvm/java-21-openjdk-amd64`, verified for the prebuilt-template export workflow. Godot's broader Android build guide recommends JDK 17; no custom Gradle/NDK build is involved here.
- Editor settings select those paths. Debug signing uses the editor-generated development keystore outside source control. No release key is configured.
- The prebuilt native template targets API 36 and successfully signs with build-tools 35.0.1, emitting a fallback-version notice. A future Gradle build requires matching SDK/build dependencies.
- Android tools also use their standard `~/.android` directory, created for this instance. Live display/adb processes do not survive environment publication.

On another workstation, install the matching Godot templates, Java and Android SDK, launch the editor through the wrapper, and set Editor Settings → Export → Android SDK/Java paths. Preserve TLS, signature and checksum verification. Official guide: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html.

## Delivery

Source goes to `main`. Versioned APK/ZIP files, checksums and install notes go to the separate `builds` branch, so GitHub can serve a real download without a cloud-local workspace link. The GitHub release API was unavailable in this environment; the standard Git transport is used instead. Do not commit SDKs, generated engine caches or signing keys.

This is a signed **debug** ARM64 build, minimum API 24 / Android 7 and target API 36. The high graphics preset additionally needs a compatible Vulkan driver. The S26 Ultra is the intended initial device. APK signature/manifest checks establish packaging, not installation or playability on that phone.

## Required phone pass

Install the new build and check neutral calibration, steering sign, simultaneous touch/fire, Android Back, background/resume, save persistence, audio and cutouts/letterboxing. Compare LIVE and STATIC reflections in settings. Record frame times, thermal behavior and memory during a 15-minute session before changing the default quality preset or claiming sustained 60 FPS. Production character assets, extra weapons, tutorial and later garage/location progression remain future work.

## Validation of 0.2.0 (2026-10-28)

- Headless gameplay/persistence suite: **36 checks, zero failures**.
- Vulkan Forward Mobile rendering suite: **40 checks, zero failures**, including nonblank garage/highway captures inspected against the actual build. Paint AO/UV mapping was corrected after visual inspection exposed black patches.
- Version 0.2.0 / versionCode 2 ARM64 APK export passed; independent APK Signature Scheme v2/v3 verification passed. `aapt2` parsed the manifest and confirmed the target and architecture. The older `aapt` tool rejects the exporter's string-encoded Vulkan feature booleans; `aapt2` accepts them. An adaptive themed-icon resource warning comes from the prebuilt template; the standard launcher icon is present.
- The software Vulkan runner reports **14 texture RIDs at process shutdown** after the scene is freed. This remains an exit-time resource-cleanup warning to investigate; the suite does not establish memory stability over long sessions. No performance claim is made from the software driver.
- No Android phone was available for installation, sensors, audio, lifecycle or thermal tests.
