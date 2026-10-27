
extends Node2D

# Referências aos nós da cena.
@onready var conveyor: Conveyor = $Conveyor
@onready var click_reader: ClickReader = $ClickReader
@onready var controller: InteractionController = $InteractionController
@onready var board_generator: BoardGenerator = $BoardGenerator
@onready var run_manager: RunManager = $RunManager

# Referências aos elementos da interface.
@onready var tool_label: Label = $ToolLabel
@onready var phase_label: Label = $PhaseLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var input_feedback: GameFeedback = $InputFeedback
@onready var hud: VisorHud = $VisorHud
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

var current_board: Array[int] = []
var current_slot: int = 0
var replacing: bool = false
var board_transitioning: bool = true

func _ready() -> void:
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# Também funciona ao executar esta cena diretamente no editor.
	if GameState.robot_name.is_empty():
		GameState.new_robot()
	GameState.robot_changed.connect(_on_robot_changed)
	_on_robot_changed(GameState.robot_name, GameState.robot_gender, GameState.serial, GameState.color_index)
	hud.set_best(ScoreboardData.get_best_score())
	ScoreboardData.changed.connect(_on_scoreboard_changed)
	# O jogo utiliza reconhecimento de duplo clique.
	click_reader.set_enabled(false)
	click_reader.mode = ClickReader.Mode.WINDOWED
	click_reader.hold_completion_time = Config.TEMPO_APARAFUSAR

	# Conecta os eventos do mouse ao controlador.
	click_reader.click.connect(_on_click)
	click_reader.double_click.connect(_on_double_click)
	click_reader.hold_completed.connect(_on_hold)
	click_reader.press_started.connect(controller.begin_press)
	click_reader.hold_started.connect(controller.begin_press)
	click_reader.press_released.connect(controller.end_press)

	# Conecta os eventos do controlador ao jogo.
	controller.tool_selected.connect(_on_tool_selected)
	controller.step_completed.connect(_on_step_completed)
	controller.slot_completed.connect(_on_slot_completed)
	controller.replacement_requested.connect(_on_replacement_requested)
	controller.wrong_action.connect(_on_wrong_action)
	controller.phase_changed.connect(update_interface)

	run_manager.time_changed.connect(hud.set_time)
	run_manager.score_changed.connect(hud.set_score)
	run_manager.level_changed.connect(hud.set_level)
	run_manager.time_expired.connect(_on_time_expired)
	run_manager.run_finished.connect(_on_run_finished)

	input_feedback.bind_input(click_reader, controller, run_manager)
	run_manager.start_run()

	generate_new_board()
	await conveyor.enter_board()
	if not run_manager.running:
		return

	start_slot()
	board_transitioning = false

	click_reader.set_enabled(true)

func generate_new_board() -> void:

	current_board = board_generator.generate_board(run_manager.level)
	current_slot = 0
	conveyor.set_slots(current_board)
	print(
		"Nível: ", run_manager.level,
		" | Peças concluídas: ", run_manager.pieces_done,
		" | Slots: ", current_board.size(),
		" | Tipos: ", current_board
	)

# Inicia o slot atual.
func start_slot() -> void:
	replacing = false
	click_reader.reset()

	controller.set_slot(current_board[current_slot])
	conveyor.update_slot_progress(current_slot)
	feedback_label.text = "SELECIONE A FERRAMENTA"

	update_interface()

# Atualiza os textos da tela.
func update_interface() -> void:
	match controller.tool:
		InteractionController.Tool.NONE:
			tool_label.text = "FERRAMENTA: NENHUMA"

		InteractionController.Tool.HAMMER:
			tool_label.text = "FERRAMENTA: MARTELO"

		InteractionController.Tool.SCREWDRIVER:
			tool_label.text = "FERRAMENTA: CHAVE"

	match controller.phase:
		InteractionController.Phase.SELECT_TOOL:
			phase_label.text = "FASE: SELECIONAR"

		InteractionController.Phase.ACT:
			phase_label.text = "FASE: EXECUTAR ACAO"

		InteractionController.Phase.UNSCREW_HOLD:
			phase_label.text = "FASE: SEGURE PARA REMOVER"

		InteractionController.Phase.WAIT_REPLACEMENT:
			phase_label.text = "FASE: SUBSTITUINDO"

		InteractionController.Phase.ACT_NO_SELECT:
			phase_label.text = "FASE: INSTALAR NOVA PECA"

		InteractionController.Phase.DONE:
			phase_label.text = "FASE: CONCLUIDO"


# O jogador escolheu a ferramenta certa.
func _on_tool_selected(_tool: int) -> void:
	feedback_label.text = "FERRAMENTA CORRETA!"
	update_interface()


# Uma etapa da ação foi realizada.
func _on_step_completed() -> void:
	feedback_label.text = "ACAO CORRETA!"
	update_interface()


# O slot foi concluído.


func _on_slot_completed() -> void:
	if not run_manager.running:
		return

	# O slot atual terminou completamente.
	var completed_kind: int = current_board[current_slot]

	input_feedback.complete_slot(current_slot == current_board.size() - 1)
	conveyor.pulse_slot(current_slot)

	# Concede pontos e recupera tempo.
	var tempo_esteira := 2.0 * conveyor.movement_duration if current_slot == current_board.size() - 1 else 0.0
	run_manager.on_slot_completed(completed_kind, tempo_esteira)

	# Marca o slot concluído visualmente.
	conveyor.update_slot_progress(current_slot + 1)

	current_slot += 1

	# Se ainda existem slots, continua na mesma peça.
	if current_slot < current_board.size():
		start_slot()
		click_reader.block_for(Config.TRAVA_POS_ACAO)
		return

	# Todos os slots da peça foram concluídos.
	run_manager.on_piece_completed()

	# Todos os slots foram concluídos.
	board_transitioning = true
	click_reader.set_enabled(false)

	feedback_label.text = "PECA CONCLUIDA!"

	# A peça pronta sai.
	await conveyor.exit_board()
	if not run_manager.running:
		return

	# Gera a próxima peça.
	generate_new_board()

	# A nova peça entra.
	await conveyor.enter_board()
	if not run_manager.running:
		return

	click_reader.reset()
	board_transitioning = false
	click_reader.set_enabled(true)

	start_slot()

# Um slot defeituoso precisa de outra peça.
func _on_replacement_requested() -> void:
	replacing = true
	click_reader.set_enabled(false)

	feedback_label.text = "AGUARDE A NOVA PECA..."
	update_interface()

	await get_tree().create_timer(Config.TEMPO_SUBSTITUICAO).timeout

	if not run_manager.running:
		return

	controller.replacement_finished()
	replacing = false

	feedback_label.text = "NOVA PECA INSTALADA!"
	update_interface()

	click_reader.set_enabled(true)

# O jogador realizou uma ação incorreta.
func _on_wrong_action(reason: String) -> void:
	print("[DEBUG] Acao incorreta: ", reason)
	run_manager.finish_run(RunManager.MOTIVO_ACAO_INCORRETA)

func _on_click() -> void:
	if board_transitioning or replacing or not run_manager.running:
		return

	controller.gesture_click()


func _on_double_click() -> void:
	if board_transitioning or replacing or not run_manager.running:
		return

	controller.gesture_double_click()


func _on_hold() -> void:
	if board_transitioning or replacing or not run_manager.running:
		return

	controller.gesture_hold()


func _on_scoreboard_changed() -> void:
	hud.set_best(ScoreboardData.get_best_score())

func _exit_tree() -> void:
	Input.mouse_mode = _previous_mouse_mode

func _on_robot_changed(robot_name: String, _gender: String, serial: int, color_index: int) -> void:
	hud.set_robot(robot_name, serial)
	hud.set_tint(Config.PALETA[color_index])


# Chamado quando o tempo acaba.
func _on_time_expired() -> void:
	print("[DEBUG] O TEMPO ESGOTOU!")


# Chamado quando a partida termina.
func _on_run_finished(
	reason: String,
	final_score: int,
	total_life_time: float
) -> void:
	# Bloqueia novas interações.
	board_transitioning = true
	click_reader.set_enabled(false)

	conveyor.stop_movement()
	var ranked := false
	if not run_manager.training:
		ranked = ScoreboardData.submit_run(GameState.robot_name, final_score, total_life_time)
	feedback_label.text = "ENTROU NO PLACAR!" if ranked else "GAME OVER!"

	# Informações de depuração.
	print("================================")
	print("[DEBUG] GAME OVER")
	print("[DEBUG] Motivo: ", reason)
	print("[DEBUG] Pontuacao: ", final_score)
	print("[DEBUG] Tempo de vida: %.2fs" % total_life_time)
	print("================================")

	# Mostra a mensagem antes de retornar ao menu.
	await get_tree().create_timer(2.0).timeout

	# Retorna ao menu principal.
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
