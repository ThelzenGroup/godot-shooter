class_name ArenaPlayer
extends CharacterBody3D

@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.0
@export var acceleration: float = 28.0
@export var friction: float = 20.0
@export var mouse_sensitivity: float = 0.0025
@export var magazine_size: int = 12
@export var reload_time: float = 1.2

var camera: Camera3D
var pitch: float = 0.0
var cooldown: float = 0.0
var reload_left: float = 0.0
var rifle: bool = false
var flash_left: float = 0.0

func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.65, 0)
	camera.current = true
	add_child(camera)
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	body_mesh.mesh = capsule
	body_mesh.visible = false
	add_child(body_mesh)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.health_changed.emit(GameState.health, GameState.max_health)
	GameState.ammo_changed.emit(GameState.ammo, GameState.reserve)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.55, 1.55)
		camera.rotation.x = pitch
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			var needed: int = magazine_size - GameState.ammo
			var loaded: int = mini(needed, GameState.reserve)
			GameState.ammo += loaded
			GameState.reserve -= loaded
			GameState.ammo_changed.emit(GameState.ammo, GameState.reserve)
	cooldown = maxf(0.0, cooldown - delta)
	flash_left = maxf(0.0, flash_left - delta)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := direction * target_speed
	var rate: float = acceleration if direction != Vector3.ZERO else friction
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = 7.5
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()
	if Input.is_action_pressed("fire"):
		fire()
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("weapon_1"):
		rifle = false
		magazine_size = 12
	if Input.is_action_just_pressed("weapon_2"):
		rifle = true
		magazine_size = 30

func fire() -> void:
	if cooldown > 0.0 or reload_left > 0.0 or GameState.ammo <= 0:
		return
	var rate: float = 0.1 if rifle else 0.28
	cooldown = rate
	GameState.ammo -= 1
	GameState.ammo_changed.emit(GameState.ammo, GameState.reserve)
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 120.0)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is ArenaEnemy:
		var damage_amount: int = 12 if rifle else 30
		hit.collider.take_damage(damage_amount, hit.position)

func start_reload() -> void:
	if reload_left <= 0.0 and GameState.ammo < magazine_size and GameState.reserve > 0:
		reload_left = reload_time
