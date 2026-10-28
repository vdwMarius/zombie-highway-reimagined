# Development notes — prototype 0.1

## What is implemented

Godot Compatibility rendering, landscape viewport with aspect-preserving scaling, shared tilt/touch/keyboard steering adapter, fixed-step arcade movement, bounded/recycled road and wrecks, light and heavy climbers, one auto-targeted roof weapon, reload, scraping, roll failure, persistent scrap/part ownership, visible upgrade parts, and garage/results/settings screens.

The plan's milestones are intentionally not marked complete: Android export is verified but physical-phone input/performance checks remain open. Art is a coherent procedural starting point rather than final production assets. The first build has one weapon and two enemy variants; the third enemy, weapon switching, animated characters, full tutorial, quality presets and deeper upgrade tradeoffs are future work.

`game.gd` currently composes the world and first loop so handling can be evaluated without asset dependencies. `art.gd`, `steering.gd` and `progression.gd` are independent modules. Split run simulation, UI and encounter management into separate scenes/modules before expanding content. Pool zombies/effects and batch repeated geometry when profiling identifies the device bottleneck; the road and wreck counts are already bounded.

## Prepared cloud tooling

- Godot 4.6.3: `/usr/local/bin/godot`.
- Writable XDG data/config/cache: `/workspace/tooling/xdg/` via `tools/godot.sh`.
- Official Android debug/release templates: `/workspace/tooling/xdg/data/godot/export_templates/4.6.3.stable/`. Downloaded from Godot's official GitHub release and verified against its SHA-512 manifest before extraction.
- Android SDK: `/workspace/tooling/android-sdk/`. Command-line tools 19.0 verified against Google's repository manifest checksum; SDK Manager installed platform-tools 37.0.1, build-tools 35.0.1 and platform Android 35 with verification enabled.
- Java: `/usr/lib/jvm/java-21-openjdk-amd64`. Verified for this prebuilt-template APK export; no Gradle or NDK build was needed. Godot's general documentation recommends JDK 17 for its full Android build workflow.
- Editor settings point at those SDK/Java paths. The editor creates its standard debug-only keystore under the writable Godot data directory. No release key is present in source control.
- The native template targets API 36; the non-Gradle exporter successfully signs and verifies it using build-tools 35.0.1, with a fallback-version notice. A future custom Gradle build needs the matching SDK/build dependencies, not merely these templates.
- Android tools also use their standard `~/.android` directory. It was created for this instance because the home directory otherwise had no writable Android cache. Do not relocate or overwrite the user's home directory to work around tooling.

For rendered cloud checks, an unprivileged Xvfb executable was extracted from Debian's signed package index into `/workspace/tooling/xvfb/root/usr/bin/Xvfb`. Launch it with `:99 -screen 0 1440x900x24 -nolisten tcp -ac`, then run the rendered test with `DISPLAY=:99`. It is a software-rendered visual check, not a phone performance benchmark. An existing desktop display is sufficient on developer machines.

## Fresh workstation setup

1. Install Godot **4.6.3** and its matching official Android export templates. Preserve TLS and artifact verification.
2. Install the Android SDK platform-tools and build-tools (35.0.1 was validated here). Use a compatible JDK, normally JDK 17 according to Godot's Android export guide.
3. Start Godot through `tools/godot.sh --editor` if using the wrapper, then configure Java SDK Path and Android SDK Path under Editor Settings → Export → Android. Install templates in that same editor instance's data directory.
4. Import the project, run the smoke checks, then export with the committed Android preset. No SDK, keystore or editor configuration belongs in the checkout.

Official guide: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html. The exporter from the installed engine remains authoritative when a documentation example lists older package versions.

## Validation and remaining device checks

Automated checks validate the loop and persistence, and a rendered run captures screenshots for inspection. APK signing verification and manifest inspection validate packaging only. They do not establish that Android GPU drivers, sensors, app lifecycle or thermal behavior work correctly.

Before calling the Android milestone complete, install on a physical ARM64 phone and record model/OS/build: verify neutral calibration and tilt sign, touch steering while firing, orientation/letterboxing/cutouts, Back/pause/resume, save persistence after force-close, audio comfort, and a 15-minute session's frame times/temperature. Tune handling and art based on those results. Do not claim device testing from the cloud's software renderer.

Validated in this instance on 2026-10-28:

- Headless import and gameplay suite: **36 checks, zero failures**.
- Rendered Compatibility/llvmpipe gameplay suite: **38 checks, zero failures**, including garage/driving screenshot capture and visual inspection. The software driver reports that V-Sync changes are unsupported; no frame-rate claim is made. Tests deliberately skip audio playback.
- Native ARM64 debug APK export succeeded. Independent `apksigner verify --verbose` passed APK Signature Schemes v2/v3. Manifest inspection confirmed API 24 minimum, API 36 target, ARM64 code and no requested Internet permission.
- `adb devices` ran successfully; **no physical Android device was attached**. Device installation, sensors, audio and performance remain unrun.

Generated outputs live in ignored `builds/` and `test-results/`; rebuild rather than commit the APK. The cloud configuration draft contains import-refresh and startup/check instructions. Publishing the prepared environment remains a user action in environment settings.
