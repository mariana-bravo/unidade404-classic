extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")

var pages: Array[String] = []
var page: int = 0
var visible_chars: float = 0.0
const CHARS_PER_SECOND: float = 28.0
@onready var text_label: Label = $Story

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), U.BG)

func _ready() -> void:
	text_label.add_theme_font_override("font", U.FONT)
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", U.INK)
	$Hint.add_theme_font_override("font", U.FONT)
	$Hint.add_theme_font_size_override("font_size", 10)
	$Hint.add_theme_color_override("font_color", U.MUTED)
	pages = ["A FÁBRICA NUNCA PARA.", "Humanos erram. Eles têm justificativas.", "Robôs não têm.", "UNIDADE 404: %s. ATIVADA. NÃO ERRE. NÃO DEMORE." % GameState.robot_name]
	_show_page()

func _process(delta: float) -> void:
	if text_label.visible_characters < text_label.get_total_character_count():
		visible_chars += CHARS_PER_SECOND * delta
		text_label.visible_characters = int(visible_chars)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if text_label.visible_characters < text_label.get_total_character_count():
		visible_chars = float(text_label.get_total_character_count())
		text_label.visible_characters = -1
	else:
		page += 1
		if page == pages.size():
			get_tree().change_scene_to_file("res://scenes/calibration.tscn")
		else:
			_show_page()

func _show_page() -> void:
	text_label.text = pages[page]
	visible_chars = 0.0
	text_label.visible_characters = 0
