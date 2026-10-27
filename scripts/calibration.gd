
extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")

@onready var status_label: Label = $Status
@onready var clicks: ClickReader = $ClickReader

enum CalibrationStep {
	SINGLE_CLICK,
	DOUBLE_CLICK,
	HOLD,
	FINISHED
}

var current_step: CalibrationStep = CalibrationStep.SINGLE_CLICK


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), U.BG)

func _ready() -> void:
	for label in [$Heading, status_label, $Info]:
		label.add_theme_font_override("font", U.FONT)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", U.INK)
	$Heading.text = "CALIBRAÇÃO"
	$Heading.add_theme_font_size_override("font_size", 20)
	$Info.text = ""
	clicks.click.connect(_on_click)
	clicks.double_click.connect(_on_double_click)
	clicks.hold_started.connect(_on_hold_started)
	clicks.hold_progress.connect(_on_hold_progress)
	clicks.hold_completed.connect(_on_hold_completed)

	status_label.text = "1/3 · CLIQUE UMA VEZ"


func _on_click() -> void:
	if current_step != CalibrationStep.SINGLE_CLICK:
		return

	current_step = CalibrationStep.DOUBLE_CLICK
	status_label.text = "2/3 · CLIQUE DUAS VEZES"


func _on_double_click() -> void:
	if current_step != CalibrationStep.DOUBLE_CLICK:
		return

	current_step = CalibrationStep.HOLD
	status_label.text = "3/3 · SEGURE O BOTÃO"


func _on_hold_started() -> void:
	if current_step != CalibrationStep.HOLD:
		return

	status_label.text = "SEGURANDO..."


func _on_hold_progress(ratio: float) -> void:
	if current_step != CalibrationStep.HOLD:
		return

	status_label.text = "SEGURANDO: %d%%" % int(ratio * 100.0)


func _on_hold_completed() -> void:
	if current_step != CalibrationStep.HOLD:
		return

	current_step = CalibrationStep.FINISHED
	status_label.text = "CALIBRAÇÃO CONCLUÍDA!"

	await get_tree().create_timer(1.0).timeout

	get_tree().change_scene_to_file("res://scenes/game.tscn")
