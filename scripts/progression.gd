class_name Progression
extends RefCounted
## The only writer of currency and upgrade ownership. No engine scene dependencies.

const PATH := "user://garage.json"
const CATEGORIES := ["Engine", "Tires", "Armor", "Bumper", "Spoiler", "Suspension", "Weapon"]
const DESCRIPTIONS := {
	"Engine": "More speed. Faster recovery after an impact.",
	"Tires": "Wider tires. Quicker lateral response.",
	"Armor": "Reinforced bodywork. More starting durability.",
	"Bumper": "Heavy steel. Less damage when you hit a wreck.",
	"Spoiler": "Extra stability. Resist high-speed roll pressure.",
	"Suspension": "Stronger springs. Recover from leaning sooner.",
	"Weapon": "Upgraded roof mount. More damage per shot."
}
var credits: int = 0
var best: float = 0.0
var levels: Dictionary = {}
var settled_runs: Array = []
var sensitivity: float = 1.0
var tilt_enabled: bool = true
var load_warning: String = ""

func _init() -> void:
	for category in CATEGORIES:
		levels[category] = 0

func price(category: String) -> int:
	return 120 + int(levels.get(category, 0)) * 180

func purchase(category: String) -> bool:
	if not levels.has(category) or int(levels[category]) >= 3 or credits < price(category):
		return false
	credits -= price(category)
	levels[category] = int(levels[category]) + 1
	return true

func settle(run_id: String, meters: float, kills: int) -> int:
	if run_id.is_empty() or settled_runs.has(run_id):
		return 0
	var reward := maxi(0, int(meters / 4.0)) + maxi(0, kills) * 15
	credits += reward
	best = maxf(best, meters)
	settled_runs.append(run_id)
	return reward

func stats() -> Dictionary:
	return {
		"speed": 28.0 + int(levels.Engine) * 2.0,
		"grip": 5.0 + int(levels.Tires) * 0.8,
		"health": 100.0 + int(levels.Armor) * 25.0,
		"impact": 28.0 - int(levels.Bumper) * 5.0,
		"stability": 1.0 + int(levels.Spoiler) * 0.17 + int(levels.Suspension) * 0.2,
		"damage": 34.0 + int(levels.Weapon) * 15.0
	}

func save_to(path: String = PATH) -> Error:
	var data := {"version": 1, "credits": credits, "best": best, "levels": levels,
		"settled_runs": settled_runs, "sensitivity": sensitivity, "tilt": tilt_enabled}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path)

func load_from(path: String = PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version") != 1:
		load_warning = "Save unreadable. A fresh garage is available; original file preserved."
		return false
	# Validate every field before assigning any state.
	var raw_levels: Variant = parsed.get("levels")
	if not raw_levels is Dictionary:
		return false
	for category in CATEGORIES:
		var value: Variant = raw_levels.get(category, 0)
		if not (value is float or value is int) or value < 0 or value > 3 or value != int(value):
			return false
	for key in ["credits", "best", "sensitivity"]:
		var value: Variant = parsed.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or value < 0:
			return false
	var runs: Variant = parsed.get("settled_runs", [])
	if not runs is Array or not parsed.get("tilt", true) is bool:
		return false
	for run in runs:
		if not run is String:
			return false
	credits = clampi(int(parsed.credits), 0, 100000000)
	best = float(parsed.best)
	for category in CATEGORIES:
		levels[category] = int(raw_levels.get(category, 0))
	settled_runs = runs
	sensitivity = clampf(float(parsed.sensitivity), 0.4, 2.0)
	tilt_enabled = parsed.get("tilt", true)
	return true
