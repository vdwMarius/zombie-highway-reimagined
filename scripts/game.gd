extends Node3D
## First vertical slice: recycled road, arcade driving, climbers and persistent garage.
const ArtFactory = preload("res://scripts/art.gd")
const GarageData = preload("res://scripts/progression.gd")
const SteeringInput = preload("res://scripts/steering.gd")
const RealScenery = preload("res://scripts/scenery.gd")
const WorkshopScene = preload("res://scripts/home_garage.gd")
const GOLD := Color("f2b35d")
const INK := Color("101d24")
const MUTED := Color("9baaa9")
const WHITE := Color("edf0df")
const BOLD = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
const REGULAR = preload("res://assets/fonts/Barlow-Regular.ttf")

var garage := GarageData.new()
var steering := SteeringInput.new()
var rng := RandomNumberGenerator.new()
var mode: String = "garage"
var car: Node3D
var camera: Camera3D
var world: Node3D
var garage_room: Node3D
var outdoor_environment: Environment
var road_probe: ReflectionProbe
var high_reflections: bool = true
var road_tiles: Array[Node3D] = []
var wrecks: Array[Node3D] = []
var zombies: Array[Dictionary] = []
var ui: Control
var hud: Control
var panel: Control
var distance_label: Label
var speed_label: Label
var health_bar: ProgressBar
var warning_label: Label
var ammo_label: Label
var roll_bar: ProgressBar
var speed: float = 0.0
var lateral: float = 0.0
var health: float = 100.0
var distance: float = 0.0
var lean: float = 0.0
var kills: int = 0
var ammo: int = 8
var reload_time: float = 0.0
var fire_cooldown: float = 0.0
var hit_cooldown: float = 0.0
var spawn_timer: float = 7.0
var elapsed: float = 0.0
var run_id: String = ""
var last_reward: int = 0
var selected: String = "Engine"
var flash: ColorRect
var shot_line: MeshInstance3D
var shot_timer: float = 0.0
var engine_audio: AudioStreamPlayer
var muted: bool = false
var save_message: String = ""
var testing: bool = "--test" in OS.get_cmdline_user_args()

func _ready() -> void:
	rng.seed = 90210
	if not testing and not garage.load_from():
		save_message = "Existing save could not be loaded. Original file preserved."
	steering.sensitivity = garage.sensitivity
	steering.tilt_enabled = garage.tilt_enabled
	build_world()
	garage_room = WorkshopScene.new()
	add_child(garage_room)
	build_car()
	build_ui()
	build_audio()
	show_garage()

func build_world() -> void:
	RealScenery.build(self)

func build_car() -> void:
	var x := 0.0
	if is_instance_valid(car):
		x = car.position.x
		car.queue_free()
	car = ArtFactory.vehicle(garage.levels)
	add_child(car)
	car.position.x = x

func lane_x(index: int) -> float:
	return [-3.8, 0.0, 3.8][index % 3]

func build_audio() -> void:
	if testing or DisplayServer.get_name() == "headless":
		return
	engine_audio = AudioStreamPlayer.new()
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 22050
	var samples := PackedByteArray()
	samples.resize(22050 * 2)
	for i in range(22050):
		var phase := float(i) * 40.0 / 22050.0 * TAU
		var value := int((sin(phase) * 0.6 + sin(phase * 2) * 0.2 + sin(phase * 3) * 0.12) * 16000)
		samples.encode_s16(i * 2, value)
	stream.data = samples
	engine_audio.stream = stream
	engine_audio.volume_db = -24
	add_child(engine_audio)
	engine_audio.play()

func pump_audio() -> void:
	if not is_instance_valid(engine_audio):
		return
	engine_audio.volume_db = -80 if muted or mode != "run" else -24
	engine_audio.pitch_scale = 0.8 + speed / 28.0

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme := Theme.new()
	theme.default_font = REGULAR
	theme.default_font_size = 20
	ui.theme = theme
	hud = Control.new()
	ui.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = Control.new()
	ui.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash = ColorRect.new()
	ui.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 0.35, 0.18, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

func label_at(parent: Node, text: String, pos: Vector2, size: int = 20, color: Color = WHITE, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", BOLD)
	parent.add_child(label)
	return label

func block(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.position = pos
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func button(parent: Node, text: String, pos: Vector2, size: Vector2, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.add_theme_font_override("font", BOLD)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", INK if primary else WHITE)
	b.add_theme_color_override("font_hover_color", INK if primary else GOLD)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = GOLD if primary else Color("233138")
		if state == "hover":
			style.bg_color = Color("ffd18b") if primary else Color("34454b")
		elif state == "pressed":
			style.bg_color = Color("b48449") if primary else Color("152329")
		elif state == "disabled":
			style.bg_color = Color("374244")
		style.border_width_bottom = 2
		style.border_color = Color("bf8a46") if primary else Color("53605e")
		b.add_theme_stylebox_override(state, style)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func clear_panel() -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()

func save_progress() -> void:
	if testing:
		return
	if not save_message.is_empty():
		return # Preserve an unrecognized/corrupt original save for recovery.
	if garage.save_to() != OK:
		save_message = "Progress could not be saved on this device."

func show_garage() -> void:
	mode = "garage"
	world.hide()
	garage_room.show()
	camera.environment = garage_room.environment
	garage_room.refresh_reflections()
	for zombie in zombies:
		zombie.node.queue_free()
	zombies.clear()
	if is_instance_valid(shot_line):
		shot_line.queue_free()
	hud.hide()
	clear_panel()
	steering.clear()
	car.position = Vector3.ZERO
	car.rotation = Vector3(0, PI + 0.12, 0)
	block(panel, Vector2.ZERO, Vector2(430, 900), Color(0.035, 0.075, 0.09, 0.95))
	block(panel, Vector2(40, 46), Vector2(42, 4), GOLD)
	label_at(panel, "AN ORIGINAL SURVIVAL DRIVING GAME", Vector2(40, 64), 14, MUTED)
	label_at(panel, "DEAD", Vector2(35, 88), 112, WHITE, true)
	label_at(panel, "MILE", Vector2(35, 191), 112, GOLD, true)
	label_at(panel, "BUILD IT. DRIVE IT. SURVIVE IT.", Vector2(40, 320), 19, WHITE, true)
	label_at(panel, "CEDAR LANE  /  HOME GARAGE", Vector2(40, 379), 16, MUTED)
	label_at(panel, "One road. No rescue.\nTake the wheel of the Nomad and make\nevery kilometer count.", Vector2(40, 415), 19, WHITE)
	button(panel, "HIT THE HIGHWAY   →", Vector2(40, 532), Vector2(350, 64), start_run, true)
	button(panel, "CONTROLS & SETTINGS", Vector2(40, 610), Vector2(350, 54), show_settings)
	label_at(panel, "A / D or ← / →  STEER\nSPACE  FIRE     R  RELOAD     ESC  PAUSE", Vector2(40, 698), 16, MUTED)
	label_at(panel, "ANDROID: TILT TO STEER · TAP FIRE\nTouch steering also available in settings.", Vector2(40, 757), 15, MUTED)
	button(panel, "CREDITS & LICENSES", Vector2(40, 808), Vector2(350, 32), show_credits)
	label_at(panel, "PROTOTYPE  0.2     /     VULKAN", Vector2(40, 854), 14, MUTED)
	label_at(panel, "HOME GARAGE  /  NOMAD GT", Vector2(470, 44), 25, WHITE, true)
	label_at(panel, "01", Vector2(470, 86), 72, Color("d4d8bd"), true)
	label_at(panel, "MIDNIGHT PETROL  /  TOURING COUPE", Vector2(550, 107), 16, WHITE)
	label_at(panel, "◇  %s SCRAP" % garage.credits, Vector2(1115, 44), 26, GOLD, true)
	label_at(panel, "BEST  %04d m" % int(garage.best), Vector2(1115, 83), 18, MUTED)
	# The part selector stays below the vehicle preview.
	block(panel, Vector2(458, 642), Vector2(948, 224), Color(0.035, 0.075, 0.09, 0.94))
	for i in range(GarageData.CATEGORIES.size()):
		var category: String = GarageData.CATEGORIES[i]
		var b := button(panel, category.to_upper(), Vector2(476 + i * 130, 658), Vector2(120, 42), func():
			selected = category
			show_garage(), category == selected)
		b.add_theme_font_size_override("font_size", 19)
	label_at(panel, "%s  /  LEVEL %d OF 3" % [selected.to_upper(), garage.levels[selected]], Vector2(481, 720), 27, WHITE, true)
	label_at(panel, GarageData.DESCRIPTIONS[selected], Vector2(481, 760), 18, MUTED)
	var level := int(garage.levels[selected])
	for i in range(3):
		block(panel, Vector2(481 + i * 55, 808), Vector2(45, 5), GOLD if i < level else Color("465352"))
	var buy := button(panel, "MAX LEVEL" if level == 3 else "UPGRADE · %s ◇" % garage.price(selected), Vector2(1120, 736), Vector2(262, 64), buy_selected, true)
	buy.disabled = level == 3 or garage.credits < garage.price(selected)
	label_at(panel, "Earn scrap by surviving and removing climbers.", Vector2(481, 832), 15, MUTED)
	if not save_message.is_empty():
		label_at(panel, save_message, Vector2(470, 601), 16, GOLD)

func show_credits() -> void:
	clear_panel()
	block(panel, Vector2(280, 120), Vector2(880, 660), Color(0.035, 0.075, 0.09, 0.98))
	label_at(panel, "BUILT TO KEEP GOING.", Vector2(330, 150), 48, GOLD, true)
	label_at(panel, "ASSET CREDITS / PROTOTYPE 0.2", Vector2(330, 220), 22, MUTED, true)
	label_at(panel, "CAR CONCEPT — Eric Chadwick / Darmstadt Graphics Group GmbH, 2024.\nCreative Commons Attribution 4.0 International (CC BY 4.0).\nBased on a public-domain concept by Unity Fan.\nSource: github.com/KhronosGroup/glTF-Sample-Assets / Models/CarConcept\nModified paint, sample branding, materials, wheels and modular parts.\ncreativecommons.org/licenses/by/4.0/\n\nGarage, highway, surface textures, UI and synthesized sound: original work.\nBarlow fonts: Jeremy Tribby / contributors, SIL Open Font License 1.1.\nGodot Engine: MIT license — godotengine.org/license\nFull attribution and license texts are included with the project.", Vector2(330, 270), 20, WHITE)
	button(panel, "BACK TO GARAGE", Vector2(330, 670), Vector2(780, 58), show_garage, true)

func buy_selected() -> void:
	if garage.purchase(selected):
		save_progress()
		build_car()
	show_garage()

func show_settings() -> void:
	clear_panel()
	block(panel, Vector2(340, 140), Vector2(760, 620), Color(0.035, 0.075, 0.09, 0.98))
	label_at(panel, "YOUR HANDS. YOUR RULES.", Vector2(380, 170), 48, GOLD, true)
	label_at(panel, "Tilt in landscape to steer. Hold the phone comfortably, then\ncalibrate. Tap FIRE for the most dangerous attached zombie.\nScrape your side against a wreck to remove a climber.\nCountersteer when the roll warning fills up.", Vector2(380, 242), 22, WHITE)
	button(panel, "STEERING: " + ("TILT + TOUCH" if steering.tilt_enabled else "TOUCH ONLY"), Vector2(380, 390), Vector2(325, 54), func():
		steering.tilt_enabled = not steering.tilt_enabled
		garage.tilt_enabled = steering.tilt_enabled
		save_progress()
		show_settings())
	button(panel, "SENSITIVITY: %.1f" % steering.sensitivity, Vector2(725, 390), Vector2(335, 54), func():
		steering.sensitivity = 0.6 if steering.sensitivity >= 1.8 else steering.sensitivity + 0.4
		garage.sensitivity = steering.sensitivity
		save_progress()
		show_settings())
	button(panel, "REFLECTIONS: " + ("LIVE" if high_reflections else "STATIC"), Vector2(380, 466), Vector2(325, 54), func():
		high_reflections = not high_reflections
		road_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS if high_reflections else ReflectionProbe.UPDATE_ONCE
		show_settings())
	button(panel, "AUDIO: " + ("OFF" if muted else "ON"), Vector2(725, 466), Vector2(335, 54), func():
		muted = not muted
		show_settings())
	label_at(panel, "Desktop: A/D or arrows · Space fire · R reload · Esc pause\nTouch: hold bottom left/right for steering · FIRE above the zones\nHigh preset: real-time reflections · Vulkan graphics required.", Vector2(380, 553), 18, MUTED)
	button(panel, "BACK", Vector2(380, 670), Vector2(680, 58), show_pause if mode == "paused" else show_garage, true)

func make_hud() -> void:
	for child in hud.get_children():
		hud.remove_child(child)
		child.queue_free()
	block(hud, Vector2(24, 24), Vector2(300, 112), Color(0.035, 0.075, 0.09, 0.88))
	label_at(hud, "ROUTE 09   /   ENDLESS", Vector2(44, 36), 16, GOLD, true)
	distance_label = label_at(hud, "0000 m", Vector2(42, 55), 48, WHITE, true)
	speed_label = label_at(hud, "0 KM/H", Vector2(210, 83), 17, MUTED)
	label_at(hud, "NOMAD  /  HULL", Vector2(44, 153), 16, WHITE, true)
	health_bar = ProgressBar.new()
	hud.add_child(health_bar)
	health_bar.position = Vector2(44, 181)
	health_bar.size = Vector2(260, 10)
	health_bar.show_percentage = false
	health_bar.max_value = garage.stats().health
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	health_bar.add_theme_stylebox_override("fill", fill)
	button(hud, "Ⅱ  PAUSE", Vector2(1268, 24), Vector2(148, 56), show_pause)
	warning_label = label_at(hud, "", Vector2(450, 38), 25, GOLD, true)
	warning_label.size.x = 540
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roll_bar = ProgressBar.new()
	hud.add_child(roll_bar)
	roll_bar.position = Vector2(560, 80)
	roll_bar.size = Vector2(320, 8)
	roll_bar.max_value = 1.0
	roll_bar.show_percentage = false
	roll_bar.add_theme_stylebox_override("fill", fill)
	button(hud, "FIRE", Vector2(1220, 630), Vector2(184, 92), fire, true)
	button(hud, "RELOAD", Vector2(1220, 734), Vector2(184, 48), begin_reload)
	ammo_label = label_at(hud, "08 / ∞", Vector2(1240, 586), 28, WHITE, true)
	button(hud, "CALIBRATE", Vector2(36, 716), Vector2(170, 50), func(): steering.calibrate())
	block(hud, Vector2(0, 810), Vector2(1440, 90), Color(0.035, 0.075, 0.09, 0.65))
	label_at(hud, "◀  HOLD TO STEER LEFT", Vector2(40, 840), 22, MUTED, true)
	label_at(hud, "HOLD TO STEER RIGHT  ▶", Vector2(1145, 840), 22, MUTED, true)
	label_at(hud, "TILT / A D TO STEER     ·     SPACE / FIRE TO SHOOT", Vector2(435, 840), 20, WHITE, true)

func start_run() -> void:
	clear_panel()
	for zombie in zombies:
		zombie.node.queue_free()
	zombies.clear()
	mode = "run"
	garage_room.hide()
	world.show()
	camera.environment = outdoor_environment
	car.position = Vector3.ZERO
	car.rotation = Vector3.ZERO
	speed = 12.0
	lateral = 0
	health = garage.stats().health
	distance = 0
	lean = 0
	kills = 0
	ammo = 8
	elapsed = 0
	reload_time = 0
	fire_cooldown = 0
	hit_cooldown = 0
	spawn_timer = 6
	run_id = "%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	steering.clear()
	steering.calibrate()
	for i in range(wrecks.size()):
		wrecks[i].position = Vector3(lane_x(i), 0, -60.0 - i * 48.0)
	make_hud()
	hud.show()

func show_pause() -> void:
	if mode != "run" and mode != "paused":
		return
	mode = "paused"
	steering.clear()
	clear_panel()
	block(panel, Vector2.ZERO, Vector2(1440, 900), Color(0.02, 0.045, 0.06, 0.72))
	label_at(panel, "TAKE A BREATHER.", Vector2(510, 220), 64, GOLD, true)
	label_at(panel, "Your run is paused.", Vector2(590, 310), 24)
	button(panel, "BACK ON THE ROAD", Vector2(510, 390), Vector2(420, 64), resume_run, true)
	button(panel, "CONTROLS & SETTINGS", Vector2(510, 472), Vector2(420, 58), show_settings)
	button(panel, "END RUN & COLLECT", Vector2(510, 548), Vector2(420, 58), func(): end_run("RETURNED TO OUTPOST"))

func resume_run() -> void:
	clear_panel()
	steering.clear()
	steering.calibrate()
	mode = "run"

func end_run(reason: String) -> void:
	if mode != "run" and mode != "paused":
		return
	mode = "results"
	last_reward = garage.settle(run_id, distance, kills)
	save_progress()
	hud.hide()
	clear_panel()
	block(panel, Vector2(420, 140), Vector2(600, 620), Color(0.035, 0.075, 0.09, 0.97))
	label_at(panel, "END OF THE ROAD", Vector2(465, 172), 68, GOLD, true)
	label_at(panel, reason, Vector2(468, 262), 18, MUTED)
	label_at(panel, "%04d" % int(distance), Vector2(465, 297), 100, WHITE, true)
	label_at(panel, "METERS SURVIVED", Vector2(680, 364), 20, MUTED, true)
	label_at(panel, "%d CLIMBERS REMOVED    /    + %d SCRAP" % [kills, last_reward], Vector2(468, 438), 24, GOLD, true)
	label_at(panel, "Spend your scrap on a stronger next run.", Vector2(468, 486), 20)
	button(panel, "ONE MORE RUN", Vector2(465, 555), Vector2(510, 62), start_run, true)
	button(panel, "BACK TO GARAGE", Vector2(465, 636), Vector2(510, 58), show_garage)
	if not save_message.is_empty():
		label_at(panel, save_message, Vector2(440, 717), 14, GOLD)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if mode == "run":
				show_pause()
			elif mode == "paused":
				resume_run()
		if mode == "run":
			if event.keycode == KEY_SPACE:
				fire()
			elif event.keycode == KEY_R:
				begin_reload()
	if mode == "run":
		# Canvas coordinates remain independent of window/device resolution.
		var transformed := event.xformed_by(get_viewport().get_canvas_transform().affine_inverse())
		steering.event(transformed, 1440, 900)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode == "run":
			show_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if mode == "run":
			show_pause()
		elif mode == "paused":
			resume_run()

func _process(delta: float) -> void:
	pump_audio()
	if not is_instance_valid(car):
		return
	var target := Vector3(5.8, 2.65, 6.0) if mode == "garage" else Vector3(car.position.x * 0.36, 3.8, 8.8)
	if mode == "garage":
		target.x += sin(Time.get_ticks_msec() * 0.00018) * 0.8
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 3.5))
	# Garage frames the vehicle in the free region to the right of its sidebar.
	var look := Vector3(-1.5, 0.45, 0) if mode == "garage" else Vector3(car.position.x * 0.6, 0.65, -10)
	camera.look_at(look)
	flash.color.a = move_toward(flash.color.a, 0, delta * 1.8)
	shot_timer = maxf(0, shot_timer - delta)
	if is_instance_valid(shot_line):
		shot_line.visible = shot_timer > 0

func _physics_process(delta: float) -> void:
	if mode != "run":
		return
	elapsed += delta
	var stats := garage.stats()
	var steer := steering.sample(delta)
	speed = move_toward(speed, stats.speed, delta * 2.5)
	lateral = move_toward(lateral, steer * float(stats.grip), delta * 12)
	car.position.x = clampf(car.position.x + lateral * delta, -5.4, 5.4)
	if absf(car.position.x) > 5.1:
		health -= delta * 8
		speed = move_toward(speed, 12.0, delta * 15)
	distance += speed * delta
	var weight := 0.0
	for zombie in zombies:
		if zombie.attached:
			weight += float(zombie.side) * (1.5 if zombie.heavy else 0.85)
	lean = move_toward(lean, (weight * 0.27 + steer * 0.1) / float(stats.stability), delta * 0.45 * float(stats.stability))
	# Countersteering reduces roll pressure; ignoring stacked attackers makes it grow.
	if absf(weight) > 1.0 and signf(steer) == -signf(weight):
		lean = move_toward(lean, 0, absf(steer) * delta * 0.65 * float(stats.stability))
	car.rotation.z = -lean + steer * 0.05
	car.rotation.y = -lateral * 0.025
	car.position.y = sin(elapsed * 16) * 0.006
	ArtFactory.animate_vehicle(car, delta, speed, steer)
	road_probe.position.x = car.position.x * 0.5
	if absf(lean) >= 0.95:
		end_run("ROLLED BY THE HORDE")
		return
	for tile in road_tiles:
		tile.position.z += speed * delta
		if tile.position.z > 42:
			tile.position.z -= 352
	for pole in get_tree().get_nodes_in_group("poles"):
		pole.position.z += speed * delta
		if pole.position.z > 35:
			pole.position.z -= 350
	hit_cooldown = maxf(0, hit_cooldown - delta)
	for wreck in wrecks:
		var previous_z := wreck.position.z
		wreck.position.z += speed * delta
		if previous_z < 3.8 and wreck.position.z > -3.8:
			var separation := absf(car.position.x - wreck.position.x)
			if separation < 1.85 and hit_cooldown <= 0:
				health -= stats.impact
				speed *= 0.5
				hit_cooldown = 0.8
				flash.color.a = 0.35
				car.position.x = clampf(car.position.x + signf(car.position.x - wreck.position.x + 0.001) * 0.5, -5.4, 5.4)
			elif separation >= 1.85 and separation < 2.75:
				scrape(signf(wreck.position.x - car.position.x))
		if wreck.position.z > 25:
			wreck.position.z -= 288
			wreck.position.x = lane_x(rng.randi_range(0, 2))
	spawn_timer -= delta
	if spawn_timer <= 0:
		if zombies.size() < 5:
			spawn_zombie()
		spawn_timer = maxf(2.3, 7.0 - elapsed * 0.035)
	update_zombies(delta)
	fire_cooldown = maxf(0, fire_cooldown - delta)
	if reload_time > 0:
		reload_time = maxf(0, reload_time - delta)
		if reload_time == 0:
			ammo = 8
	health_bar.value = health
	distance_label.text = "%04d m" % int(distance)
	speed_label.text = "%d KM/H" % int(speed * 3.6)
	ammo_label.text = "RELOADING…" if reload_time > 0 else "%02d / ∞" % ammo
	roll_bar.value = absf(lean)
	roll_bar.visible = absf(lean) > 0.25
	if elapsed < 5:
		warning_label.text = "TILT / A D TO STEER · AVOID THE WRECKS"
	elif absf(lean) > 0.45:
		warning_label.text = "COUNTERSTEER!  ROLL DANGER"
	elif not zombies.is_empty():
		warning_label.text = "CLIMBERS! FIRE OR SCRAPE THEM OFF"
	else:
		warning_label.text = "KEEP MOVING."
	if health <= 0:
		end_run("VEHICLE DESTROYED")

func spawn_zombie() -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var slot := rng.randi_range(0, 2)
	for candidate in zombies:
		if candidate.side == side and candidate.slot == slot:
			return
	var heavy := elapsed > 25 and rng.randf() < 0.4
	var node := ArtFactory.zombie(heavy)
	add_child(node)
	node.position = Vector3(side * 7.5, 0, -10)
	zombies.append({"node": node, "side": side, "slot": slot, "heavy": heavy, "hp": 100.0 if heavy else 65.0, "attached": false, "approach": 0.0})

func update_zombies(delta: float) -> void:
	for zombie in zombies:
		var node: Node3D = zombie.node
		if not zombie.attached:
			zombie.approach = minf(1, zombie.approach + delta * 0.65)
			var t: float = zombie.approach
			node.position = Vector3(lerpf(float(zombie.side) * 7.5, car.position.x + float(zombie.side) * 1.1, t), sin(t * PI) * 1.5, lerpf(-10, float(zombie.slot) * 0.95 - 0.9, t))
			if t >= 1:
				zombie.attached = true
		else:
			var attachment := Vector3(float(zombie.side) * 1.08, 0.25, float(zombie.slot) * 0.95 - 0.9)
			node.position = car.to_global(attachment)
			node.rotation = car.rotation + Vector3(0, -float(zombie.side) * PI / 2, -float(zombie.side) * 0.2)
			health -= delta * (2.2 if zombie.heavy else 1.1)

func remove_zombie(index: int) -> void:
	zombies[index].node.queue_free()
	zombies.remove_at(index)
	kills += 1

func scrape(side: float) -> void:
	for i in range(zombies.size() - 1, -1, -1):
		if zombies[i].attached and zombies[i].side == side:
			remove_zombie(i)
			flash.color = Color(0.95, 0.7, 0.3, 0.16)

func begin_reload() -> void:
	if mode == "run" and reload_time <= 0 and ammo < 8:
		reload_time = 1.6

func fire() -> void:
	if mode != "run" or fire_cooldown > 0 or reload_time > 0:
		return
	if ammo <= 0:
		begin_reload()
		return
	ammo -= 1
	fire_cooldown = 0.22
	var target := car.position + Vector3(0, 1.5, -22)
	var index := -1
	var priority := -1.0
	for i in range(zombies.size()):
		var score := (10.0 if zombies[i].attached else 0.0) + (3.0 if zombies[i].heavy else 0.0) + float(zombies[i].approach)
		if score > priority:
			priority = score
			index = i
	if index >= 0:
		target = zombies[index].node.position + Vector3(0, 0.85, 0)
		zombies[index].hp -= garage.stats().damage
		if zombies[index].hp <= 0:
			remove_zombie(index)
	if is_instance_valid(shot_line):
		shot_line.queue_free()
	var origin := car.to_global(Vector3(0, 1.47, -0.84))
	shot_line = ArtFactory.box(self, Vector3(0.035, 0.035, origin.distance_to(target)), (origin + target) / 2, "ffe8a0", 0, true)
	shot_line.look_at(target)
	shot_timer = 0.065

func _exit_tree() -> void:
	if is_instance_valid(engine_audio):
		engine_audio.stop()
		engine_audio.stream = null
	ArtFactory.release_cached_resources()
