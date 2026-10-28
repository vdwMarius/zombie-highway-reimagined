# Changes

## 0.2.0 — Reflective automotive / home garage

- Replace the block-built SUV with a detailed licensed concept coupe, adapted with clear-coat blue paint, alloy wheels, tinted glass, working wheel rotation and modular upgrades.
- Switch to Forward Mobile / Vulkan, 4× MSAA and local reflections. The home garage has an interior box-projected capture; the highway has a live capture of the moving surroundings. Exclude the player from its own reflection capture.
- Add a furnished residential workshop with practical lighting, windows, workbench, storage and textured concrete/plaster/wood. Add a location-style resource for future themed garages; only the home garage is available now.
- Add textured asphalt, mountain terrain, vegetation, rails and road lights. Replace cube-like enemies with organic stand-ins; production character animation remains future work.
- Correct imported AO texture coordinates so the baked map does not stain reflective body panels. Disable source AO on the paint where the source declares zero occlusion strength.
- Add in-game asset attribution and a LIVE/STATIC reflection control. Preserve existing driving/combat/progression and save compatibility.
- Strengthen rendered screenshot checks to reject blank initial Vulkan frames.
- Publish the APK/ZIP/checksum separately on the GitHub `builds` branch, with direct links from the source README.

This build is a debug-signed ARM64 prototype. The Samsung Galaxy S26 Ultra is the intended test device; actual installation, tilt, audio, thermal performance and sustained frame rate still require that phone.

## 0.1 — Initial playable

Initial Android project, keyboard/touch/tilt input, procedural highway, wrecks, zombie attachment/combat, shooting/reloading, garage upgrades, persistent progress and smoke tests.
