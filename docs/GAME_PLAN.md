# Zombie Highway Reimagined — development plan

## Product direction

An Android-first, landscape 3D survival driving game: steer through an abandoned highway, shake off zombies climbing onto the vehicle, shoot dangerous attackers, and spend earnings rebuilding one increasingly formidable car.

Zombie Highway 2 is the reference for the core driving/combat rhythm. Earn to Die is the reference for the satisfaction of turning a basic vehicle into a visibly upgraded survival machine. Use original names, artwork, audio and interface layouts, with properly licensed third-party assets where appropriate. Capture the clarity and pace of the references without reproducing their screens or assets.

The first release is a polished, offline, single-player vertical slice. No multiplayer, advertising, accounts, purchases, open world, or vehicle roster. These would dilute the driving and upgrade work before it is proven.

## Technology decision

- **Engine:** Godot 4.6.3, currently installed in the development environment. Use typed GDScript and native engine features; reserve C++ extensions for measured bottlenecks.
- **Rendering:** Forward Mobile / Vulkan for the realistic automotive direction requested after the initial prototype. Use clear-coat PBR materials and local reflection probes. Target the user’s Samsung Galaxy S26 Ultra first; measure real-device performance before expanding the supported tier. Use native Android exports.
- **Authoring:** Godot editor for scenes and tuning; a text editor with GDScript support for code. Keep the project usable without a paid IDE or plugin. Blender can supply custom meshes once the visual prototype is approved.
- **Delivery:** desktop development build for fast iteration, Android debug APK for device testing, signed release APK/AAB later. Android export templates, SDK/JDK compatibility, and signing are separate setup work; engine availability alone does not prove Android builds work.
- **Versioning:** commit source scenes, scripts, resources, import settings, and asset license records. Ignore generated imports, build outputs, SDKs, and signing secrets.

Godot fits the small scope, rapid iteration, native sensor access, and modest build overhead. Unreal can deliver excellent results but brings substantially larger tooling and rendering costs for this particular slice. Visual quality will come from art direction, animation, lighting, and feedback rather than engine complexity alone.

## First playable scope

| Area | Initial commitment |
| --- | --- |
| Vehicle | One detailed touring coupe with modular upgrade mounting points |
| Environment | One mountain highway, assembled from reusable road chunks |
| Driving | Automatic acceleration, tilt steering, speed loss from damage/obstacles, recoverable roll danger |
| Zombies | Three roles: light climber, heavy destabilizer, armored attacker |
| Weapons | Three vehicle-mounted weapon options: sidearm, shotgun, automatic weapon |
| Upgrades | Engine, tires, suspension, bumper, armor, spoiler, weapon mount |
| Progression | One currency; three upgrade levels per vehicle category, with visible part changes |
| Modes | Endless survival plus a short interactive first-run tutorial |
| Persistence | Local settings, currency, purchases, best run, tutorial completion |

Initial balance targets are hypotheses: runs should last roughly 2–4 minutes for a new player, a first upgrade should be affordable after the first completed run, and early purchases should offer meaningful alternatives rather than one mandatory choice. Tune using playtests.

## Core loop and controls

1. Enter the garage, inspect the equipped parts, and choose an affordable upgrade or weapon.
2. Start a run with a brief countdown and steering calibration.
3. Tilt to weave between wrecks. Zombies approach, leap, and attach to specific vehicle slots.
4. Use the touchscreen to target an attached zombie and fire the selected weapon. Side swipe zones switch weapons; essential controls must not overlap Android system gestures.
5. Scrape a vehicle side against a wreck to remove attached zombies, accepting collision risk. A heavy attacker increases roll pressure on its side.
6. Survive increasing pressure until the vehicle is destroyed or rolls beyond recovery. Distance and kills award currency through a single settlement step.
7. Review the run summary, then retry or return to the garage.

Tilt is the primary steering input. Read gravity/accelerometer data through a sensor adapter, map it correctly to the locked landscape orientation, calibrate neutral, filter noise, apply a dead zone, and clamp the result. Make sensitivity, inversion, recalibration, and reduced camera shake available. Pause and recalibrate safely after an app interruption or orientation change. Validate sign, latency, and comfort on real hardware; simulated sensor values cannot establish this.

Provide touch steering as an accessible fallback and keyboard steering plus pointer targeting for desktop development. All input routes produce the same steering and combat commands. Do not implement a separate desktop game.

## Driving model

Use a custom arcade vehicle controller, not a full drivetrain simulation. Keep the car near a stable world origin and advance/recycle road content around it. Represent forward speed, lateral velocity, yaw, visual suspension, and roll pressure explicitly. Use fixed physics updates and swept collision checks where needed to avoid missed impacts.

Separate simulation state from visual body motion: suspension bounce and camera shake should not make the controls unpredictable. Actual collision, damage, and roll failure remain consistent with what the player sees. A configurable recovery window lets the player countersteer against a heavy zombie before tipping becomes irreversible.

Prototype steering response, readable obstacles, side scrapes, and roll recovery before building the economy. If driving is not enjoyable without upgrades, progression will not fix it.

## Upgrade system

| Category | Gameplay effect | Visible change / tradeoff |
| --- | --- | --- |
| Engine | Acceleration and recovery after impacts | Intake/exhaust changes; added speed demands better control |
| Tires | Lateral grip and steering response | Wider tread and wheel changes |
| Suspension | Roll resistance and recovery | Ride height and suspension pieces; tune separately from grip |
| Bumper | Impact protection and scraping effectiveness | Increasingly reinforced front/side protection; adds mass |
| Armor | Durability and resistance to zombie damage | Modular plates; mass reduces acceleration |
| Spoiler | High-speed stability | Three silhouette changes; limited benefit at low speed |
| Weapon mount | Recoil control and reload performance | Visible bracket/turret changes |

Weapon upgrades separately tune damage, magazine capacity, and reload time within explicit caps. Use authored definitions for costs, stats, meshes, and descriptions. Compute final vehicle stats from base data plus purchased/equipped modifiers in one place. Clearly show the before/after effect and any tradeoff before purchase.

Purchases validate balance and ownership, deduct once, and save atomically. Run rewards are settled once using a run identifier, including after an interrupted results screen. Include a save schema version, corruption recovery, and migration path. Never grant currency every time the results UI opens.

## Interface and visual direction

The interface follows a familiar mobile flow: title → garage/play → run → results → garage/retry. Start in a furnished home garage. Later location-specific garage scenes can use distinct lighting, materials and layouts; only the first garage is in the initial slice. The garage is the central hub with a large real-time vehicle preview, category tabs, part inspection, comparison, price, and one clear purchase/equip action. Settings and pause remain shallow and easy to reach.

Use an original industrial salvage style: charcoal panels, warm amber highlights, pale legible typography, restrained hazard markings, and a consistent icon language. Keep the driving HUD sparse: distance, vehicle health, ammo/reload, weapon selection, and roll danger. Confirm destructive actions, but avoid confirmation dialogs on routine retries.

Target realistic automotive presentation: detailed curved coachwork, clear-coat paint, alloy wheels, tinted glass, textured concrete/asphalt, local environmental reflections, and practical garage lighting. Keep exposure and material response coherent. Reflections use probes rather than ray tracing; allow a static-reflection setting for performance comparisons. Characters need an eventual rigged production-art pass to match the vehicle fidelity.

Plan asset replacement early: primitives are acceptable for the driving proof, but the visual milestone must include the actual car silhouette, zombie animation, environment palette, upgrade parts, HUD styling, sound effects, and responsive feedback. Track source and redistribution license for every external asset, font, and audio file.

## Architecture

Keep systems small and driven by resources rather than a global script containing the whole game.

```text
project.godot
scenes/       boot, garage, run, results, reusable vehicle/zombie/road scenes
scripts/
  core/       run state, scene transitions, settings, persistence
  input/      tilt adapter, touch/keyboard mapping, calibration
  driving/    arcade movement, impacts, roll pressure
  combat/     attachment slots, zombie states, weapons, damage
  world/      chunk recycling, spawn director, difficulty
  progression/ upgrade calculation, purchase validation, reward settlement
  ui/         garage, HUD, results, settings
data/         vehicle, upgrades, weapons, zombies, encounter definitions
assets/       models, materials, textures, animation, audio, fonts, licenses
tests/        deterministic logic tests and reproducible smoke scenarios
```

Use a small set of autoloads for settings/persistence and scene transitions. Keep run state local to each run. Use signals for UI updates and explicit APIs for damage and purchases. Seed the spawn director for reproducible failures. Pool road chunks, zombies, projectiles, and effects; cap their counts.

## Delivery order and acceptance gates

### 1. Project foundation and Android pipeline

Create the Godot project, input abstraction, scene transitions, a minimal landscape HUD, and export configuration without credentials. Run it on desktop and produce an Android debug build. Verify installation, touch, sensors, app pause/resume, and audio on a physical phone when one is available. Establish asset licensing records and build instructions.

**Gate:** a repeatable desktop run and Android build; phone-dependent checks recorded explicitly if hardware is unavailable. Do not defer the first Android export until the end.

### 2. Driving proof

Implement the arcade car, chase camera, recycled highway, obstacle impacts, tilt calibration, and roll/recovery model. Use temporary art. Add a repeatable slalom and scrape scenario.

**Gate:** readable, responsive steering; stable collisions; consistent frame-rate-independent behavior; recovery feels learnable. Validate tilt on a phone before locking handling values.

### 3. Survival combat

Add the zombie approach/leap/attach/remove/death states, attachment slots, weapons/reloading, damage, escalating encounters, loss conditions, and pause/retry. Ensure a spawn does not create an unavoidable immediate collision.

**Gate:** a complete run can end, restart, and end again without stale zombies, duplicated rewards, or leaked run state. Scraping, shooting, and countersteering each serve a useful purpose.

### 4. Garage and persistent progression

Add currency settlement, the upgrade definitions, visual part swaps, weapon selection, comparison UI, settings, and local saves. Connect title, garage, gameplay, and results into one loop.

**Gate:** earn → buy → visibly improve → restart app → retain progress. Test insufficient funds, repeated purchase input, interrupted results, and damaged save data.

### 5. Visual and audio vertical slice

Replace prototype assets with a coherent vehicle/environment/zombie set. Finish lighting, animation, HUD, garage presentation, responsive sound, and pooled effects. Review screenshots and gameplay captures together for visual consistency.

**Gate:** the playable build looks intentional throughout, including menus, transitions, upgrade previews, and failure states. Maintain readability on a small phone screen.

### 6. Android hardening and balance

Profile real devices, tune object and effect budgets, test several aspect ratios/cutouts, large touch targets, sensor absence, backgrounding, and repeated runs. Add quality presets and tune the economy only after the loop is reliable.

**Gate:** installable release candidate with recorded device/build versions, known issues, license inventory, and repeatable packaging instructions. Release signing remains local/secure; no keys in source control.

## Performance and validation

Provisional target: sustained 60 FPS on a mid-range Android phone, with a stable 30 FPS low preset. Evaluate frame-time spikes and thermal behavior during at least a 15-minute session, not only the title screen. Establish concrete draw-call, geometry, memory, and active-zombie budgets from the first representative device capture rather than inventing unsupported numbers now.

Use bounded spawn counts, pooled effects, limited transparent overdraw, compressed textures, shared materials, simple collision shapes, and modest dynamic shadows. Gameplay should not require Internet access.

Automate deterministic tests for stat calculations, purchase validation, one-time rewards, save migration/recovery, spawn bounds, and run resets. Use headless engine checks for scene/resource loading and logic; use rendered desktop smoke tests for UI and gameplay. Headless checks do not validate rendering, touch comfort, Android sensors, or device performance.

For each milestone record what ran, what passed, what failed, and what still needs a physical phone. No claims of Android readiness based only on a desktop window or successful APK export.

## Current evidence and assumptions

- The selected repository currently contains only its README and an initial commit; no game or tests exist yet.
- Godot 4.6.3 and Java are available in this cloud instance. Android SDK/export templates and device access have not been established.
- Current presentation is landscape, offline, and realistic automotive 3D; one vehicle and one environment keep the initial scope bounded.
- The existing README mentions UE5. This plan deliberately selects Godot; update the README when implementation begins so documentation matches the actual project.
- Exact Android minimum version, device tier, engine export requirements, and final asset sources will be established during the first milestone. No Epic account or Unreal download is required for this approach.

The next implementation task is milestone 1 followed by the driving proof. Build the smallest playable slice first, then use its handling and performance evidence to guide the remaining work.

## Direction update — 2026-10-28

The user requested a realistic art style, reflective cars, a home garage and later garages themed to locations. Version 0.2 implements the first home garage and the automotive rendering foundation. It does not claim completed photorealistic environments, production characters or garage unlock progression. The original stylized prototype remains in the first implementation commit for comparison.
