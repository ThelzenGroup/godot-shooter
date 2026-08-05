extends SceneTree

var failures: Array[String] = []
var main: Node3D
var player: ArenaPlayer
var state: GameStateModel
var death_seen: bool = false

func _initialize() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	state = root.get_node("GameState") as GameStateModel
	state.player_died.connect(func() -> void: death_seen = true)
	player = main.get_node("Player") as ArenaPlayer
	var play_button := main.main_menu.primary_button as Button
	_assert(play_button != null and play_button.visible, "main menu exposes clickable Play button")
	print("CHECK: play rect ", play_button.get_global_rect(), " viewport ", play_button.get_viewport_rect(), " menu ", main.main_menu.visible)
	await _click_control(play_button)
	_assert(main.mode != main.GameMode.MENU, "Play button starts the game")
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
	await _frames(120)
	print("CHECK: enemy position ", enemy.global_position, " velocity ", enemy.velocity, " sees ", enemy.can_see_player(), " player ", player.global_position, " distance ", enemy.global_position.distance_to(player.global_position))
	_assert(enemy.can_see_player(), "enemy has line of sight")
	_assert(enemy.global_position.distance_to(player.global_position) < initial_distance - 0.2, "enemy approaches player")
	_assert(enemy.global_position.y < 1.2, "enemy is affected by gravity")
	_assert(not _inside_cover(enemy.global_position), "enemy does not enter cover")
	var memory_enemy := load("res://scenes/Enemy.tscn").instantiate() as ArenaEnemy
	memory_enemy.position = Vector3(0, 1, 10)
	main.add_child(memory_enemy)
	memory_enemy.setup(player, 0)
	await _frames(30)
	_assert(memory_enemy.can_see_player(), "enemy records a visible player position")
	var last_known_position: Vector3 = player.global_position
	memory_enemy.position = Vector3(-1.9, 1, 5)
	var memory_distance: float = memory_enemy.global_position.distance_to(last_known_position)
	await _frames(60)
	print("CHECK: memory enemy position ", memory_enemy.global_position, " distance to last known ", memory_enemy.global_position.distance_to(last_known_position))
	_assert(not memory_enemy.can_see_player(), "enemy loses line of sight behind cover")
	_assert(memory_enemy.global_position.distance_to(last_known_position) < memory_distance - 0.2, "enemy chases last known position after losing sight")
	memory_enemy.queue_free()
	await process_frame
	var health_before: int = state.health
	enemy.position = player.global_position + Vector3(0, 0, -1.0)
	await _frames(70)
	_assert(state.health < health_before, "enemy contact damages player")
	enemy.queue_free()
	await process_frame
	var target := load("res://scenes/Enemy.tscn").instantiate() as ArenaEnemy
	target.position = player.global_position + Vector3(8, 1, -4.0)
	main.add_child(target)
	target.setup(player, 0)
	player.aim_override = target.global_position
	player.spread_degrees = 0.0
	await process_frame
	var aim_query := PhysicsRayQueryParameters3D.create(player.camera.global_position, target.global_position)
	aim_query.collision_mask = GameConstants.HITSCAN_MASK
	aim_query.exclude = [player]
	var aim_hit := main.get_world_3d().direct_space_state.intersect_ray(aim_query)
	print("CHECK: aimed collider ", aim_hit.get("collider").name if not aim_hit.is_empty() else "none")
	var ammo_before: int = state.ammo
	player.fire()
	_assert(state.ammo == ammo_before - 1, "firing decrements ammo")
	_assert(target.health < target.base_health, "firing damages enemy")
	_assert(player.camera.rotation.x < player.pitch, "firing applies camera recoil offset")
	await _frames(300)
	_assert(absf(player.camera.rotation.x - player.pitch) < 0.02, "recoil returns camera to pitch")
	for _index in range(3):
		await _frames(30)
		player.fire()
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
	var converging: Array[ArenaEnemy] = []
	for position in [Vector3(-8, 1, 12), Vector3(8, 1, 12), Vector3(-10, 1, 8), Vector3(10, 1, 8)]:
		var converging_enemy := load("res://scenes/Enemy.tscn").instantiate() as ArenaEnemy
		converging_enemy.position = position
		main.add_child(converging_enemy)
		converging_enemy.setup(player, 0)
		converging.append(converging_enemy)
	await _frames(120)
	var minimum_separation: float = 999.0
	for first in range(converging.size()):
		for second in range(first + 1, converging.size()):
			minimum_separation = minf(minimum_separation, converging[first].global_position.distance_to(converging[second].global_position))
	_assert(minimum_separation > 0.5, "enemy avoidance keeps converging enemies separated")
	player.hurt(999)
	_assert(death_seen and state.health == 0, "health reaching zero emits player death")
	var restart_button := main.game_over.primary_button as Button
	_assert(restart_button != null and restart_button.visible, "game over exposes clickable Restart button")
	await _click_control(restart_button)
	await process_frame
	state = root.get_node("GameState") as GameStateModel
	_assert(not paused, "restart clears tree pause")
	_assert(state.health == state.max_health and state.wave == 0 and not state.dead, "restart fully resets GameState")
	main = current_scene as Node3D
	await _click_control(main.main_menu.primary_button as Button)
	main._on_victory()
	var victory_button := main.victory.primary_button as Button
	_assert(victory_button != null and victory_button.visible, "victory exposes clickable Restart button while paused")
	await _click_control(victory_button)
	await process_frame
	_assert(not paused, "victory restart clears tree pause")
	await _cleanup()

func _frames(amount: int) -> void:
	for _index in range(amount):
		await process_frame

func _remove_enemies() -> void:
	for child in main.get_children():
		if child is ArenaEnemy:
			child.queue_free()

func _inside_cover(position: Vector3) -> bool:
	return (absf(position.x + 7.0) < 1.6 and absf(position.z) < 1.6) or (absf(position.x - 7.0) < 1.6 and absf(position.z) < 1.6) or (absf(position.x) < 1.6 and absf(position.z + 7.0) < 1.6) or (absf(position.x) < 1.6 and absf(position.z - 7.0) < 1.6)

func _click_control(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	var menu := control.get_parent().get_parent().get_parent() as Control
	menu.call("_input", event)
	await process_frame
	event.pressed = false
	if is_instance_valid(menu):
		menu.call("_input", event)

func _assert(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func _cleanup() -> void:
	var scene := current_scene
	if scene != null:
		scene.queue_free()
		await process_frame
	if failures.is_empty():
		print("SMOKE PASS: all gameplay invariants verified")
		quit(0)
	else:
		print("SMOKE FAILURES: ", failures)
		quit(1)
