extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
const PRESS = preload("res://audio/sfx/press.ogg")
const MOTOR = preload("res://audio/sfx/screwdriver_loop.wav")
const OPTIONS: Array[String] = ["JOGAR", "PLACAR", "SAIR"]
var selection: int = 0
var holding: bool = false
var hold_time: float = 0.0
var _click_sound: AudioStreamPlayer
var _hold_sound: AudioStreamPlayer

func _ready() -> void:
	_click_sound = AudioStreamPlayer.new()
	_click_sound.name = "MenuPress"
	_click_sound.stream = PRESS
	_click_sound.volume_db = -17.0
	_click_sound.max_polyphony = 3
	add_child(_click_sound)
	_hold_sound = AudioStreamPlayer.new()
	_hold_sound.name = "MenuHold"
	_hold_sound.volume_db = -14.0
	var motor_stream := MOTOR.duplicate() as AudioStreamWAV
	motor_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	motor_stream.loop_begin = 0
	motor_stream.loop_end = roundi(motor_stream.get_length() * motor_stream.mix_rate)
	_hold_sound.stream = motor_stream
	add_child(_hold_sound)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), U.BG)
	U.text(self, "UNIDADE", 40, 49, 30)
	U.text(self, "404", 212, 54, 40, U.AMBER)
	U.text(self, "FUTURO NÃO ENCONTRADO", 40, 69, 10, U.MUTED)
	for i in range(OPTIONS.size()):
		var y := 88 + i * 22
		if i == selection:
			draw_rect(Rect2(40, y, 240, 18), U.PANEL)
			draw_rect(Rect2(40, y, 2, 18), U.AMBER)
		U.text(self, OPTIONS[i], 52, y + 12, 10, U.INK if i == selection else U.MUTED)
		if holding and i == selection:
			var ratio := clampf(hold_time / Config.MENU_SEGURAR, 0.0, 1.0)
			draw_arc(Vector2(266, y + 9), 5, -PI / 2, -PI / 2 + TAU * ratio, 24, U.AMBER, 1)
	U.text(self, "CLIQUE: MUDAR / SEGURAR: ESCOLHER", 40, 175, 10, U.MUTED)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if event.pressed:
		_click_sound.play()
		holding = true
		hold_time = 0.0
	else:
		if not holding:
			return
		if hold_time < Config.LIMIAR_SEGURAR:
			selection = (selection + 1) % OPTIONS.size()
		holding = false
		_hold_sound.stop()
		hold_time = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if not holding:
		return
	hold_time += delta
	if hold_time >= Config.LIMIAR_SEGURAR and not _hold_sound.playing:
		_hold_sound.play()
	queue_redraw()
	if hold_time >= Config.MENU_SEGURAR:
		holding = false
		_hold_sound.stop()
		_choose()

func _choose() -> void:
	match selection:
		0:
			GameState.new_robot()
			get_tree().change_scene_to_file("res://scenes/intro.tscn")
		1:
			get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")
		2:
			get_tree().quit()
