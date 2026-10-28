class_name Art
extends RefCounted
## Licensed detailed vehicle plus original modular upgrades and scene primitives.
static var palette: Dictionary = {}
static var vehicle_scene: PackedScene
static var vehicle_materials: Dictionary = {}

static func mat(hex: String, metallic: float = 0.0, glow: bool = false) -> StandardMaterial3D:
	var key := hex + str(metallic) + str(glow)
	if palette.has(key):
		return palette[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.metallic = metallic
	material.roughness = 0.23 if metallic > 0.5 else 0.72
	if glow:
		material.emission_enabled = true
		material.emission = Color(hex)
		material.emission_energy_multiplier = 1.8
	palette[key] = material
	return material

static func box(parent: Node3D, size: Vector3, at: Vector3, color: String, metallic: float = 0.0, glow: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat(color, metallic, glow)
	parent.add_child(node)
	node.position = at
	return node

static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: String, top: float = -1.0, segments: int = 10) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	node.mesh = mesh
	node.material_override = mat(color)
	parent.add_child(node)
	node.position = at
	return node

static func vehicle(levels: Dictionary, wreck: bool = false) -> Node3D:
	if vehicle_scene == null:
		vehicle_scene = load("res://assets/vehicles/concept/CarConcept.gltf")
	var root := Node3D.new()
	var visual := Node3D.new()
	visual.name = "Coachwork"
	root.add_child(visual)
	visual.rotation.y = PI
	visual.position = Vector3(0, 0.16, 0.24)
	var imported := vehicle_scene.instantiate()
	visual.add_child(imported)
	for node in imported.find_children("*", "MeshInstance3D", true, false):
		# The player's layer is excluded from its own reflection capture.
		node.layers = 1 if wreck else 2
		for surface in range(node.mesh.get_surface_count()):
			var original: Material = node.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D:
				continue
			var key := original.resource_name + ("_wreck" if wreck else "_hero")
			if not vehicle_materials.has(key):
				var material: StandardMaterial3D = original.duplicate()
				# This asset's baked occlusion uses glTF TEXCOORD_1 (Godot UV2).
				# Reading it from UV1 produces black triangular stains on the body.
				material.ao_on_uv2 = true
				if "Paint 1" in key:
					material.ao_enabled = false
					material.albedo_color = Color("29353d") if wreck else Color("3585a0")
					material.metallic = 0.48 if wreck else 0.55
					material.roughness = 0.83 if wreck else 0.22
					material.clearcoat_enabled = not wreck
					material.clearcoat = 0.95
					material.clearcoat_roughness = 0.08
					material.normal_enabled = false
				elif "Paint 2" in key:
					material.ao_enabled = false
					material.albedo_color = Color("161e23")
					material.metallic = 0.65
					material.roughness = 0.28 if not wreck else 0.9
				elif "Glass" in key:
					material.albedo_color = Color(0.065, 0.1, 0.12, 0.72)
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					material.metallic = 0.28
					material.roughness = 0.06
					material.clearcoat_enabled = true
					material.clearcoat = 1.0
				elif "Rim" in key or "Hardware" in key:
					material.metallic = 0.95
					material.roughness = 0.2
				vehicle_materials[key] = material
			node.set_surface_override_material(surface, vehicle_materials[key])
		if wreck and ("Interior" in node.name or "Engine" in node.name):
			node.hide()
	for node in imported.find_children("Wheel*", "Node3D", true, false):
		if node.name in ["WheelFrontL", "WheelFrontR", "WheelRearL", "WheelRearR"]:
			node.set_meta("wheel_rest", node.basis)
			node.set_meta("front", "Front" in node.name)
			node.add_to_group("spinning_wheels")
	if wreck:
		return root
	# Removable expedition parts complement, rather than replace, the coachwork.
	for side in [-1.0, 1.0]:
		if int(levels.get("Armor", 0)) > 0:
			box(root, Vector3(0.045, 0.22, 1.2), Vector3(side * 1.07, 0.6, 0.1), "293238", 0.8)
		for tier in range(int(levels.get("Suspension", 0))):
			cylinder(root, 0.055, 0.2, Vector3(side * 0.94, 0.46, -0.7 + tier * 0.65), "cd9c46", -1, 12)
	if int(levels.get("Bumper", 0)) > 0:
		box(root, Vector3(1.95, 0.06 + int(levels.Bumper) * 0.025, 0.18), Vector3(0, 0.28, -2.13), "222b2f", 0.85)
	if int(levels.get("Engine", 0)) > 0:
		box(root, Vector3(0.4, 0.07 + int(levels.Engine) * 0.02, 0.48), Vector3(0, 0.88, -1.35), "1a242a", 0.8)
	if int(levels.get("Spoiler", 0)) > 0:
		for side in [-0.65, 0.65]:
			box(root, Vector3(0.035, 0.22, 0.09), Vector3(side, 1.12, 1.7), "202b30", 0.85)
		box(root, Vector3(1.8 + int(levels.Spoiler) * 0.08, 0.045, 0.3), Vector3(0, 1.25, 1.7), "17252c", 0.8)
	var gun := Node3D.new()
	gun.name = "RoofMount"
	root.add_child(gun)
	cylinder(gun, 0.16, 0.08, Vector3(0, 1.35, 0), "2d373b", -1, 24)
	box(gun, Vector3(0.16, 0.13, 0.46), Vector3(0, 1.46, -0.12), "273239", 0.8)
	box(gun, Vector3(0.05, 0.05, 0.58), Vector3(0, 1.47, -0.55), "151d22", 0.9)
	for tier in range(int(levels.get("Weapon", 0))):
		box(gun, Vector3(0.04, 0.05, 0.38), Vector3(-0.09 + tier * 0.09, 1.55, -0.4), "495351", 0.8)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		node.layers = 2
	root.set_meta("wheel_angle", 0.0)
	root.set_meta("tire_level", int(levels.get("Tires", 0)))
	return root

static func release_cached_resources() -> void:
	palette.clear()
	vehicle_materials.clear()
	vehicle_scene = null

static func animate_vehicle(root: Node3D, delta: float, speed: float, steer: float) -> void:
	var angle := fmod(float(root.get_meta("wheel_angle", 0.0)) + speed * delta / 0.39, TAU)
	root.set_meta("wheel_angle", angle)
	for node in root.find_children("Wheel*", "Node3D", true, false):
		if node.has_meta("wheel_rest"):
			var rest: Basis = node.get_meta("wheel_rest")
			var steering_angle := -steer * 0.16 if node.get_meta("front") else 0.0
			node.basis = rest * Basis(Vector3.UP, steering_angle) * Basis(Vector3.RIGHT, angle)
			var scale_factor := 1.0 + float(root.get_meta("tire_level", 0)) * 0.015
			node.scale = Vector3.ONE * scale_factor

static func capsule(parent: Node3D, radius: float, height: float, at: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = mat(color)
	parent.add_child(node)
	node.position = at
	return node

static func zombie(heavy: bool = false) -> Node3D:
	# Organic stand-in until a production animated character set is authored.
	var root := Node3D.new()
	var skin := "899080"
	var jacket := "54413b" if heavy else "455453"
	var torso := capsule(root, 0.25, 0.69, Vector3(0, 0.89, 0), jacket)
	torso.scale.z = 0.62
	var head := capsule(root, 0.145, 0.37, Vector3(0, 1.37, -0.03), skin)
	head.scale.z = 0.85
	head.rotation.z = -0.13
	capsule(root, 0.065, 0.15, Vector3(0, 1.16, 0), skin)
	capsule(root, 0.027, 0.09, Vector3(0, 1.37, -0.16), "7e8373")
	box(root, Vector3(0.08, 0.018, 0.012), Vector3(0, 1.27, -0.16), "55403a")
	for side in [-1.0, 1.0]:
		var arm := capsule(root, 0.085, 0.48, Vector3(side * 0.28, 0.98, -0.13), jacket)
		arm.rotation.x = -0.85
		arm.rotation.z = side * 0.2
		var forearm := capsule(root, 0.055, 0.32, Vector3(side * 0.29, 1.02, -0.4), skin)
		forearm.rotation.x = -1.35
		var hand := capsule(root, 0.057, 0.15, Vector3(side * 0.29, 1.04, -0.56), skin)
		hand.rotation.x = -1.25
		var thigh := capsule(root, 0.115, 0.48, Vector3(side * 0.13, 0.45, 0.03), "3c454b")
		thigh.rotation.x = side * 0.2
		var shin := capsule(root, 0.075, 0.42, Vector3(side * 0.15, 0.17, 0.1), "354049")
		shin.rotation.x = 0.25
		var boot := capsule(root, 0.08, 0.28, Vector3(side * 0.15, 0.04, 0.035), "252d30")
		boot.rotation.x = PI / 2
		var socket := capsule(root, 0.032, 0.072, Vector3(side * 0.062, 1.41, -0.149), "383b34")
		socket.rotation.z = PI / 2
		box(root, Vector3(0.023, 0.012, 0.007), Vector3(side * 0.06, 1.409, -0.179), "acb099")
	if heavy:
		root.scale = Vector3(1.35, 1.13, 1.18)
	return root
