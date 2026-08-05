extends SceneTree

var failures: Array[String] = []
var main: Node3D
var player: ArenaPlayer
var state: Node
var death_seen: bool = false

func _initialize() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	state = root.get_node("GameState")
	state.player_died.connect(func() -> void: death_seen = true)
	player = main.get_node("Player") as ArenaPlayer
	player.movement_enabled = false
	main.set("countdown", 999.0)
	await _frames(120)
	_assert(player != null, "player spawns")
	_assert(player.is_on_floor(), "player is standing on floor")
	print("CHECK: player y ", player.global_position.y)
	_assert(player.global_position.y > -0.1 and player.global_position.y < 0.3, "player height is stable")
	_remove_enemies()
	var enemy := load("res://scenes/Enemy.tscn").instantiate() as ArenaEnemy
	enemy.position = Vector3(-15, 1, 0)
	main.add_child(enemy)
	enemy.setup(player, 0)
	var initial_distance: float = enemy.global_position.distance_to(player.global_position)
	await _frames(60)
	print("CHECK: enemy position ", enemy.global_position, " velocity ", enemy.velocity, " sees ", enemy.can_see_player(), " player ", player.global_position, " distance ", enemy.global_position.distance_to(player.global_position))
	_assert(enemy.can_see_player(), "enemy has line of sight")
	_assert(enemy.global_position.distance_to(player.global_position) < initial_distance - 0.2, "enemy approaches player")
	_assert(enemy.global_position.y < 1.2, "enemy is affected by gravity")
	var health_before: int = state.health
	enemy.position = player.global_position + Vector3(0, 0, -1.0)
	await _frames(70)
	_assert(state.health < health_before, "enemy contact damages player")
	enemy.queue_free()
	await process_frame
	var target := load("res://scenes/Enemy.tscn").instantiate() as ArenaEnemy
	target.position = player.global_position + Vector3(0, 0, -4.0)
	main.add_child(target)
	target.setup(player, 0)
	var ammo_before: int = state.ammo
	player.fire_at(target)
	_assert(state.ammo == ammo_before - 1, "firing decrements ammo")
	_assert(target.health < target.base_health, "firing damages enemy")
	for _index in range(3):
		player.fire_at(target)
	_assert(not is_instance_valid(target) or target.health <= 0, "enough shots kill enemy")
	player.switch_weapon(2)
	_assert(state.ammo <= 30, "weapon switch clamps magazine")
	player.switch_weapon(1)
	player.start_reload()
	print("CHECK: reload started")
	await _frames(300)
	print("CHECK: reload complete")
	print("CHECK: ammo value ", state.ammo, " reload_left ", player.reload_left, " loaded ", player.loaded)
	_assert(state.ammo == 12, "reload refills magazine")
	print("CHECK: entering wave loop")
	main.set("countdown", 0.0)
	await _frames(3)
	for _wave in range(5):
		for child in main.get_children():
			if child is ArenaEnemy:
				child.take_damage(9999, child.global_position)
		main.set("countdown", 0.0)
		await _frames(5)
	_assert(state.wave >= 2, "wave state advances beyond wave one")
	player.hurt(999)
	_assert(death_seen and state.health == 0, "health reaching zero emits player death")
	_cleanup()

func _frames(amount: int) -> void:
	for _index in range(amount):
		await process_frame

func _remove_enemies() -> void:
	for child in main.get_children():
		if child is ArenaEnemy:
			child.queue_free()

func _assert(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func _cleanup() -> void:
	if failures.is_empty():
		print("SMOKE PASS: all gameplay invariants verified")
		quit(0)
	else:
		print("SMOKE FAILURES: ", failures)
		quit(1)
