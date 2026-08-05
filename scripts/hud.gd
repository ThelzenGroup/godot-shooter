extends CanvasLayer

var health_label: Label
var ammo_label: Label
var status_label: Label
var crosshair: Label
var vignette: ColorRect
var state: GameStateModel

func _ready() -> void:
	var root := Control.new()
	state = get_node("/root/GameState") as GameStateModel
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	root.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	health_label = Label.new()
	ammo_label = Label.new()
	status_label = Label.new()
	for label in [health_label, ammo_label, status_label]:
		label.add_theme_font_size_override("font_size", 20)
		column.add_child(label)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.size = Vector2(48, 48)
	crosshair.position -= crosshair.size / 2.0
	crosshair.add_theme_font_size_override("font_size", 28)
	root.add_child(crosshair)
	vignette = ColorRect.new()
	vignette.color = Color(0.8, 0.0, 0.0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vignette)
	state.health_changed.connect(_health)
	state.ammo_changed.connect(_ammo)
	state.wave_changed.connect(_wave)
	_health(state.health, state.max_health)
	_ammo(state.ammo, state.reserve)
	_wave(state.wave, state.enemies_remaining, 0.0)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as ArenaPlayer
	if player != null and vignette != null:
		vignette.color.a = clampf(player.damage_flash * 2.2, 0.0, 0.5)

func _health(value: int, maximum: int) -> void:
	if health_label != null:
		health_label.text = "HEALTH  %d / %d" % [value, maximum]

func _ammo(current: int, reserve: int) -> void:
	if ammo_label != null:
		ammo_label.text = "AMMO  %d / %d" % [current, reserve]

func _wave(value: int, remaining: int, countdown: float) -> void:
	if status_label != null:
		status_label.text = "SCORE  %d    WAVE  %d / %d    ENEMIES  %d" % [state.score, value, GameConstants.MAX_WAVE, remaining]
		if countdown > 0.0:
			status_label.text += "    NEXT WAVE %.1f" % countdown
