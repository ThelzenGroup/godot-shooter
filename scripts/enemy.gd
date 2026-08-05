class_name ArenaEnemy
extends CharacterBody3D

@export var base_health: int = 60
@export var speed: float = 2.6
@export var attack_damage: int = 8
@export var attack_range: float = 1.7
@export var detection_radius: float = 22.0
@export var gravity: float = 18.0

var health: int
var player: ArenaPlayer
var attack_cooldown: float = 0.0
var agent: NavigationAgent3D
var body_mesh: MeshInstance3D
var hit_flash: float = 0.0
var state: GameStateModel
var desired_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	health = base_health
	agent = get_node_or_null("NavigationAgent3D")
	body_mesh = get_node_or_null("Body")
	state = get_node("/root/GameState") as GameStateModel
	agent.velocity_computed.connect(_on_velocity_computed)

func setup(target: ArenaPlayer, toughness: int) -> void:
	player = target
	health = base_health + toughness * 15

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	var direction := Vector3.ZERO
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance <= detection_radius and _has_line_of_sight():
			agent.target_position = player.global_position
			var next := agent.get_next_path_position()
			var target := player.global_position
			if next != Vector3.ZERO and global_position.distance_to(next) < distance:
				target = next
			direction = global_position.direction_to(target)
			if distance <= attack_range and attack_cooldown <= 0.0 and _has_line_of_sight():
				attack_cooldown = 1.0
				player.hurt(attack_damage)
	desired_velocity = Vector3(direction.x * speed, velocity.y, direction.z * speed)
	agent.set_velocity(desired_velocity)
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP)
	query.collision_mask = GameConstants.WORLD_LAYER | GameConstants.PLAYER_LAYER
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player

func can_see_player() -> bool:
	return _has_line_of_sight()

func take_damage(amount: int, hit_position: Vector3) -> void:
	health -= amount
	hit_flash = 0.12
	get_tree().call_group("game", "play_sound_3d", "impact", hit_position)
	get_tree().call_group("game", "spawn_impact", hit_position)
	if health <= 0:
		get_tree().call_group("game", "spawn_death_effect", global_position)
		state.add_score(100)
		get_tree().call_group("game", "enemy_defeated", self)
		queue_free()
