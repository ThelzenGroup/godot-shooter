extends Node3D

enum GameMode { MENU, INTERMISSION, FIGHTING, PAUSED, GAME_OVER, VICTORY }

const MAX_WAVE: int = 5
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")
const ARENA_SCENE: PackedScene = preload("res://scenes/Arena.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/HUD.tscn")
const PAUSE_SCENE: PackedScene = preload("res://scenes/PauseMenu.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/GameOver.tscn")
const VICTORY_SCENE: PackedScene = preload("res://scenes/Victory.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/MainMenu.tscn")

var mode: GameMode = GameMode.MENU
var countdown: float = 2.0
var player: ArenaPlayer
var enemy_count: int = 0
var pause_menu: Control
var game_over: Control
var victory: Control
var main_menu: Control
var state: Node

func _ready() -> void:
	add_to_group("game")
	state = get_node("/root/GameState")
	state.reset()
	state.player_died.connect(_on_player_died)
	state.player_victory.connect(_on_victory)
	add_child(ARENA_SCENE.instantiate())
	player = PLAYER_SCENE.instantiate() as ArenaPlayer
	player.position = Vector3(0, 0.0, 12)
	add_child(player)
	add_child(HUD_SCENE.instantiate())
	pause_menu = PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	game_over = GAME_OVER_SCENE.instantiate()
	add_child(game_over)
	victory = VICTORY_SCENE.instantiate()
	add_child(victory)
	main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	if DisplayServer.get_name() == "headless":
		_begin_game()
	else:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if mode == GameMode.INTERMISSION:
		countdown = maxf(0.0, countdown - delta)
		state.wave_changed.emit(state.wave, state.enemies_remaining, countdown)
		if countdown <= 0.0:
			_start_wave(state.wave + 1)

func _begin_game() -> void:
	mode = GameMode.INTERMISSION
	countdown = 2.0
	main_menu.visible = false
	player.process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state.mode_changed.emit("READY", "First wave incoming")

func _start_wave(number: int) -> void:
	if number > MAX_WAVE:
		_on_victory()
		return
	mode = GameMode.FIGHTING
	state.wave = number
	var count: int = 2 + number * 2
	enemy_count = count
	state.enemies_remaining = count
	state.wave_changed.emit(number, count, 0.0)
	for index in range(count):
		var enemy := ENEMY_SCENE.instantiate() as ArenaEnemy
		enemy.position = _spawn_position(index)
		add_child(enemy)
		enemy.setup(player, number - 1)

func _spawn_position(index: int) -> Vector3:
	var arena := get_node_or_null("Arena") as Node
	if arena != null:
		var points: Array[Vector3] = arena.get("spawn_points")
		if points.is_empty():
			return Vector3(0, 1, -15)
		return points[index % points.size()]
	return Vector3(0, 1, -15)

func enemy_defeated(_enemy: ArenaEnemy) -> void:
	enemy_count = maxi(0, enemy_count - 1)
	state.enemies_remaining = enemy_count
	state.wave_changed.emit(state.wave, enemy_count, 0.0)
	if enemy_count == 0 and mode == GameMode.FIGHTING:
		if state.wave >= MAX_WAVE:
			_on_victory()
		else:
			mode = GameMode.INTERMISSION
			countdown = 2.0
			state.mode_changed.emit("WAVE CLEARED", "Prepare for the next wave")

func _on_player_died() -> void:
	if mode == GameMode.GAME_OVER:
		return
	mode = GameMode.GAME_OVER
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over.visible = true

func _on_victory() -> void:
	if mode == GameMode.VICTORY:
		return
	mode = GameMode.VICTORY
	state.victory()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	victory.visible = true

func toggle_pause() -> void:
	if mode == GameMode.GAME_OVER or mode == GameMode.VICTORY:
		return
	if get_tree().paused:
		menu_primary()
	else:
		mode = GameMode.PAUSED
		get_tree().paused = true
		pause_menu.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func menu_primary() -> void:
	if mode == GameMode.MENU:
		_begin_game()
	elif mode == GameMode.PAUSED:
		mode = GameMode.FIGHTING if state.wave > 0 else GameMode.INTERMISSION
		pause_menu.visible = false
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		get_tree().reload_current_scene()

func spawn_impact(position: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = Color(1.0, 0.35, 0.08)
	light.light_energy = 2.0
	light.omni_range = 2.0
	add_child(light)
	var timer := get_tree().create_timer(0.08)
	timer.timeout.connect(light.queue_free)

func spawn_death_effect(position: Vector3) -> void:
	spawn_impact(position)
