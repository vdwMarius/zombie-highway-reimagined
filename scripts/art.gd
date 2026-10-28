class_name Art
extends RefCounted
## Original, procedural low-poly art. Shared materials keep draw state predictable.
static var palette: Dictionary = {}

static func mat(hex: String, metallic: float = 0.0, glow: bool = false) -> StandardMaterial3D:
	var key := hex + str(metallic) + str(glow)
	if palette.has(key):
		return palette[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.metallic = metallic
	material.roughness = 0.72
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
	var root := Node3D.new()
	var paint := "86533c" if wreck else "a4b4a3"
	box(root, Vector3(1.95, 0.55, 4.1), Vector3(0, 0.85, 0), paint, 0.35)
	box(root, Vector3(1.77, 0.6, 2.05), Vector3(0, 1.38, 0.38), paint, 0.35)
	box(root, Vector3(1.65, 0.08, 2.15), Vector3(0, 1.72, 0.38), "3b4a43", 0.5)
	box(root, Vector3(1.66, 0.41, 0.045), Vector3(0, 1.42, -0.67), "243c42", 0.5)
	box(root, Vector3(1.66, 0.4, 0.04), Vector3(0, 1.42, 1.42), "21353b", 0.5)
	for side in [-1.0, 1.0]:
		box(root, Vector3(0.025, 0.38, 1.8), Vector3(side * 0.9, 1.42, 0.37), "283c3d", 0.3)
		box(root, Vector3(0.07, 0.46, 0.09), Vector3(side * 0.92, 1.42, 0.4), paint)
		box(root, Vector3(0.16, 0.16, 0.25), Vector3(side * 1.04, 1.36, -0.46), paint)
		box(root, Vector3(0.13, 0.12, 3.7), Vector3(side, 0.6, 0), "252c2d", 0.7)
		box(root, Vector3(0.12, 0.08, 1.8), Vector3(side * 0.66, 1.84, 0.35), "293333", 0.7)
		for z in [-1.28, 1.27]:
			var tire := cylinder(root, 0.48 + int(levels.get("Tires", 0)) * 0.025, 0.32, Vector3(side * 0.96, 0.49, z), "191e20", -1, 14)
			tire.rotation.z = PI / 2
			var hub := cylinder(root, 0.25, 0.335, Vector3(side * 0.98, 0.49, z), "6f7976", -1, 8)
			hub.rotation.z = PI / 2
		box(root, Vector3(0.4, 0.18, 0.06), Vector3(side * 0.66, 0.94, -2.07), "ffe1a3", 0.0, true)
		box(root, Vector3(0.29, 0.18, 0.06), Vector3(side * 0.7, 0.96, 2.07), "ed654d", 0.0, true)
		if int(levels.get("Armor", 0)) > 0:
			box(root, Vector3(0.08, 0.4, 1.5), Vector3(side * 0.99, 0.97, 0.35), "4d605b", 0.5)
			for tier in range(int(levels.get("Armor", 0))):
				box(root, Vector3(0.09, 0.16, 0.4), Vector3(side * 1.04, 1.15, -0.5 + tier * 0.55), "4d605b", 0.6)
		for tier in range(int(levels.get("Suspension", 0))):
			cylinder(root, 0.075, 0.43, Vector3(side * 0.94, 0.52, -0.8 + tier * 0.7), "d9a34e", -1, 8)
	box(root, Vector3(1.25, 0.22, 0.05), Vector3(0, 0.85, -2.09), "192326")
	for x in [-0.48, -0.24, 0, 0.24, 0.48]:
		box(root, Vector3(0.05, 0.21, 0.07), Vector3(x, 0.85, -2.12), "707a73", 0.6)
	box(root, Vector3(2.05, 0.17 + int(levels.get("Bumper", 0)) * 0.07, 0.22), Vector3(0, 0.63, -2.16), "414e4c", 0.8)
	box(root, Vector3(2.0, 0.17, 0.2), Vector3(0, 0.65, 2.15), "414e4c", 0.8)
	box(root, Vector3(0.46, 0.015, 1.2), Vector3(0, 1.14, -1.37), "cf7d45")
	if int(levels.get("Engine", 0)) > 0:
		box(root, Vector3(0.5 + int(levels.get("Engine", 0)) * 0.12, 0.13 + int(levels.get("Engine", 0)) * 0.06, 0.6), Vector3(0, 1.23, -1.2), "313d3c", 0.6)
	if int(levels.get("Spoiler", 0)) > 0:
		for side in [-0.65, 0.65]:
			box(root, Vector3(0.08, 0.25, 0.12), Vector3(side, 1.85, 1.25), "404d48")
		box(root, Vector3(1.9 + int(levels.get("Spoiler", 0)) * 0.12, 0.09, 0.3 + int(levels.get("Spoiler", 0)) * 0.07), Vector3(0, 1.99, 1.3), "303f3c", 0.6)
	# Roof-mounted gun, spare wheel and expedition details.
	cylinder(root, 0.23, 0.15, Vector3(0, 1.84, -0.02), "39443e")
	box(root, Vector3(0.22, 0.2, 0.65), Vector3(0, 1.98, -0.25), "293133", 0.7)
	box(root, Vector3(0.09, 0.09, 0.8), Vector3(0, 1.98, -0.85), "161f23", 0.8)
	for tier in range(int(levels.get("Weapon", 0))):
		box(root, Vector3(0.08, 0.12, 0.55), Vector3(-0.18 + tier * 0.18, 2.12, -0.7), "586058", 0.7)
	var spare := cylinder(root, 0.39, 0.22, Vector3(0.3, 1.86, 0.89), "202627")
	spare.rotation.z = 0.07
	box(root, Vector3(0.4, 0.3, 0.6), Vector3(-0.5, 1.91, 0.9), "9b6b42")
	return root

static func zombie(heavy: bool = false) -> Node3D:
	var root := Node3D.new()
	var jacket := "6e4743" if heavy else "62766d"
	box(root, Vector3(0.47, 0.62, 0.25), Vector3(0, 0.8, 0), jacket)
	box(root, Vector3(0.3, 0.33, 0.28), Vector3(0, 1.29, 0), "92a278")
	for side in [-1.0, 1.0]:
		var arm := box(root, Vector3(0.13, 0.6, 0.14), Vector3(side * 0.31, 0.9, -0.12), "92a278")
		arm.rotation.x = -0.9
		var leg := box(root, Vector3(0.17, 0.6, 0.19), Vector3(side * 0.14, 0.28, 0), "343e40")
		leg.rotation.x = side * 0.25
		box(root, Vector3(0.05, 0.05, 0.02), Vector3(side * 0.08, 1.32, -0.15), "f7c75d", 0, true)
	if heavy:
		root.scale = Vector3.ONE * 1.25
	return root
