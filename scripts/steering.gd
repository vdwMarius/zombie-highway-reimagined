class_name Steering
extends RefCounted
## Landscape-locked sensor adapter; touch/keyboard share the same output.
var neutral: float = 0.0
var filtered: float = 0.0
var calibrated: bool = false
var touches: Dictionary = {}
var sensitivity: float = 1.0
var tilt_enabled: bool = true

func calibrate() -> void:
	var gravity := Input.get_gravity()
	neutral = gravity.x if gravity.length() > 0.1 else Input.get_accelerometer().x
	filtered = 0.0
	calibrated = true

func clear() -> void:
	touches.clear()
	filtered = 0.0

func event(input: InputEvent, width: float, height: float) -> void:
	if input is InputEventScreenTouch:
		if input.pressed and input.position.y >= height * 0.9:
			touches[input.index] = -1.0 if input.position.x < width * 0.5 else 1.0
		else:
			touches.erase(input.index)
	elif input is InputEventScreenDrag and touches.has(input.index):
		touches[input.index] = -1.0 if input.position.x < width * 0.5 else 1.0

func sample(delta: float) -> float:
	var desired := 0.0
	if OS.get_name() == "Android" and tilt_enabled:
		if not calibrated:
			calibrate()
		var gravity := Input.get_gravity()
		var x := gravity.x if gravity.length() > 0.1 else Input.get_accelerometer().x
		desired = clampf((x - neutral) / 3.8 * sensitivity, -1.0, 1.0)
		if absf(desired) < 0.06:
			desired = 0.0
	var keyboard := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if keyboard != 0:
		desired = keyboard
	for value in touches.values():
		desired = float(value)
	filtered = lerpf(filtered, desired, 1.0 - exp(-delta * 10.0))
	return filtered
