extends SceneTree
## Run with -- --test; uses only a dedicated disposable save file.
const Garage = preload("res://scripts/progression.gd")
var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check("--test" in OS.get_cmdline_user_args(), "Smoke tests require --test to isolate persistence")
	if failures:
		quit(1)
		return
	var data := Garage.new()
	check(not data.purchase("Engine"), "Cannot purchase without funds")
	check(data.settle("one", 600, 2) == 180, "Distance and kills produce correct reward")
	check(data.settle("one", 600, 2) == 0 and data.credits == 180, "Repeated settlement cannot duplicate currency")
	check(data.purchase("Engine") and data.credits == 60, "Purchase deducts exact cost")
	check(data.stats().speed == 30.0, "Engine upgrade changes actual driving speed")
	check(not data.purchase("Missing"), "Invalid upgrade cannot be purchased")
	data.credits = 9999
	check(data.purchase("Engine") and data.purchase("Engine") and not data.purchase("Engine"), "Upgrade cap is enforced")
	var path := "user://smoke-garage.json"
	check(data.save_to(path) == OK, "Atomic save succeeds")
	var restored := Garage.new()
	check(restored.load_from(path), "Saved progress loads")
	check(restored.credits == data.credits and restored.levels.Engine == 3, "Save roundtrip preserves purchases")
	check(restored.settle("one", 600, 2) == 0, "Settled run remains settled after reload")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version": 999}')
	file.close()
	check(not restored.load_from(path), "Unsupported save schema rejected")
	check(FileAccess.get_file_as_string(path) == '{"version": 999}', "Rejected save stays untouched")
	DirAccess.remove_absolute(path)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	await process_frame
	check(game.mode == "garage", "Main scene reaches garage")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(80):
			game._process(1.0 / 60.0)
		await capture("garage")
	game.start_run()
	game.spawn_timer = 999 # Isolate combat fixtures from timed encounter spawns.
	check(game.mode == "run" and game.health == 100, "Run starts with clean base stats")
	var fire_touch := InputEventScreenTouch.new()
	fire_touch.index = 1
	fire_touch.pressed = true
	fire_touch.position = Vector2(1300, 680)
	game.steering.event(fire_touch, 1440, 900)
	check(game.steering.touches.is_empty(), "FIRE control does not also steer")
	# Drive via the same touch adapter used on phones.
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(1200, 850)
	game.steering.event(touch, 1440, 900)
	for i in range(30):
		game._physics_process(1.0 / 60.0)
	check(game.car.position.x > 0.3, "Touch steering moves car right")
	game.steering.clear()
	game.car.position.x = 0
	game.lateral = 0
	for wreck in game.wrecks:
		wreck.position.x = 50
	for i in range(120):
		game._physics_process(1.0 / 60.0)
	check(game.distance > 30, "Driving accumulates distance")
	var before: float = game.distance
	game.show_pause()
	game._physics_process(1)
	check(game.distance == before, "Pause freezes gameplay")
	game.resume_run()
	# Deterministic attached climber, then weapon damage/reload.
	game.spawn_zombie()
	check(game.zombies.size() == 1, "Climber enters run")
	for i in range(120):
		game._physics_process(1.0 / 60.0)
	check(game.zombies[0].attached, "Climber attaches to vehicle")
	check(game.health < 100, "Attached climber damages vehicle")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(100):
			game._process(1.0 / 60.0)
		await capture("driving")
	game.fire()
	game.fire_cooldown = 0
	game.fire()
	check(game.kills == 1 and game.zombies.is_empty(), "Weapon removes climber after sufficient damage")
	check(game.ammo == 6, "Shots consume ammo")
	game.begin_reload()
	for i in range(100):
		game._physics_process(1.0 / 60.0)
	check(game.ammo == 8 and game.reload_time == 0, "Reload restores magazine")
	game.spawn_zombie()
	var side: float = game.zombies[0].side
	game.zombies[0].attached = true
	game.scrape(-side)
	check(game.zombies.size() == 1, "Scraping the other side does not remove a climber")
	game.scrape(side)
	check(game.zombies.is_empty() and game.kills == 2, "Scraping occupied side removes climber and awards kill")
	# Sweep across obstacle's collision interval in one physics step.
	game.car.position.x = 0
	game.steering.clear()
	game.wrecks[0].position = Vector3(0, 0, -4)
	game.hit_cooldown = 0
	var hp: float = game.health
	game._physics_process(0.1)
	check(game.health < hp, "Wreck crossing collision interval damages hull")
	game.spawn_timer = 0
	game._physics_process(1.0 / 60.0)
	check(game.zombies.size() == 1, "Encounter timer spawns climber during run")
	game.end_run("TEST COMPLETE")
	check(game.mode == "results" and game.last_reward > 0, "End run settles rewards")
	var credits: int = game.garage.credits
	game.end_run("TEST COMPLETE")
	check(game.garage.credits == credits, "Repeated end event cannot duplicate reward")
	game.start_run()
	check(game.distance == 0 and game.kills == 0 and game.zombies.is_empty() and game.ammo == 8, "Retry resets run state")
	game.health = 0
	game._physics_process(1.0 / 60.0)
	check(game.mode == "results", "Zero hull ends a run")
	game.start_run()
	game.lean = 1.1
	game._physics_process(1.0 / 60.0)
	check(game.mode == "results", "Unrecoverable roll ends run")
	game.show_garage()
	check(game.mode == "garage", "Results can return to garage")
	game.queue_free()
	await process_frame
	print("SMOKE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results")
	var error := root.get_texture().get_image().save_png("res://test-results/%s.png" % name)
	check(error == OK, "Rendered screenshot saved: " + name)
