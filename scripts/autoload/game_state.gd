extends Node
signal robot_changed(robot_name: String, gender: String, serial: int, color_index: int)

var reboot_pending: bool = false
var robot_name: String = ""
var robot_gender: String = "m"
var serial: int = 0
var color_index: int = 0
var score: int = 0
var life_seconds: float = 0.0
var level: int = 1

func new_robot() -> void:
	serial += 1
	var generated: Dictionary = NameGenerator.gerar_nome_robo()
	while generated["nome"] == robot_name:
		generated = NameGenerator.gerar_nome_robo()
	robot_name = generated["nome"]
	robot_gender = generated["genero"]
	# A primeira unidade pode usar qualquer cor; as seguintes não repetem a anterior.
	if serial == 1 or Config.PALETA.size() <= 1:
		color_index = randi_range(0, Config.PALETA.size() - 1)
	else:
		color_index = (color_index + randi_range(1, Config.PALETA.size() - 1)) % Config.PALETA.size()
	score = 0
	life_seconds = 0.0
	level = 1
	robot_changed.emit(robot_name, robot_gender, serial, color_index)
