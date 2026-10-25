class_name InteractionController
extends Node

signal tool_selected(tool:int)
signal step_completed
signal slot_completed
signal replacement_requested
signal wrong_action(reason: String)

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
	WAIT_REPLACEMENT,
	ACT_NO_SELECT,
	DONE
}

var kind: SlotKind = SlotKind.NAIL
var phase:Phase = Phase.SELECT_TOOL
var tool:Tool = Tool.NONE

func set_slot(new_kind:SlotKind) -> void:
	kind = new_kind
	phase = Phase.SELECT_TOOL
	tool = Tool.NONE

func gesture_click() -> void:
	_gesture("click")

func gesture_double_click() -> void:
	_gesture("double")

func gesture_hold() -> void:
	_gesture("hold")

func _gesture(gesture: String) -> void:
	if phase == Phase.WAIT_REPLACEMENT or phase == Phase.DONE:
		return
	
	if phase == Phase.SELECT_TOOL:
		#Segurar não seleciona ferramenta
		if gesture == "hold":
			return
		var selected:Tool = (Tool.HAMMER if gesture == "click" else Tool.SCREWDRIVER)
		var expected: Tool = (Tool.HAMMER if kind == SlotKind.NAIL or kind == SlotKind.BAD_NAIL else Tool.SCREWDRIVER)
		
		#Ferramenta incorreta
		if selected != expected:
			wrong_action.emit("FERRAMENTA ERRADA")
			return
		
		#Ferramenta correta
		tool = selected
		phase = Phase.ACT
		tool_selected.emit(int(tool))
		return
	
	var expected_gesture := ("hold" if kind == SlotKind.SCREW or kind == SlotKind.RUSTY_SCREW else ("double" if kind == SlotKind.BAD_NAIL and phase == Phase.ACT else "click"))
	
	if gesture != expected_gesture:
		wrong_action.emit("GESTO ERRADO")
		return
	
	step_completed.emit()
	if (kind == SlotKind.BAD_NAIL or kind == SlotKind.RUSTY_SCREW) and phase == Phase.ACT:
		phase = Phase.WAIT_REPLACEMENT
		replacement_requested.emit()
	else:
		phase = Phase.DONE
		slot_completed.emit()
		
# Chamado após o braço auxiliar substituir a peça.
func replacement_finished() -> void:
	if phase == Phase.WAIT_REPLACEMENT:
		phase = Phase.ACT_NO_SELECT
