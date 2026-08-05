class_name ArenaPlayer
extends CharacterBody3D

@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.0
@export var acceleration: float = 28.0
@export var friction: float = 20.0
@export var jump_velocity: float = 7.5
@export var mouse_sensitivity: float = 0.0025
@export var reload_time: float = 1.2
@export var spread_degrees: float = 1.2
@export var gravity: float = 18.0

const WEAPONS: Dictionary = {
	1: {"magazine": 12, "reserve": 72, "rate": 0.28, "damage": 30},
	2: {"magazine": 30, "reserve": 120, "rate": 0.10, "damage": 12},
}

var camera: Camera3D
var pitch: float = 0.0
var cooldown: float = 0.0
var reload_left: float = 0.0
var weapon_slot: int = 1
var loaded: Dictionary = {1: 12, 2: 30}
var reserves: Dictionary = {1: 72, 2: 120}
var recoil: float = 0.0
var damage_flash: float = 0.0
var muzzle_light: OmniLight3D
var state: GameStateModel
var aim_override: Vector3 = Vector3.ZERO

func _ready() -> void:
	camera = get_node_or_null("Camera3D")
	muzzle_light = get_node_or_null("MuzzleLight")
	state = get_node("/root/GameState") as GameStateModel
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_ammo()
	get_tree().call_group("game", "play_sound", "fire")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.55, 1.55)
		camera.rotation.x = pitch
	if event.is_action_pressed("pause"):
		get_tree().call_group("game", "toggle_pause")

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			reload_left = 0.0
			_finish_reload()
	recoil = move_toward(recoil, 0.0, delta * 5.0)
	camera.rotation.x = pitch - recoil
	damage_flash = maxf(0.0, damage_flash - delta)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := direction * target_speed
	var rate: float = acceleration if direction != Vector3.ZERO else friction
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if Input.is_action_pressed("fire"):
		fire()
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("weapon_1"):
		switch_weapon(1)
	if Input.is_action_just_pressed("weapon_2"):
		switch_weapon(2)

func switch_weapon(slot: int) -> void:
	if not WEAPONS.has(slot) or slot == weapon_slot:
		return
	weapon_slot = slot
	reload_left = 0.0
	_sync_ammo()

func fire() -> void:
	if cooldown > 0.0 or reload_left > 0.0 or loaded[weapon_slot] <= 0:
		return
	var stats: Dictionary = WEAPONS[weapon_slot]
	cooldown = float(stats["rate"])
	loaded[weapon_slot] -= 1
	_sync_ammo()
	recoil += 0.018 if weapon_slot == 2 else 0.028
	camera.rotation.x = pitch - recoil
	_show_muzzle_flash()
	var spread := deg_to_rad(spread_degrees)
	var direction := _fire_direction()
	direction = direction.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
	direction = direction.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * 120.0)
	query.collision_mask = GameConstants.HITSCAN_MASK
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var enemy := hit.collider as ArenaEnemy
		if enemy != null:
			enemy.take_damage(int(stats["damage"]), hit.position)
		get_tree().call_group("game", "spawn_impact", hit.position)

func _fire_direction() -> Vector3:
	if aim_override != Vector3.ZERO:
		return camera.global_position.direction_to(aim_override)
	return -camera.global_transform.basis.z

func start_reload() -> void:
	if reload_left <= 0.0 and loaded[weapon_slot] < int(WEAPONS[weapon_slot]["magazine"]) and reserves[weapon_slot] > 0:
		reload_left = reload_time
		get_tree().call_group("game", "play_sound", "reload")

func _finish_reload() -> void:
	var magazine: int = int(WEAPONS[weapon_slot]["magazine"])
	var needed: int = magazine - loaded[weapon_slot]
	var amount: int = mini(needed, reserves[weapon_slot])
	loaded[weapon_slot] += amount
	reserves[weapon_slot] -= amount
	_sync_ammo()

func _sync_ammo() -> void:
	state.ammo = loaded[weapon_slot]
	state.reserve = reserves[weapon_slot]
	state.ammo_changed.emit(state.ammo, state.reserve)

func hurt(amount: int) -> void:
	damage_flash = 0.25
	get_tree().call_group("game", "play_sound", "hurt")
	state.damage(amount)

func _show_muzzle_flash() -> void:
	if muzzle_light == null:
		return
	muzzle_light.visible = true
	var timer := get_tree().create_timer(0.06)
	timer.timeout.connect(func() -> void: muzzle_light.visible = false)
