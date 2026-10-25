
extends Control

@onready var status_label: Label = $Status
@onready var clicks: ClickReader = $ClickReader

enum CalibrationStep {
	SINGLE_CLICK,
	DOUBLE_CLICK,
	HOLD,
	FINISHED
}

var current_step: CalibrationStep = CalibrationStep.SINGLE_CLICK


func _ready() -> void:
	clicks.click.connect(_on_click)
	clicks.double_click.connect(_on_double_click)
	clicks.hold_started.connect(_on_hold_started)
	clicks.hold_progress.connect(_on_hold_progress)
	clicks.hold_completed.connect(_on_hold_completed)

	status_label.text = "CALIBRACAO 1/3: CLIQUE UMA VEZ"


func _on_click() -> void:
	if current_step != CalibrationStep.SINGLE_CLICK:
		return

	current_step = CalibrationStep.DOUBLE_CLICK
	status_label.text = "CALIBRACAO 2/3: CLIQUE DUAS VEZES"


func _on_double_click() -> void:
	if current_step != CalibrationStep.DOUBLE_CLICK:
		return

	current_step = CalibrationStep.HOLD
	status_label.text = "CALIBRACAO 3/3: SEGURE O BOTAO"


func _on_hold_started() -> void:
	if current_step != CalibrationStep.HOLD:
		return

	status_label.text = "CALIBRACAO 3/3: SEGURANDO..."


func _on_hold_progress(ratio: float) -> void:
	if current_step != CalibrationStep.HOLD:
		return

	status_label.text = "SEGURANDO: %d%%" % int(ratio * 100.0)


func _on_hold_completed() -> void:
	if current_step != CalibrationStep.HOLD:
		return

	current_step = CalibrationStep.FINISHED
	status_label.text = "CALIBRACAO CONCLUIDA!"

	await get_tree().create_timer(1.0).timeout

	get_tree().change_scene_to_file("res://scenes/game.tscn")
