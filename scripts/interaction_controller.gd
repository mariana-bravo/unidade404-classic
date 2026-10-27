class_name InteractionController
extends Node

signal tool_selected(tool:int)
signal step_completed
signal slot_completed
signal replacement_requested
signal wrong_action(reason: String)
signal phase_changed

enum Tool{
	NONE,
	HAMMER,
	SCREWDRIVER
}

enum SlotKind{
	NAIL,
	SCREW,
	BAD_NAIL,
	RUSTY_SCREW
}

enum Phase{
	SELECT_TOOL,
	ACT,
	UNSCREW_HOLD,
	WAIT_REPLACEMENT,
	ACT_NO_SELECT,
	DONE
}

const Settings = preload("res://scripts/autoload/config.gd")
var _prepare_left: float = 0.0
var _prepare_pressed: bool = false

var kind: SlotKind = SlotKind.NAIL
var phase:Phase = Phase.SELECT_TOOL
var tool:Tool = Tool.NONE

func set_slot(new_kind:SlotKind) -> void:
	kind = new_kind
	phase = Phase.SELECT_TOOL
	tool = Tool.NONE
	_prepare_left = 0.0
	_prepare_pressed = false
	phase_changed.emit()

# A janela limita o início do pressionamento, não sua duração.
func _process(delta: float) -> void:
	if phase != Phase.UNSCREW_HOLD or _prepare_pressed:
		return
	_prepare_left = maxf(0.0, _prepare_left - delta)
	if _prepare_left <= 0.0:
		phase = Phase.ACT
		phase_changed.emit()

func begin_press() -> void:
	if phase == Phase.UNSCREW_HOLD:
		_prepare_pressed = true

func end_press() -> void:
	_prepare_pressed = false

func gesture_click() -> void:
	_gesture("click")

func gesture_double_click() -> void:
	_gesture("double")

func gesture_hold() -> void:
	_gesture("hold")


func _gesture(gesture: String) -> void:

	# Ignora gestos durante a substituição
	# ou depois da conclusão do slot.
	if phase == Phase.WAIT_REPLACEMENT or phase == Phase.DONE:
		return

	# Seleção da ferramenta.
	if phase == Phase.SELECT_TOOL:
		if gesture == "hold":
			return

		var selected: Tool = (
			Tool.HAMMER
			if gesture == "click"
			else Tool.SCREWDRIVER
		)

		var expected: Tool = (
			Tool.HAMMER
			if kind == SlotKind.NAIL or kind == SlotKind.BAD_NAIL
			else Tool.SCREWDRIVER
		)

		if selected != expected:
			wrong_action.emit("FERRAMENTA ERRADA")
			return

		tool = selected
		phase = Phase.ACT
		tool_selected.emit(int(tool))
		return

	# Parafuso enferrujado:
	# primeiro clique simples da remoção.
	if kind == SlotKind.RUSTY_SCREW and phase == Phase.ACT:
		if gesture != "click":
			wrong_action.emit("CLIQUE ANTES DE DESAPARAFUSAR")
			return

		phase = Phase.UNSCREW_HOLD
		_prepare_left = Settings.JANELA_CLIQUE_LONGO
		phase_changed.emit()
		return

	# Parafuso enferrujado:
	# agora exige um clique longo.
	if phase == Phase.UNSCREW_HOLD:
		if gesture != "hold":
			wrong_action.emit("SEGURE PARA DESAPARAFUSAR")
			return

		step_completed.emit()
		phase = Phase.WAIT_REPLACEMENT
		replacement_requested.emit()
		return

	# Demais ações, incluindo a instalação
	# do novo parafuso após a substituição.
	var expected_gesture := (
        "hold"
		if kind == SlotKind.SCREW or kind == SlotKind.RUSTY_SCREW
		else (
            "double"
			if kind == SlotKind.BAD_NAIL and phase == Phase.ACT
			else "click"
		)
	)

	if gesture != expected_gesture:
		wrong_action.emit("GESTO ERRADO")
		return

	step_completed.emit()

	if kind == SlotKind.BAD_NAIL and phase == Phase.ACT:
		phase = Phase.WAIT_REPLACEMENT
		replacement_requested.emit()
	else:
		phase = Phase.DONE
		slot_completed.emit()


# Chamado após o braço auxiliar substituir a peça.
func replacement_finished() -> void:
	if phase == Phase.WAIT_REPLACEMENT:
		phase = Phase.ACT_NO_SELECT
		phase_changed.emit()
