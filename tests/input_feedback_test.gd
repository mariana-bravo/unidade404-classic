extends Node
var reader: ClickReader
var controller: InteractionController
var run: RunManager
var feedback: GameFeedback
var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _pair(kind: int) -> void:
	for node in [reader, controller, run, feedback]:
		if is_instance_valid(node):
			node.free()
	reader = ClickReader.new()
	controller = InteractionController.new()
	run = RunManager.new()
	feedback = GameFeedback.new()
	for node in [reader, controller, run, feedback]:
		add_child(node)
		node.set_process(false)
	reader.click.connect(controller.gesture_click)
	reader.double_click.connect(controller.gesture_double_click)
	reader.hold_completed.connect(controller.gesture_hold)
	reader.press_started.connect(controller.begin_press)
	reader.hold_started.connect(controller.begin_press)
	reader.press_released.connect(controller.end_press)
	controller.wrong_action.connect(func(_reason: String): run.finish_run(RunManager.MOTIVO_ACAO_INCORRETA))
	feedback.bind_input(reader, controller, run)
	controller.slot_completed.connect(func(): feedback.complete_slot(false))
	controller.set_slot(kind)
	run.start_run()

func _button(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	reader._unhandled_input(event)

func _tick(seconds: float) -> void:
	reader._process(seconds)
	controller._process(seconds)

func _tap() -> void:
	_button(true)
	_tick(0.05)
	_button(false)

func _single() -> void:
	_tap()
	_tick(0.29)

func _double() -> void:
	_tap()
	_tick(0.1)
	_tap()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	_pair(InteractionController.SlotKind.SCREW)
	_button(true)
	_check(feedback._press_pulse > 0 and feedback._tool == InteractionController.Tool.NONE, "Resposta imediata nao confirma ferramenta")
	_check(feedback._ui.playing and feedback._ui.stream == GameFeedback.PRESS, "Clique inicial toca")
	_tick(0.05)
	_button(false)
	_tick(0.1)
	_tap()
	_check(feedback._tool == InteractionController.Tool.SCREWDRIVER and feedback._ui.stream == GameFeedback.SELECT_SCREWDRIVER, "Chave confirmada tem indicador e som")
	_button(true)
	_tick(0.05)
	_check(not feedback._ring_visible, "Anel nao aparece antes de 0.1 segundo")
	_tick(0.06)
	_check(feedback._ring_visible and feedback._ratio > 0, "Anel aparece com progresso apos atraso")
	_check(not feedback._motor.playing, "Motor aguarda classificacao de segurar")
	_tick(0.21)
	_check(feedback._motor.playing, "Segurar inicia motor")
	_button(false)
	_check(not feedback._motor.playing and not feedback._ring_visible and is_zero_approx(feedback._ratio), "Soltar cancela motor e anel")
	_check(run.running and not feedback._stopped, "Cancelamento nao produz erro")
	_button(true)
	_tick(0.4)
	reader.set_enabled(false)
	_check(not feedback._motor.playing and not feedback._ring_visible, "Bloqueio interrompe feedback")
	_button(false)
	reader.set_enabled(true)
	_button(true)
	_tick(0.91)
	_check(not feedback._motor.playing and feedback._success.stream == GameFeedback.SLOT_COMPLETE, "Conclusao para motor e confirma slot")
	_button(false)

	_pair(InteractionController.SlotKind.RUSTY_SCREW)
	_double()
	_tap()
	_tick(0.1)
	_button(true)
	_tick(0.31)
	_check(feedback._prepared and feedback._motor.playing and feedback._ring_visible, "Curto mais longo mostra preparo e motor")
	_button(false)
	_tick(0.8)
	_check(not feedback._prepared and run.running, "Expiracao apaga preparo sem erro")
	_single()
	_check(feedback._prepared and feedback._ui.stream == GameFeedback.PREPARE, "Preparo reconhecido toca estalo")
	_button(true)
	_tick(0.91)
	_check(not feedback._motor.playing and not feedback._prepared, "Remocao concluida encerra motor e preparo")
	_button(false)

	_pair(InteractionController.SlotKind.NAIL)
	_single()
	_check(feedback._tool == InteractionController.Tool.HAMMER and feedback._ui.stream == GameFeedback.SELECT_HAMMER, "Martelo possui confirmacao distinta")
	_single()
	_check(feedback._mechanical.stream == GameFeedback.HAMMER, "Martelada usa impacto mecanico")
	feedback.complete_slot(true)
	_check(feedback._success.stream == GameFeedback.BOARD_COMPLETE, "Placa completa possui som distinto")
	controller.set_slot(InteractionController.SlotKind.NAIL)
	_check(feedback._tool == InteractionController.Tool.NONE, "Proximo slot limpa selecao")

	_pair(InteractionController.SlotKind.BAD_NAIL)
	_single()
	_double()
	_check(feedback._mechanical.stream == GameFeedback.REMOVE, "Remover prego usa impacto diferente")

	_pair(InteractionController.SlotKind.NAIL)
	run._process(5.6)
	_check(feedback._warning.stream == GameFeedback.TIME_LOW, "Tempo baixo dispara aviso")
	feedback._warning.stop()
	run._process(0.1)
	_check(not feedback._warning.playing, "Alerta nao repete a cada quadro")
	_double()
	_check(feedback._stopped and feedback._flash > 0 and feedback._warning.stream == GameFeedback.ERROR, "Erro produz flash e buzzer")
	_check(not feedback._motor.playing, "Game over para motor")
	var old_tool := feedback._tool
	feedback._on_tool_selected(InteractionController.Tool.SCREWDRIVER)
	_check(feedback._tool == old_tool, "Game over ignora feedback tardio")
	feedback._process(0.3)
	_check(is_zero_approx(feedback._flash), "Flash desaparece")
	_check(feedback.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Feedback nao captura mouse")
	_check(GameFeedback.SELECT_HAMMER.get_length() > 0 and GameFeedback.HAMMER.get_length() > 0 and GameFeedback.MOTOR.get_length() > 0, "Audios importados possuem duracao")
	print("INPUT FEEDBACK: %d checks, %d failures" % [checks, failures])
	for node in [reader, controller, run, feedback]:
		node.free()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if failures == 0 else 1)
