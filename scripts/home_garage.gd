class_name HomeGarage
extends Node3D
## Residential workshop: restrained materials, soft practicals and local IBL.
const A = preload("res://scripts/art.gd")
var style: Resource
var environment: Environment
var probe: ReflectionProbe

func _init(config: Resource = preload("res://data/garages/home.tres")) -> void:
	style = config
	name = "HomeGarage"
	build()

static func surface(name_: String, scale_: float, roughness_: float = 0.7) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/surfaces/%s_color.jpg" % name_)
	material.roughness = roughness_
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_
	if name_ in ["concrete", "asphalt"]:
		material.roughness_texture = load("res://assets/surfaces/%s_rough.jpg" % name_)
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		material.normal_enabled = true
		material.normal_texture = load("res://assets/surfaces/%s_normal.png" % name_)
		material.normal_scale = 0.2
	return material

func area_practical(at: Vector3, color: Color, energy: float, range_: float, shadows: bool = false) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_
	light.omni_attenuation = 1.4
	light.shadow_enabled = shadows
	add_child(light)

func build() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("131a20")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a4b4bf")
	environment.ambient_light_energy = 0.23
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	var floor_mesh := A.box(self, Vector3(16, 0.2, 18), Vector3(0, -0.15, 0), "70716c")
	floor_mesh.material_override = surface("concrete", 0.22, 0.8)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_texture = load("res://assets/surfaces/plaster.jpg")
	wall_material.albedo_color = style.wall_color
	wall_material.uv1_triplanar = true
	wall_material.uv1_scale = Vector3.ONE * 0.25
	wall_material.roughness = 0.95
	for item in [Vector4(0, 2.3, -6.5, 0), Vector4(-7.5, 2.3, 0, 1), Vector4(7.5, 2.3, 0, 1)]:
		var wall := A.box(self, Vector3(15, 4.6, 0.18) if item.w == 0 else Vector3(0.18, 4.6, 13), Vector3(item.x, item.y, item.z), "9b9a8f")
		wall.material_override = wall_material
	# Painted lower walls, skirting and visible roof beams.
	A.box(self, Vector3(15, 1.1, 0.04), Vector3(0, 0.51, -6.37), "444e4d")
	A.box(self, Vector3(15, 0.07, 0.06), Vector3(0, 1.08, -6.33), "b1a68d")
	A.box(self, Vector3(15, 0.12, 0.08), Vector3(0, 0.04, -6.3), "272f32")
	for side in [-1.0, 1.0]:
		A.box(self, Vector3(0.05, 1.1, 13), Vector3(side * 7.38, 0.51, 0), "444e4d")
		A.box(self, Vector3(0.12, 0.12, 13), Vector3(side * 7.32, 0.04, 0), "272f32")
		A.box(self, Vector3(0.04, 0.07, 13), Vector3(side * 7.32, 1.08, 0), "b1a68d")
	A.box(self, Vector3(15, 0.12, 13), Vector3(0, 4.6, 0), "454b49")
	for x in [-5.0, -1.8, 1.8, 5.0]:
		A.box(self, Vector3(0.15, 0.25, 13), Vector3(x, 4.42, 0), "48423a")
	# Long luminous fixtures are visible in the car's clear-coat reflections.
	for x in [-3.6, 0, 3.6]:
		for z in [-2.8, 2.0]:
			A.box(self, Vector3(0.36, 0.09, 2.6), Vector3(x, 4.17, z), "242c30", 0.6)
			A.box(self, Vector3(0.22, 0.015, 2.35), Vector3(x, 4.11, z), "e5eee9", 0, true)
			area_practical(Vector3(x, 3.7, z), style.light_color, 2.3, 7.2, x == 0)
	area_practical(Vector3(3.3, 2.8, 3.4), Color("d7e9ff"), 2.5, 7.5)
	# Back windows with deep reveals and cooler daylight.
	for x in [-4.5, 3.5]:
		A.box(self, Vector3(2.65, 1.4, 0.12), Vector3(x, 2.85, -6.3), "313c3f")
		A.box(self, Vector3(2.42, 1.2, 0.03), Vector3(x, 2.85, -6.21), "9daeb1", 0.1, true)
		A.box(self, Vector3(0.06, 1.25, 0.06), Vector3(x, 2.85, -6.17), "4b5858")
		A.box(self, Vector3(2.45, 0.06, 0.06), Vector3(x, 2.85, -6.17), "4b5858")
		A.box(self, Vector3(2.8, 0.09, 0.3), Vector3(x, 2.11, -6.14), "b0aca1")
		area_practical(Vector3(x, 2.7, -4.9), Color("a7c9ef"), 1.2, 7)
	# Workbench: wood grain, metal drawers, tool board, stool, vice, boxes.
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/surfaces/wood.jpg")
	wood.roughness = 0.6
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(0.5, 0.5, 0.5)
	var bench := A.box(self, Vector3(4.4, 0.11, 0.85), Vector3(-0.1, 1.04, -5.78), "927650")
	bench.material_override = wood
	for x in [-1.5, 1.5]:
		A.box(self, Vector3(1.1, 0.94, 0.7), Vector3(x, 0.5, -5.8), style.cabinet_color, 0.45)
		for y in [0.25, 0.48, 0.71, 0.94]:
			A.box(self, Vector3(1.0, 0.015, 0.03), Vector3(x, y, -5.43), "516067", 0.8)
			A.box(self, Vector3(0.38, 0.025, 0.035), Vector3(x, y - 0.08, -5.4), "a5acaa", 0.95)
	A.box(self, Vector3(4.0, 1.1, 0.06), Vector3(0, 1.9, -6.25), "6c6756")
	for x in range(32):
		for y in range(7):
			# One perforation strip per column avoids hundreds of tiny meshes.
			if y == 0:
				A.box(self, Vector3(0.012, 0.9, 0.008), Vector3(-1.85 + x * 0.12, 1.9, -6.21), "464940")
	for x in [-1.4, -0.95, -0.5, 0, 0.45, 0.9, 1.4]:
		A.box(self, Vector3(0.035, 0.32, 0.025), Vector3(x, 1.9, -6.15), "9da29c", 0.95)
		A.cylinder(self, 0.052, 0.04, Vector3(x, 2.09, -6.15), "b4bab6", -1, 16).rotation.x = PI / 2
	A.box(self, Vector3(0.46, 0.22, 0.22), Vector3(1.5, 1.2, -5.7), "475663", 0.7)
	A.box(self, Vector3(0.15, 0.1, 0.34), Vector3(1.5, 1.35, -5.68), "8b9395", 0.95)
	A.cylinder(self, 0.27, 0.08, Vector3(-0.3, 0.66, -4.4), "3c4d4e", -1, 32)
	for side in [-1.0, 1.0]:
		A.box(self, Vector3(0.03, 0.62, 0.03), Vector3(-0.3 + side * 0.19, 0.31, -4.4), "7c8584", 0.8)
	# Shelving on the left wall, with irregular domestic storage.
	for z in [-3.8, -1.0, 1.8]:
		for x in [-7.1, -6.2]:
			A.box(self, Vector3(0.06, 2.65, 0.06), Vector3(x, 1.33, z), "414d4e", 0.7)
		for y in [0.2, 1.0, 1.8, 2.65]:
			A.box(self, Vector3(1.0, 0.045, 2.4), Vector3(-6.66, y, z + 0.9), "77705a")
		for i in range(4):
			A.box(self, Vector3(0.65, 0.45, 0.55), Vector3(-6.64, 1.25 + (i % 2) * 0.8, z + i * 0.5), "8b775a" if i % 2 else "6f7669")
	# Residential details: a side door, coat hooks, wall clock, extinguisher.
	A.box(self, Vector3(0.08, 2.5, 1.15), Vector3(7.34, 1.25, -3.8), "9b9889")
	A.box(self, Vector3(0.08, 0.045, 0.18), Vector3(7.24, 1.15, -3.45), "b2b7b4", 0.95)
	var clock := A.cylinder(self, 0.3, 0.05, Vector3(0, 3.3, -6.23), "dfd8c5", -1, 48)
	clock.rotation.x = PI / 2
	A.box(self, Vector3(0.018, 0.18, 0.02), Vector3(0, 3.38, -6.18), "303c40")
	A.box(self, Vector3(0.14, 0.018, 0.02), Vector3(0.05, 3.3, -6.17), "303c40")
	A.cylinder(self, 0.11, 0.45, Vector3(6.8, 0.7, -5.9), "a73329", -1, 24)
	A.box(self, Vector3(0.12, 0.06, 0.12), Vector3(6.8, 0.97, -5.9), "343b3e", 0.8)
	# Loose wheel stack and service trolley near, but clear of, the car.
	for i in range(3):
		A.cylinder(self, 0.41, 0.23, Vector3(4.7, 0.15 + i * 0.23, -4.8), "151b20", -1, 48)
	A.box(self, Vector3(0.8, 0.8, 0.5), Vector3(4.6, 0.5, -1.8), "314a52", 0.55)
	for i in range(4):
		A.box(self, Vector3(0.68, 0.03, 0.03), Vector3(4.6, 0.27 + i * 0.18, -1.53), "969f9e", 0.95)
	# Reflections capture room/light fixtures while excluding the reflective car.
	probe = ReflectionProbe.new()
	probe.name = "WorkshopReflection"
	probe.position = Vector3(0, 1.7, 0)
	probe.size = Vector3(15, 7, 16)
	probe.box_projection = true
	probe.interior = true
	probe.enable_shadows = true
	probe.cull_mask = 1
	probe.intensity = 1.15
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)

func refresh_reflections() -> void:
	# Toggling visibility invalidates a once-updated capture after scene changes.
	probe.visible = false
	probe.visible = true
