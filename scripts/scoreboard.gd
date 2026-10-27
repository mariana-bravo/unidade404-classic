extends Control
var held: bool = false
var elapsed: float = 0.0
var _rows: Array[Array] = []
var _progress: ProgressBar

func _ready() -> void:
	_build_table()
	ScoreboardData.changed.connect(_refresh)
	_refresh()

func _build_table() -> void:
	_label("PLACAR", Vector2(16, 14), Vector2(288, 22), 16)
	_label("NOME", Vector2(16, 48), Vector2(156, 12), 9)
	_label("TEMPO", Vector2(176, 48), Vector2(48, 12), 9)
	_label("PONTUAÇÃO", Vector2(228, 48), Vector2(76, 12), 9, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(3):
		var y := 70.0 + i * 22.0
		_rows.append([
			_label("---", Vector2(16, y), Vector2(156, 14), 9),
			_label("---", Vector2(176, y), Vector2(48, 14), 9),
			_label("---", Vector2(228, y), Vector2(76, 14), 9, HORIZONTAL_ALIGNMENT_RIGHT)])
	_label("SEGURAR: VOLTAR", Vector2(16, 147), Vector2(288, 14), 9, HORIZONTAL_ALIGNMENT_CENTER)
	_progress = ProgressBar.new()
	_progress.position = Vector2(104, 165)
	_progress.size = Vector2(112, 4)
	_progress.max_value = Config.MENU_SEGURAR
	_progress.show_percentage = false
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress)

func _refresh() -> void:
	var entries := ScoreboardData.get_entries()
	for i in range(3):
		var row := _rows[i]
		if i >= entries.size():
			for label in row:
				label.text = "---"
			continue
		var entry := entries[i]
		row[0].text = entry["name"]
		var seconds := int(entry["life_seconds"])
		row[1].text = "%02d:%02d" % [seconds / 60, seconds % 60]
		row[2].text = str(entry["score"])

func _label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.85))
	add_child(label)
	label.size = dimensions
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		held = event.pressed
		elapsed = 0.0
		_progress.value = 0.0

func _process(delta: float) -> void:
	if not held:
		return
	elapsed += delta
	_progress.value = elapsed
	if elapsed >= Config.MENU_SEGURAR:
		held = false
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
