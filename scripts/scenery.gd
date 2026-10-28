class_name Scenery
extends RefCounted
const A = preload("res://scripts/art.gd")
const Workshop = preload("res://scripts/home_garage.gd")

static func terrain(root: Node3D) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 2068
	noise.frequency = 0.009
	noise.fractal_octaves = 3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 100
	var rows := 100
	var vertices: Array[Vector3] = []
	for z in range(rows + 1):
		for x in range(columns + 1):
			var wx := -400.0 + x * 8.0
			var wz := -650.0 + z * 8.0
			var away := maxf(0, absf(wx) - 10.0)
			var envelope := smoothstep(0, 110, away)
			var height := (noise.get_noise_2d(wx, wz) + 0.65) * envelope * 85.0
			vertices.append(Vector3(wx, height - 0.25, wz))
	for z in range(rows):
		for x in range(columns):
			var i := z * (columns + 1) + x
			for idx in [i, i + columns + 1, i + 1, i + 1, i + columns + 1, i + columns + 2]:
				var point := vertices[idx]
				var blend := noise.get_noise_2d(point.x * 3.0, point.z * 3.0) * 0.3 + 0.7
				st.set_color(Color(0.42, 0.48, 0.4).lerp(Color(0.75, 0.72, 0.62), blend))
				st.add_vertex(point)
	st.index()
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/surfaces/rock.jpg")
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.12
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.94
	mesh.material_override = material
	root.add_child(mesh)

static func tree_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/surfaces/evergreen.png")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.3
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.backlight_enabled = true
	material.backlight = Color(0.18, 0.22, 0.14)
	return material

static func build(game) -> void:
	var root := Node3D.new()
	game.add_child(root)
	game.world = root
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("344e74")
	sky_mat.sky_horizon_color = Color("c8b7a4")
	sky_mat.sky_curve = 0.7
	sky_mat.ground_horizon_color = Color("a1a39a")
	sky_mat.ground_bottom_color = Color("323e3a")
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.7
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_light_color = Color("a1afba")
	environment.fog_light_energy = 0.7
	environment.fog_density = 0.0018
	environment.fog_sky_affect = 0.15
	game.outdoor_environment = environment
	var env := WorldEnvironment.new()
	env.environment = environment
	game.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-18, -28, 0)
	sun.light_color = Color("ffdab0")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	root.add_child(sun)
	terrain(root)
	var asphalt := Workshop.surface("asphalt", 0.25, 0.55)
	var trees := tree_material()
	var tree_mesh := QuadMesh.new()
	tree_mesh.size = Vector2(5.2, 10)
	tree_mesh.material = trees
	for i in range(16):
		var tile := Node3D.new()
		root.add_child(tile)
		tile.position.z = 20.0 - i * 22.0
		var road := A.box(tile, Vector3(12.4, 0.14, 22), Vector3(0, -0.09, 0), "30373d")
		road.material_override = asphalt
		for side in [-1.0, 1.0]:
			A.box(tile, Vector3(0.11, 0.008, 22), Vector3(side * 5.45, 0.004, 0), "c0c3b4")
			A.box(tile, Vector3(0.8, 0.03, 22), Vector3(side * 6.5, -0.02, 0), "737a70")
			# Continuous metal rails carry long moving highlights into the paint.
			A.box(tile, Vector3(0.12, 0.23, 22), Vector3(side * 7.2, 0.7, 0), "8e9697", 0.8)
			for z in [-8.0, 0.0, 8.0]:
				A.box(tile, Vector3(0.08, 0.75, 0.09), Vector3(side * 7.25, 0.35, z), "657071", 0.7)
				A.box(tile, Vector3(0.045, 0.08, 0.14), Vector3(side * 7.1, 0.72, z), "e7d29c", 0, true)
		for x in [-1.9, 1.9]:
			for z in [-8.0, 3.0]:
				A.box(tile, Vector3(0.09, 0.006, 4), Vector3(x, 0.003, z), "b0b7b1")
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = tree_mesh
		instances.instance_count = 12
		for j in range(12):
			var side := -1.0 if j % 2 == 0 else 1.0
			var scale_: float = game.rng.randf_range(0.65, 1.2)
			var at := Vector3(side * game.rng.randf_range(12, 30), 5 * scale_, game.rng.randf_range(-11, 11))
			instances.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_), at))
		var grove := MultiMeshInstance3D.new()
		grove.multimesh = instances
		tile.add_child(grove)
		game.road_tiles.append(tile)
	for i in range(6):
		var wreck := A.vehicle({}, true)
		root.add_child(wreck)
		wreck.position = Vector3(game.lane_x(i), 0, -45.0 - i * 48)
		wreck.rotation.y = game.rng.randf_range(-0.25, 0.25)
		game.wrecks.append(wreck)
	for i in range(10):
		var lamp := Node3D.new()
		root.add_child(lamp)
		lamp.position = Vector3(8.0, 0, 15 - i * 35)
		A.cylinder(lamp, 0.085, 7.8, Vector3(0, 3.9, 0), "626c71", 0.05, 16)
		A.box(lamp, Vector3(2.2, 0.07, 0.07), Vector3(-1.0, 7.7, 0), "626c71", 0.7)
		A.box(lamp, Vector3(0.75, 0.06, 0.35), Vector3(-2.0, 7.65, 0), "fce4af", 0, true)
		lamp.add_to_group("poles")
	var probe := ReflectionProbe.new()
	probe.name = "MovingRoadReflection"
	probe.position = Vector3(0, 1.4, 0)
	probe.size = Vector3(26, 14, 48)
	probe.max_distance = 65
	probe.cull_mask = 1
	probe.enable_shadows = false
	probe.intensity = 0.85
	probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	root.add_child(probe)
	game.road_probe = probe
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.fov = 48
	camera.far = 700
	camera.position = Vector3(7, 2.9, 7)
	camera.look_at(Vector3(-1.4, 0.7, 0))
	game.camera = camera
