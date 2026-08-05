class_name ArenaEnemy
extends CharacterBody3D

@export var max_health: int = 60
@export var speed: float = 2.6
@export var attack_damage: int = 8
@export var detection_radius: float = 35.0

var health: int
var player: ArenaPlayer
var attack_cooldown: float = 0.0
var agent: NavigationAgent3D

func _ready() -> void:
	health = max_health
	agent = NavigationAgent3D.new()
	agent.path_height_offset = 0.0
	agent.radius = 0.55
	agent.avoidance_enabled = true
	add_child(agent)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.5
	capsule.material = _material(Color(0.75, 0.08, 0.1))
	mesh.mesh = capsule
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := CapsuleShape3D.new()
	collider.height = 1.8
	collider.radius = 0.5
	shape.shape = collider
	add_child(shape)

func setup(target: ArenaPlayer, toughness: int) -> void:
	player = target
	max_health += toughness * 10
	health = max_health

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_radius:
		agent.target_position = player.global_position
		var next := agent.get_next_path_position()
		var direction := global_position.direction_to(next if next != Vector3.ZERO else player.global_position)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if distance < 1.8 and attack_cooldown <= 0.0:
			attack_cooldown = 1.0
			GameState.damage(attack_damage)
		move_and_slide()

func take_damage(amount: int, _hit_position: Vector3) -> void:
	health -= amount
	if health <= 0:
		GameState.add_score(100)
		GameState.enemies_remaining = maxi(0, GameState.enemies_remaining - 1)
		GameState.wave_changed.emit(GameState.wave, GameState.enemies_remaining)
		queue_free()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.15
	material.roughness = 0.72
	return material
