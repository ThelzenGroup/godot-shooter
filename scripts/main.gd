extends Node3D

const MAX_WAVE: int = 5
var player: ArenaPlayer
var spawn_points: Array[Vector3] = []
var wave_timer: float = 2.0
var intermission: bool = true
var hud: Label
var overlay: Label

func _ready() -> void:
	GameState.reset()
	_build_environment()
	_build_arena()
	_build_player()
	_build_ui()
	spawn_points = [Vector3(-14, 1, -14), Vector3(14, 1, -14), Vector3(-14, 1, 14), Vector3(14, 1, 14), Vector3(0, 1, 18)]
	GameState.mode_changed.emit("ARENA READY", "Survive five waves")

func _process(delta: float) -> void:
	if intermission:
		wave_timer -= delta
		if wave_timer <= 0.0:
			intermission = false
			_start_wave(GameState.wave + 1)
	if GameState.health <= 0 and overlay.text == "":
		overlay.text = "GAME OVER\nPress F5 to restart"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if GameState.wave >= MAX_WAVE and GameState.enemies_remaining == 0 and not intermission and overlay.text == "":
		overlay.text = "VICTORY\nAll waves cleared!"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_hud()

func _start_wave(number: int) -> void:
	GameState.wave = number
	var count: int = 3 + number * 2
	GameState.enemies_remaining = count
	GameState.wave_changed.emit(number, count)
	for index in count:
		var enemy := ArenaEnemy.new()
		enemy.position = spawn_points[index % spawn_points.size()]
		add_child(enemy)
		enemy.setup(player, number - 1)

func _build_player() -> void:
	player = ArenaPlayer.new()
	player.position = Vector3(0, 1.2, 8)
	add_child(player)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.02, 0.04, 0.12)
	sky_material.sky_horizon_color = Color(0.35, 0.12, 0.08)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	add_child(sun)

func _build_arena() -> void:
	_add_box(Vector3(0, -0.5, 0), Vector3(40, 1, 40), Color(0.09, 0.11, 0.16))
	_add_box(Vector3(0, 2, -20), Vector3(40, 5, 1), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(0, 2, 20), Vector3(40, 5, 1), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(-20, 2, 0), Vector3(1, 5, 40), Color(0.16, 0.19, 0.27))
	_add_box(Vector3(20, 2, 0), Vector3(1, 5, 40), Color(0.16, 0.19, 0.27))
	for position in [Vector3(-7, 1, 0), Vector3(7, 1, 0), Vector3(0, 1, -7), Vector3(0, 1, 7)]:
		_add_box(position, Vector3(3, 2, 3), Color(0.28, 0.34, 0.43))
	var nav := NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([Vector3(-19, 0, -19), Vector3(19, 0, -19), Vector3(19, 0, 19), Vector3(-19, 0, 19)])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav.navigation_mesh = nav_mesh
	add_child(nav)

func _add_box(position: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = position
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

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(634, 340)
	crosshair.add_theme_font_size_override("font_size", 28)
	layer.add_child(crosshair)
	overlay = Label.new()
	overlay.position = Vector2(470, 290)
	overlay.add_theme_font_size_override("font_size", 32)
	overlay.text = ""
	layer.add_child(overlay)

func _update_hud() -> void:
	if hud == null:
		return
	hud.text = "HP %d/%d   AMMO %d/%d   SCORE %d   WAVE %d/%d   ENEMIES %d" % [GameState.health, GameState.max_health, GameState.ammo, GameState.reserve, GameState.score, GameState.wave, MAX_WAVE, GameState.enemies_remaining]
