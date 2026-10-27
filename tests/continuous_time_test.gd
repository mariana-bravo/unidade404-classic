extends Node
var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _new_game() -> Node2D:
	var game = preload("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.run_manager.set_process(false)
	return game

func _run() -> void:
	# Arquivo exclusivo: testes não modificam o placar do jogador.
	ScoreboardData.save_path = "user://scoreboard_test_%s_%d.dat" % [name, Time.get_ticks_usec()]
	ScoreboardData.load_scores()
	var expected := [3.40, 4.55, 5.825, 9.375]
	for kind in range(4):
		_check(is_equal_approx(TimeModel.tempo_concedido(kind, 0), expected[kind]), "Recompensa nivel 1 tipo %d" % kind)
		_check(is_equal_approx(TimeModel.tempo_concedido(kind, 0, 2.0), expected[kind] + 2.0), "Ultimo slot compensa esteira tipo %d" % kind)
	_check(is_equal_approx(TimeModel.tempo_concedido(TimeModel.SlotKind.RUSTY_SCREW, 45), 4.685), "Substituicao nao perde compensacao com dificuldade")
	var game = _new_game()
	game.run_manager._process(0.5)
	_check(is_equal_approx(game.run_manager.time_left, 7.5), "Drena durante entrada inicial")
	_check(is_equal_approx(game.run_manager.life_time, 0.5), "Vida inclui automacoes")
	await get_tree().create_timer(1.1).timeout
	game.current_board.assign([InteractionController.SlotKind.NAIL])
	game.current_slot = 0
	game.start_slot()
	game.run_manager.time_left = 1.0
	game.conveyor.movement_duration = 0.3
	game.controller.gesture_click()
	game.controller.gesture_click()
	_check(is_equal_approx(game.run_manager.time_left, 5.0), "Bonus final usa duracao real da esteira")
	game.run_manager._process(0.2)
	_check(is_equal_approx(game.run_manager.time_left, 4.8), "Drena durante saida da placa")
	game.run_manager.time_left = 0.05
	game.run_manager._process(0.1)
	var position_at_death: Vector2 = game.conveyor.board.position
	await get_tree().create_timer(0.7).timeout
	_check(not game.run_manager.running and not game.click_reader._enabled, "Morte na saida nao reativa input")
	_check(game.conveyor.board.position == position_at_death and not game.conveyor.moving, "Esteira congela na morte")
	_check(game.current_slot == 1, "Morte na saida nao gera nova placa")
	game.free()

	game = _new_game()
	await get_tree().create_timer(1.1).timeout
	game.current_board.assign([InteractionController.SlotKind.BAD_NAIL])
	game.current_slot = 0
	game.start_slot()
	game.controller.gesture_click()
	game.controller.gesture_double_click()
	game.run_manager._process(0.3)
	_check(is_equal_approx(game.run_manager.time_left, 7.7), "Drena durante substituicao")
	game.run_manager.time_left = 0.05
	game.run_manager._process(0.1)
	await get_tree().create_timer(1.1).timeout
	_check(not game.click_reader._enabled and game.controller.phase == InteractionController.Phase.WAIT_REPLACEMENT, "Morte na substituicao nao retoma instalacao")
	game.free()

	game = _new_game()
	game.run_manager.time_left = 0.01
	game.run_manager._process(0.02)
	await get_tree().create_timer(1.1).timeout
	_check(game.board_transitioning and not game.click_reader._enabled, "Morte na entrada nao inicia slot")
	game.free()

	var rm := RunManager.new()
	add_child(rm)
	rm.set_process(false)
	rm.start_run()
	rm.on_slot_completed(TimeModel.SlotKind.RUSTY_SCREW, 2.0)
	_check(is_equal_approx(rm.time_left, 10.0), "Bonus respeita teto de 10 segundos")
	rm.time_left = 0.01
	rm._process(0.02)
	rm.on_slot_completed(TimeModel.SlotKind.RUSTY_SCREW, 2.0)
	_check(is_zero_approx(rm.time_left) and rm.score == 10, "Conclusao tardia nao revive nem pontua")
	rm.free()
	print("CONTINUOUS TIME: %d checks, %d failures" % [checks, failures])
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ScoreboardData.save_path + suffix):
			DirAccess.remove_absolute(ScoreboardData.save_path + suffix)
	# O servidor de áudio libera os playbacks em seu próximo ciclo.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if failures == 0 else 1)
