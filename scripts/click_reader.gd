class_name ClickReader
extends Node

signal click
signal double_click
signal press_started
signal press_progress(seconds: float, ratio: float)
signal cancelled
signal press_released
signal hold_started
signal hold_progress(ratio: float)
signal hold_completed
signal hold_released

const Settings = preload("res://scripts/autoload/config.gd")
enum Mode { IMMEDIATE, WINDOWED }
@export var mode: Mode = Mode.WINDOWED
@export var hold_completion_time: float = Settings.TEMPO_APARAFUSAR

var _enabled: bool = true
var _cooldown: float = 0.0
var _discard_until_release: bool = false
var _physical_pressed: bool = false
var _pressed: bool = false
var _press_time: float = 0.0
var _pending_click: bool = false
var _double_elapsed: float = 0.0
var _holding: bool = false
var _hold_done: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	_physical_pressed = event.pressed
	if not _enabled or _cooldown > 0.0 or _discard_until_release:
		_discard_until_release = event.pressed
		return
	if event.pressed:
		if _pressed:
			return
		_pressed = true
		_press_time = 0.0
		_holding = false
		_hold_done = false
		press_started.emit()
	else:
		if not _pressed:
			return
		_pressed = false
		if _holding:
			hold_released.emit()
		elif mode == Mode.IMMEDIATE:
			click.emit()
		elif _pending_click:
			_pending_click = false
			double_click.emit()
		else:
			_pending_click = true
			_double_elapsed = 0.0
		press_released.emit()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if not _enabled or _cooldown > 0.0 or _discard_until_release:
		return
	if _pressed:
		_press_time += delta
		if not _holding and _press_time >= Settings.LIMIAR_SEGURAR:
			_holding = true
			# O segundo pressionamento virou longo: o primeiro era um clique.
			if _pending_click:
				_pending_click = false
				click.emit()
				if not _pressed or not _enabled:
					return
			hold_started.emit()
		press_progress.emit(_press_time, clampf(_press_time / hold_completion_time, 0.0, 1.0))
		if _holding:
			var ratio := clampf(_press_time / hold_completion_time, 0.0, 1.0)
			hold_progress.emit(ratio)
			if ratio >= 1.0 and not _hold_done:
				_hold_done = true
				hold_completed.emit()
	# Com o segundo botão apertado, sua duração decide clique ou segurar.
	elif _pending_click:
		_double_elapsed += delta
		if _double_elapsed > Settings.JANELA_DUPLO:
			_pending_click = false
			click.emit()

func reset() -> void:
	_discard_until_release = _physical_pressed or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_pressed = false
	_press_time = 0.0
	_pending_click = false
	_double_elapsed = 0.0
	_holding = false
	_hold_done = false
	cancelled.emit()

func set_enabled(value: bool) -> void:
	_enabled = value
	reset()

func block_for(seconds: float) -> void:
	reset()
	_cooldown = maxf(_cooldown, seconds)
