extends Node
## Execute: godot --headless --path . res://tests/input_regression_test.tscn
var reader: ClickReader
var controller: InteractionController
var events: Array[String] = []
var errors: Array[String] = []
var checks: int = 0
var failures: int = 0

func _ready() -> void:
	call_deferred("_run")

func _new_pair(kind: int = InteractionController.SlotKind.RUSTY_SCREW) -> void:
	if is_instance_valid(reader):
		reader.free()
	if is_instance_valid(controller):
		controller.free()
	events.clear()
	errors.clear()
	reader = ClickReader.new()
	controller = InteractionController.new()
	add_child(reader)
	add_child(controller)
	reader.set_process(false)
	controller.set_process(false)
	controller.set_slot(kind)
	reader.click.connect(func(): events.append("click"); controller.gesture_click())
	reader.double_click.connect(func(): events.append("double"); controller.gesture_double_click())
	reader.hold_completed.connect(func(): events.append("hold"); controller.gesture_hold())
	reader.press_started.connect(controller.begin_press)
	reader.hold_started.connect(controller.begin_press)
	reader.press_released.connect(controller.end_press)
	controller.wrong_action.connect(func(reason: String): errors.append(reason))

func _button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
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
	_tick(0.10)
	_tap()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	_new_pair(InteractionController.SlotKind.NAIL)
	_single()
	_check(controller.tool == InteractionController.Tool.HAMMER, "Clique seleciona martelo")
	_single()
	_check(controller.phase == InteractionController.Phase.DONE and errors.is_empty(), "Prego normal completo")

	_new_pair(InteractionController.SlotKind.SCREW)
	_double()
	_check(controller.tool == InteractionController.Tool.SCREWDRIVER, "Duplo seleciona chave")
	_button(true)
	_tick(0.5)
	_button(false)
	_check(controller.phase == InteractionController.Phase.ACT and errors.is_empty(), "Soltar cedo cancela sem erro")
	_button(true)
	_tick(0.91)
	_check(controller.phase == InteractionController.Phase.DONE, "Parafuso normal completo")
	_button(false)

	_new_pair()
	_double()
	_tap()
	_tick(0.10)
	_button(true)
	_tick(0.31)
	_check(events == ["double", "click"] and controller.phase == InteractionController.Phase.UNSCREW_HOLD, "Curto seguido de longo confirma preparo sem duplo")
	_tick(0.61)
	_check(controller.phase == InteractionController.Phase.WAIT_REPLACEMENT and errors.is_empty(), "Remocao completa mesmo segurando por mais que a janela")
	_button(false)
	controller.replacement_finished()
	_button(true)
	_tick(0.91)
	_check(controller.phase == InteractionController.Phase.DONE, "Instala sem selecionar novamente")
	_button(false)

	_new_pair()
	_double()
	_single()
	_tick(0.8)
	_check(controller.phase == InteractionController.Phase.ACT and errors.is_empty(), "Preparo expira sem morte")
	_single()
	_check(controller.phase == InteractionController.Phase.UNSCREW_HOLD, "Pode preparar novamente")
	_button(true)
	_tick(0.4)
	_button(false)
	_check(controller.phase == InteractionController.Phase.UNSCREW_HOLD and errors.is_empty(), "Soltar cedo preserva preparo")
	_button(true)
	_tick(0.91)
	_check(controller.phase == InteractionController.Phase.WAIT_REPLACEMENT, "Pode tentar segurar novamente")
	_button(false)

	_new_pair()
	_double()
	_button(true)
	_tick(0.91)
	_check(errors.size() == 1, "Longo sem preparo e erro")
	_button(false)
	_new_pair()
	_double()
	_double()
	_check(errors.size() == 1, "Duplo na remocao e erro")
	_new_pair(InteractionController.SlotKind.NAIL)
	_double()
	_check(errors.size() == 1, "Ferramenta errada e erro")
	_new_pair(InteractionController.SlotKind.NAIL)
	_single()
	_button(true)
	_tick(0.91)
	_check(errors.size() == 1, "Gesto errado e erro")
	_button(false)

	_new_pair(InteractionController.SlotKind.BAD_NAIL)
	_single()
	_double()
	controller.replacement_finished()
	_single()
	_check(controller.phase == InteractionController.Phase.DONE and errors.is_empty(), "Prego torto completo")

	_new_pair(InteractionController.SlotKind.NAIL)
	_tap()
	reader.set_enabled(false)
	_tick(1.0)
	reader.set_enabled(true)
	_tick(1.0)
	_check(events.is_empty(), "Bloqueio descarta clique pendente")
	reader.set_enabled(false)
	_button(true)
	_tick(1.0)
	reader.set_enabled(true)
	_tick(1.0)
	_button(false)
	_tick(0.3)
	_check(events.is_empty(), "Segurar durante automacao nao vaza gesto")
	_single()
	_check(events == ["click"], "Novo gesto apos soltar funciona")

	_new_pair(InteractionController.SlotKind.NAIL)
	reader.block_for(Config.TRAVA_POS_ACAO)
	_button(true)
	_tick(0.2)
	_button(false)
	_tick(0.3)
	_check(events.is_empty(), "Pressionar durante trava exige soltar")
	_single()
	_check(events == ["click"], "Input volta depois da trava")

	_new_pair(InteractionController.SlotKind.SCREW)
	controller.slot_completed.connect(func(): reader.reset())
	_double()
	_button(true)
	_tick(0.91)
	controller.set_slot(InteractionController.SlotKind.NAIL)
	_tick(1.0)
	_button(false)
	_tick(0.3)
	_check(controller.phase == InteractionController.Phase.SELECT_TOOL and errors.is_empty(), "Soltar acao anterior nao seleciona proximo slot")

	_new_pair(InteractionController.SlotKind.SCREW)
	_tap()
	_tick(0.279)
	_tap()
	_check(events == ["double"], "Segundo toque antes do limite e duplo")
	_new_pair(InteractionController.SlotKind.NAIL)
	_tap()
	_tick(0.281)
	_check(events == ["click"], "Clique confirmado depois do limite")
	_new_pair(InteractionController.SlotKind.NAIL)
	reader.mode = ClickReader.Mode.IMMEDIATE
	_tap()
	_check(events == ["click"], "Modo imediato nao espera janela")
	_new_pair()
	_double()
	_single()
	_button(true)
	_tick(0.4)
	_button(false)
	_tick(0.8)
	_check(controller.phase == InteractionController.Phase.ACT and errors.is_empty(), "Preparo interrompido expira sem erro")

	var rm := RunManager.new()
	add_child(rm)
	rm.set_process(false)
	rm.start_run()
	rm._process(3.0)
	_check(is_equal_approx(rm.time_left, Config.BARRA_INICIAL - 3.0), "Relogio drena continuamente")
	rm._process(0.5)
	_check(is_equal_approx(rm.time_left, Config.BARRA_INICIAL - 3.5), "Relogio volta a drenar")
	_check(is_equal_approx(TimeModel.t_min(TimeModel.SlotKind.RUSTY_SCREW), 3.35), "Modelo de tempo preservado")
	print("INPUT REGRESSION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
