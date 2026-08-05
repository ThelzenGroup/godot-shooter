extends Node3D

var navigation: NavigationRegion3D
var cover_positions: Array[Vector3] = [
	Vector3(-7, 1, 0), Vector3(7, 1, 0), Vector3(0, 1, -7), Vector3(0, 1, 7)
]
var cover_size: Vector3 = Vector3(3, 2, 3)
var spawn_points: Array[Vector3] = [
	Vector3(-15, 0.0, -15), Vector3(15, 0.0, -15),
	Vector3(-15, 0.0, 15), Vector3(15, 0.0, 15),
	Vector3(0, 0.0, -17), Vector3(0, 0.0, 17),
]

func _ready() -> void:
	_build_environment()
	_build_geometry()
	_build_navigation()

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	var sky := Sky.new()
	var material := PanoramaSkyMaterial.new()
	material.panorama = load("res://assets/sky/urban_street_03_1k.hdr") as Texture2D
	sky.sky_material = material
	environment.sky = sky
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	add_child(sun)

func _build_geometry() -> void:
	_add_box(Vector3(0, -0.5, 0), Vector3(40, 1, 40), Color(0.09, 0.11, 0.16))
	_add_box(Vector3(0, 2.0, -20), Vector3(40, 5, 1), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(0, 2.0, 20), Vector3(40, 5, 1), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(-20, 2.0, 0), Vector3(1, 5, 40), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(20, 2.0, 0), Vector3(1, 5, 40), Color(0.16, 0.19, 0.27))
	for position in cover_positions:
		_add_box(position, cover_size, Color(0.28, 0.34, 0.43))

func _add_box(position: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = GameConstants.WORLD_LAYER
	body.collision_mask = GameConstants.WORLD_MASK
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_navigation() -> void:
	navigation = NavigationRegion3D.new()
	navigation.name = "BakedNavigation"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.5
	nav_mesh.agent_radius = 0.55
	nav_mesh.agent_height = 1.8
	var vertices := PackedVector3Array()
	var polygons: Array[PackedInt32Array] = []
	for x in range(-10, 10):
		for z in range(-10, 10):
			var center := Vector3((float(x) + 0.5) * 2.0, 0.01, (float(z) + 0.5) * 2.0)
			if absf(center.x) > 18.5 or absf(center.z) > 18.5:
				continue
			var blocked := false
			for cover_position in cover_positions:
				if absf(center.x - cover_position.x) < cover_size.x * 0.5 + 0.5 and absf(center.z - cover_position.z) < cover_size.z * 0.5 + 0.5:
					blocked = true
					break
			if blocked:
				continue
			var base := vertices.size()
			vertices.append(center + Vector3(-1, 0, -1))
			vertices.append(center + Vector3(1, 0, -1))
			vertices.append(center + Vector3(1, 0, 1))
			vertices.append(center + Vector3(-1, 0, 1))
			polygons.append(PackedInt32Array([base, base + 1, base + 2, base + 3]))
	nav_mesh.vertices = vertices
	for polygon in polygons:
		nav_mesh.add_polygon(polygon)
	navigation.navigation_mesh = nav_mesh
	add_child(navigation)
	NavigationServer3D.map_force_update(navigation.get_navigation_map())
