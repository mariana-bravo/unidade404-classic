extends Node
## Testa a cena real e seus sinais. Use -- --capture para gerar uma imagem do HUD.
var game: Node2D
var checks: int = 0
var failures: int = 0

func _ready() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	game.click_reader._unhandled_input(event)

func _tick(seconds: float) -> void:
	game.click_reader._process(seconds)
	game.controller._process(seconds)

func _tap() -> void:
	_button(true)
	_tick(0.05)
	_button(false)

func _single() -> void:
	_tap()
	_tick(0.29)

func _double() -> void:
	_tap()
	_tick(0.10)
	_tap()

func _run() -> void:
	var previous_mode := Input.mouse_mode
	game = preload("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.run_manager.set_process(false)
	game.click_reader.set_process(false)
	game.controller.set_process(false)
	_check(game.run_manager.running, "Relogio ativo na entrada")
	_button(true)
	await get_tree().create_timer(1.15).timeout
	_tick(1.0)
	_button(false)
	_tick(0.3)
	_check(game.controller.phase == InteractionController.Phase.SELECT_TOOL, "Entrada nao reaproveita pressionamento")
	_check(game.run_manager.running, "Relogio continua ativo depois da entrada")
	_check(is_equal_approx(game.hud._bar_fill.size.x, 64.0), "HUD inicia com 8 de 10 segundos")
	_check(game.hud._score_label.text == "PONTOS 0000", "HUD inicia pontuacao")
	_check(game.hud._level_label.text == "NÍVEL 1", "HUD inicia nivel")
	_check(game.hud._name_label.text == GameState.robot_name, "HUD recebe nome")
	_check(game.hud._serial_label.text == "Nº %03d" % GameState.serial, "HUD recebe serie")
	_check(game.hud._frame.modulate == Config.PALETA[GameState.color_index], "HUD recebe cor")
	_check(game.hud._best_label.text == "RECORDE ---", "Recorde ainda indisponivel")
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "Cursor oculto")

	game.current_board.assign([InteractionController.SlotKind.NAIL, InteractionController.SlotKind.SCREW])
	game.current_slot = 0
	game.conveyor.set_slots(game.current_board)
	game.start_slot()
	_single()
	_single()
	_check(game.current_slot == 1 and game.run_manager.score == 10, "Slot completo avanca e pontua")
	_check(game.hud._score_label.text == "PONTOS 0010", "HUD atualiza pontos via sinal")
	_tap()
	_tick(0.3)
	_check(game.controller.phase == InteractionController.Phase.SELECT_TOOL, "Trava impede selecao residual")
	_double()
	_button(true)
	_tick(0.91)
	_check(game.board_transitioning and game.run_manager.running, "Relogio ativo durante esteira")
	_check(game.run_manager.score == 70, "Bonus de peca e slots")
	await get_tree().create_timer(2.15).timeout
	_tick(1.0)
	_button(false)
	_tick(0.3)
	_check(game.controller.phase == InteractionController.Phase.SELECT_TOOL and game.run_manager.running, "Esteira nao vaza gesto")

	game.current_board.assign([InteractionController.SlotKind.RUSTY_SCREW, InteractionController.SlotKind.NAIL])
	game.current_slot = 0
	game.conveyor.set_slots(game.current_board)
	game.start_slot()
	_double()
	_single()
	_button(true)
	_tick(0.91)
	_check(game.replacing and game.run_manager.running, "Relogio ativo durante substituicao")
	await get_tree().create_timer(1.15).timeout
	_tick(1.0)
	_check(game.controller.phase == InteractionController.Phase.ACT_NO_SELECT, "Substituicao nao reutiliza longo anterior")
	_button(false)
	_tick(0.3)
	_check(game.controller.phase == InteractionController.Phase.ACT_NO_SELECT and game.run_manager.running, "Soltar depois da substituicao nao executa acao")
	_button(true)
	_tick(0.91)
	_button(false)
	_check(game.current_slot == 1, "Novo pressionamento instala e avanca")

	for i in range(4):
		game.run_manager.on_piece_completed()
	_check(game.hud._level_label.text == "NÍVEL 2", "HUD acompanha mudanca de nivel")
	game.run_manager.time_left = 2.0
	game.run_manager.time_changed.emit(2.0)
	_check(game.hud._low and game.hud._bar_fill.color == VisorHud.COR_BARRA_BAIXA, "Tempo baixo usa ambar")
	game.run_manager.on_slot_completed(InteractionController.SlotKind.NAIL)
	_check(not game.hud._low and game.hud._bar_fill.size.x > 16.0, "Bonus recupera barra e remove alerta")
	GameState.new_robot()
	_check(game.hud._name_label.text == GameState.robot_name and game.hud._frame.modulate == Config.PALETA[GameState.color_index], "Mudanca de identidade atualiza HUD")

	if "--capture" in OS.get_cmdline_user_args():
		game.hud.set_robot("Estagiário Desempregado", GameState.serial)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/hud_preview.png")
	game.run_manager.finish_run(RunManager.MOTIVO_TEMPO_ESGOTADO)
	_button(true)
	_tick(1.0)
	_button(false)
	_check(not game.click_reader._enabled and game.board_transitioning, "Game over bloqueia gestos")
	game.free()
	_check(Input.mouse_mode == previous_mode, "Cursor restaurado ao sair")
	print("GAME INTEGRATION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
