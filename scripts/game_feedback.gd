class_name GameFeedback
extends Control
## Apresentação do input: não interpreta gestos nem altera o relógio.
const PRESS = preload("res://audio/sfx/press.ogg")
const SELECT_HAMMER = preload("res://audio/sfx/select_hammer.ogg")
const SELECT_SCREWDRIVER = preload("res://audio/sfx/select_screwdriver.ogg")
const PREPARE = preload("res://audio/sfx/prepare.ogg")
const HAMMER = preload("res://audio/sfx/hammer.ogg")
const REMOVE = preload("res://audio/sfx/remove.ogg")
const SLOT_COMPLETE = preload("res://audio/sfx/slot_complete.ogg")
const BOARD_COMPLETE = preload("res://audio/sfx/board_complete.ogg")
const ERROR = preload("res://audio/sfx/error.ogg")
const TIME_LOW = preload("res://audio/sfx/time_low.ogg")
const MOTOR = preload("res://audio/sfx/screwdriver_loop.wav")
const NEUTRAL := Color(0.5, 0.6, 0.65)
const ACTIVE := Color(0.65, 1.0, 0.8)
const AMBER := Color(1.0, 0.72, 0.15)

var _reader: ClickReader
var _controller: InteractionController
var _tool: int = InteractionController.Tool.NONE
var _prepared: bool = false
var _prepare_strength: float = 0.0
var _press_pulse: float = 0.0
var _flash: float = 0.0
var _ratio: float = 0.0
var _ring_visible: bool = false
var _stopped: bool = false
var _ui: AudioStreamPlayer
var _mechanical: AudioStreamPlayer
var _success: AudioStreamPlayer
var _warning: AudioStreamPlayer
var _motor: AudioStreamPlayer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui = _player("Interface", -17.0, 3)
	_mechanical = _player("Mechanical", -10.0, 2)
	_success = _player("Success", -14.0, 2)
	_warning = _player("Warning", -9.0, 1)
	_motor = _player("Motor", -14.0, 1)
	var stream := MOTOR.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_motor.stream = stream

func bind_input(reader: ClickReader, controller: InteractionController, run: RunManager) -> void:
	_reader = reader
	_controller = controller
	reader.press_started.connect(_on_press)
	reader.press_progress.connect(_on_press_progress)
	reader.hold_started.connect(_on_hold_started)
	reader.press_released.connect(clear_gesture)
	reader.cancelled.connect(clear_gesture)
	controller.tool_selected.connect(_on_tool_selected)
	controller.phase_changed.connect(_sync_phase)
	controller.step_completed.connect(_on_step_completed)
	run.time_low.connect(_on_time_low)
	run.run_finished.connect(_on_run_finished)
	_sync_phase()

func _player(player_name: String, volume: float, voices: int) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume
	player.max_polyphony = voices
	add_child(player)
	return player

func _play(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stream = stream
	player.play()

func _process(delta: float) -> void:
	_press_pulse = maxf(0.0, _press_pulse - delta)
	_flash = maxf(0.0, _flash - delta * 2.0)
	_prepare_strength = move_toward(_prepare_strength, 1.0 if _prepared else 0.0, delta * 7.0)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(202, 126)
	for i in range(2):
		var selected := _tool == i + 1
		var color := ACTIVE if selected else NEUTRAL
		var rect := Rect2(origin + Vector2(i * 53, 0), Vector2(50, 13))
		draw_rect(rect, Color(0.08, 0.14, 0.16))
		draw_rect(rect, color, false, 1.0)
		draw_string(font, rect.position + Vector2(3, 9), "MARTELO" if i == 0 else "CHAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, color)
	if _press_pulse > 0.0:
		draw_rect(Rect2(origin - Vector2.ONE, Vector2(105, 15)), Color(0.6, 0.9, 1.0, _press_pulse / 0.14), false)
	if _prepare_strength > 0.0:
		draw_string(font, origin + Vector2(0, 29), "PREPARADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(AMBER, _prepare_strength))
	if _ring_visible:
		var center := origin + Vector2(88, 32)
		draw_arc(center, 12, 0, TAU, 40, Color(0.2, 0.28, 0.3), 2.0)
		if _ratio > 0.0:
			draw_arc(center, 12, -PI / 2, -PI / 2 + TAU * _ratio, 40, AMBER if _prepared else ACTIVE, 2.0)
		draw_string(font, center + Vector2(-7, 3), "%d" % roundi(_ratio * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ACTIVE)
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, 320, 180), Color(1.0, 0.08, 0.04, _flash))

func _on_press() -> void:
	if _stopped:
		return
	if _controller.phase == InteractionController.Phase.SELECT_TOOL:
		_press_pulse = 0.14
		_play(_ui, PRESS)

func _can_hold() -> bool:
	if _stopped or _controller.tool != InteractionController.Tool.SCREWDRIVER:
		return false
	return _controller.phase == InteractionController.Phase.UNSCREW_HOLD \
		or _controller.phase == InteractionController.Phase.ACT_NO_SELECT \
		or (_controller.phase == InteractionController.Phase.ACT and _controller.kind == InteractionController.SlotKind.SCREW)

func _on_press_progress(seconds: float, ratio: float) -> void:
	if _can_hold():
		_ratio = ratio
		_ring_visible = seconds >= Config.ATRASO_ANEL

func _on_hold_started() -> void:
	if _can_hold():
		_motor.pitch_scale = 0.9 if _prepared else 1.0
		_motor.play()

func clear_gesture() -> void:
	_ring_visible = false
	_ratio = 0.0
	_motor.stop()
	_press_pulse = 0.0
	queue_redraw()

func _sync_phase() -> void:
	if _stopped:
		return
	_tool = _controller.tool
	var was_prepared := _prepared
	_prepared = _controller.phase == InteractionController.Phase.UNSCREW_HOLD
	if _prepared and not was_prepared:
		_play(_ui, PREPARE)
	queue_redraw()

func _on_tool_selected(tool: int) -> void:
	if _stopped:
		return
	_tool = tool
	_play(_ui, SELECT_HAMMER if tool == InteractionController.Tool.HAMMER else SELECT_SCREWDRIVER)
	queue_redraw()

func _on_step_completed() -> void:
	if _stopped:
		return
	clear_gesture()
	if _controller.tool == InteractionController.Tool.HAMMER:
		var removing := _controller.kind == InteractionController.SlotKind.BAD_NAIL and _controller.phase == InteractionController.Phase.ACT
		_play(_mechanical, REMOVE if removing else HAMMER)
	_prepared = false

func complete_slot(last_slot: bool) -> void:
	if not _stopped:
		clear_gesture()
		_tool = InteractionController.Tool.NONE
		_prepared = false
		_play(_success, BOARD_COMPLETE if last_slot else SLOT_COMPLETE)

func _on_time_low() -> void:
	if not _stopped:
		_play(_warning, TIME_LOW)

func _on_run_finished(_reason: String, _score: int, _life: float) -> void:
	_stopped = true
	clear_gesture()
	_ui.stop()
	_mechanical.stop()
	_success.stop()
	_prepared = false
	_prepare_strength = 0.0
	_flash = 0.35
	_play(_warning, ERROR)
	queue_redraw()


func _exit_tree() -> void:
	for player in [_ui, _mechanical, _success, _warning, _motor]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
