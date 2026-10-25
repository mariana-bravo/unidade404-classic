extends Control

var selection: int = 0
const OPTIONS: Array[String] = ["JOGAR", "PLACAR", "SAIR"]
var holding: bool = false
var hold_time: float = 0.0

@onready var menu_label: Label = $MenuLabel
@onready var hint: Label = $Hint

func _ready() -> void:
	_draw_options()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if event.pressed:
		holding = true
		hold_time = 0.0
	else:
		if not holding:
			return
		if hold_time < Config.LIMIAR_SEGURAR:
			selection = (selection + 1) % OPTIONS.size()
			_draw_options()
		holding = false
		hint.text = "CLIQUE: MUDAR  ·  SEGURAR: ESCOLHER"

func _process(delta: float) -> void:
	if not holding:
		return
	hold_time += delta
	if hold_time >= Config.MENU_SEGURAR:
		holding = false
		_choose()
		return
	if hold_time >= Config.LIMIAR_SEGURAR:
		hint.text = "ESCOLHENDO... %d%%" % int(100.0 * minf(hold_time / Config.MENU_SEGURAR, 1.0))

func _draw_options() -> void:
	var lines: Array[String] = []
	for i in range(OPTIONS.size()):
		lines.append(("> " if i == selection else "  ") + OPTIONS[i])
	menu_label.text = "\n".join(lines)

func _choose() -> void:
	match selection:
		0:
			GameState.new_robot()
			get_tree().change_scene_to_file("res://scenes/intro.tscn")
		1:
			get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")
		2:
			get_tree().quit()
