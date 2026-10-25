extends Control

@onready var status_label: Label = $Status
@onready var clicks: ClickReader = $ClickReader

func _ready() -> void:
	clicks.click.connect(func(): status_label.text = "GESTO: CLIQUE")
	clicks.double_click.connect(func(): status_label.text = "GESTO: DUPLO CLIQUE")
	clicks.hold_started.connect(func(): status_label.text = "GESTO: SEGURANDO...")
	clicks.hold_progress.connect(func(ratio: float): status_label.text = "SEGURANDO: %d%%" % int(100.0 * ratio))
	clicks.hold_completed.connect(func(): status_label.text = "GESTO: SEGURAR COMPLETO")
	clicks.hold_released.connect(func(): status_label.text = "GESTO: SOLTOU")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
