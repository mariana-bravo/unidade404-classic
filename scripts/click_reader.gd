class_name ClickReader
extends Node

signal click
signal double_click
signal hold_started
signal hold_progress(ratio: float)
signal hold_completed
signal hold_released

enum Mode { IMMEDIATE, WINDOWED }
@export var mode: Mode = Mode.WINDOWED
@export var hold_completion_time: float = 0.90

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
	if event.pressed:
		if _pressed:
			return
		_pressed = true
		_press_time = 0.0
		_holding = false
		_hold_done = false
	else:
		if not _pressed:
			return
		_pressed = false
		if _holding:
			hold_released.emit()
			return
		if mode == Mode.IMMEDIATE:
			click.emit()
		elif _pending_click and _double_elapsed <= Config.JANELA_DUPLO:
			_pending_click = false
			double_click.emit()
		else:
			_pending_click = true
			_double_elapsed = 0.0

func _process(delta: float) -> void:
	if _pressed:
		_press_time += delta
		if not _holding and _press_time >= Config.LIMIAR_SEGURAR:
			_holding = true
			_pending_click = false
			hold_started.emit()
		if _holding:
			var ratio: float = clampf(_press_time / hold_completion_time, 0.0, 1.0)
			hold_progress.emit(ratio)
			if ratio >= 1.0 and not _hold_done:
				_hold_done = true
				hold_completed.emit()
	if _pending_click:
		_double_elapsed += delta
		if _double_elapsed > Config.JANELA_DUPLO:
			_pending_click = false
			click.emit()

func reset() -> void:
	_pressed = false
	_pending_click = false
	_holding = false
	_hold_done = false
