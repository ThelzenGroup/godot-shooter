extends Control

@export var screen_title: String = "MENU"
@export var primary_text: String = "PLAY"

func _ready() -> void:
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
	var action := Button.new()
	action.text = primary_text
	action.custom_minimum_size = Vector2(0, 52)
	action.pressed.connect(_primary)
	box.add_child(action)
	var quit := Button.new()
	quit.text = "QUIT"
	quit.custom_minimum_size = Vector2(0, 44)
	quit.pressed.connect(_quit)
	box.add_child(quit)

func _primary() -> void:
	if get_parent().has_method("menu_primary"):
		get_parent().menu_primary()
	else:
		get_tree().reload_current_scene()

func _quit() -> void:
	get_tree().quit()
