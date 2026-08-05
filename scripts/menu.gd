extends Control

@export var screen_title: String = "MENU"
@export var primary_text: String = "PLAY"
var primary_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.025, 0.06, 0.92)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.size = Vector2(360, 220)
	box.position -= box.size / 2.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var title := Label.new()
	title.text = screen_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	primary_button = Button.new()
	primary_button.text = primary_text
	primary_button.custom_minimum_size = Vector2(0, 52)
	primary_button.pressed.connect(_primary)
	box.add_child(primary_button)
	var quit := Button.new()
	quit.text = "QUIT"
	quit.custom_minimum_size = Vector2(0, 44)
	quit.pressed.connect(_quit)
	box.add_child(quit)

func _input(event: InputEvent) -> void:
	if not visible or primary_button == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if primary_button.get_global_rect().has_point(event.position):
			_primary()
func _primary() -> void:
	get_tree().call_group("game", "play_sound", "ui_click")
	var game := get_tree().get_first_node_in_group("game") as Node
	if game != null and game.has_method("menu_primary"):
		game.menu_primary()
	else:
		get_tree().reload_current_scene()

func _quit() -> void:
	get_tree().quit()
