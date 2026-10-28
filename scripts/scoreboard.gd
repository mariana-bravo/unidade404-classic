extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
const MOTOR = preload("res://audio/sfx/screwdriver_loop.wav")
var _hold_sound: AudioStreamPlayer
var held: bool = false
var elapsed: float = 0.0
var _entries: Array[Dictionary] = []

func _ready() -> void:
	_hold_sound = AudioStreamPlayer.new()
	_hold_sound.name = "ScoreboardHold"
	_hold_sound.volume_db = -14.0
	var motor_stream := MOTOR.duplicate() as AudioStreamWAV
	motor_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	motor_stream.loop_begin = 0
	motor_stream.loop_end = roundi(motor_stream.get_length() * motor_stream.mix_rate)
	_hold_sound.stream = motor_stream
	add_child(_hold_sound)
	ScoreboardData.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	_entries = ScoreboardData.get_entries()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), U.BG)
	U.text(self, "PLACAR", 24, 40, 20)
	U.text(self, "UNIDADE", 40, 77, 10, U.MUTED)
	U.text(self, "VIDA", 191, 77, 10, U.MUTED)
	U.text(self, "PONTOS", 258, 77, 10, U.MUTED)
	for i in range(3):
		var y := 84 + i * 23
		if i == 0 and not _entries.is_empty():
			draw_rect(Rect2(12, y, 296, 20), U.PANEL)
			draw_rect(Rect2(12, y, 2, 20), U.AMBER)
		draw_line(Vector2(12, y + 20), Vector2(308, y + 20), U.LINE)
		U.text(self, "%02d" % (i + 1), 18, y + 13, 10, U.AMBER if i == 0 else U.MUTED)
		var name_text := "---"
		var name_color := U.INK
		var life_text := "---"
		var score_text := "---"
		if i < _entries.size():
			name_text = _entries[i]["name"].to_upper()
			name_color = Color.hex(_entries[i]["color"])
			var seconds := int(_entries[i]["life_seconds"])
			life_text = "%02d:%02d" % [seconds / 60, seconds % 60]
			score_text = str(_entries[i]["score"])
		U.text(self, name_text, 40, y + 13, 10, name_color, 143)
		U.text(self, life_text, 191, y + 13, 10, U.MUTED, 58)
		U.text(self, score_text, 251, y + 13, 10, U.AMBER if i == 0 else U.INK, 50, HORIZONTAL_ALIGNMENT_RIGHT)
	U.text(self, "SEGURAR: VOLTAR", 24, 175, 10, U.MUTED)
	if held:
		draw_arc(Vector2(290, 171), 5, -PI / 2, -PI / 2 + TAU * minf(elapsed / Config.MENU_SEGURAR, 1.0), 24, U.AMBER, 1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		held = event.pressed
		if not held:
			_hold_sound.stop()
		elapsed = 0.0
		queue_redraw()

func _process(delta: float) -> void:
	if held:
		elapsed += delta
		if elapsed >= Config.LIMIAR_SEGURAR and not _hold_sound.playing:
			_hold_sound.play()
		queue_redraw()
		if elapsed >= Config.MENU_SEGURAR:
			held = false
			_hold_sound.stop()
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
