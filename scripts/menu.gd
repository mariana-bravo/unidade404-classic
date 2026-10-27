extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
const OPTIONS: Array[String] = ["JOGAR", "PLACAR", "SAIR"]
var selection: int = 0
var holding: bool = false
var hold_time: float = 0.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), U.BG)
	U.text(self, "UNIDADE", 40, 49, 30)
	U.text(self, "404", 212, 54, 40, U.AMBER)
	U.text(self, "FUTURO NÃO ENCONTRADO", 40, 69, 10, U.MUTED)
	for i in range(3):
		var y := 88 + i * 22
		if i == selection:
			draw_rect(Rect2(40, y, 240, 18), U.PANEL)
			draw_rect(Rect2(40, y, 2, 18), U.AMBER)
		U.text(self, OPTIONS[i], 52, y + 12, 10, U.INK if i == selection else U.MUTED)
		if holding and i == selection:
			var ratio := clampf(hold_time / Config.MENU_SEGURAR, 0.0, 1.0)
			draw_arc(Vector2(266, y + 9), 5, -PI / 2, -PI / 2 + TAU * ratio, 24, U.AMBER, 1)
	U.text(self, "CLIQUE: MUDAR / SEGURAR: ESCOLHER", 40, 175, 10, U.MUTED)

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
		holding = false
	queue_redraw()

func _process(delta: float) -> void:
	if not holding:
		return
	hold_time += delta
	queue_redraw()
	if hold_time >= Config.MENU_SEGURAR:
		holding = false
		_choose()

func _choose() -> void:
	match selection:
		0:
			GameState.new_robot()
			get_tree().change_scene_to_file("res://scenes/intro.tscn")
		1:
			get_tree().change_scene_to_file("res://scenes/scoreboard.tscn")
		2:
			get_tree().quit()
