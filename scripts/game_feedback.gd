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
const U = preload("res://scripts/ui/industrial_ui.gd")
const NEUTRAL := U.MUTED
const ACTIVE := U.UNIT
const AMBER := U.AMBER

var _reader: ClickReader
var _controller: InteractionController
var _status: String = ""
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
	if not _stopped:
		U.visor_panel(self, Rect2(14, 138, 174, 25), ACTIVE)
		U.visor_panel(self, Rect2(216, 138, 88, 25), ACTIVE)
		U.text(self, "ESTADO DA UNIDADE", 20, 146, 8, ACTIVE)
		U.text(self, "FERRAMENTA", 222, 146, 8, ACTIVE)
		U.text(self, "MARTELO", 222, 157, 8, ACTIVE if _tool == InteractionController.Tool.HAMMER else NEUTRAL)
		U.text(self, "CHAVE", 258, 157, 8, ACTIVE if _tool == InteractionController.Tool.SCREWDRIVER else NEUTRAL)
		if _press_pulse > 0.0:
			draw_line(Vector2(222, 160), Vector2(282, 160), U.UNIT)
		if _status != "":
			U.text(self, _status, 20, 157, 10, U.INK, 164)
		elif _prepare_strength > 0.0:
			U.text(self, "PREPARADO", 20, 157, 10, Color(AMBER, _prepare_strength))
		if _ring_visible:
			draw_arc(Vector2(293, 151), 7, 0, TAU, 32, U.LINE, 1)
			draw_arc(Vector2(293, 151), 7, -PI / 2, -PI / 2 + TAU * maxf(_ratio, 0.001), 32, AMBER if _prepared else ACTIVE, 1)
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, 320, 180), Color(U.ERROR, _flash))

func show_status(message: String) -> void:
	_status = message
	queue_redraw()

func sync_phase() -> void:
	if _controller != null:
		_sync_phase()

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
	_status = "SELECIONE A FERRAMENTA" if _controller.phase == InteractionController.Phase.SELECT_TOOL else ("SUBSTITUINDO..." if _controller.phase == InteractionController.Phase.WAIT_REPLACEMENT else "")
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
