
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
@onready var time_label: Label = $TimeLabel

var current_board: Array[int] = []


const SLOT_NAMES = [
	"PREGO",
	"PARAFUSO",
	"PREGO TORTO",
    "PARAFUSO ENFERRUJADO"
]

var current_slot: int = 0
var score: int = 0
var replacing: bool = false
var board_transitioning: bool = true

func _ready() -> void:
	# O jogo utiliza reconhecimento de duplo clique.
	click_reader.mode = ClickReader.Mode.WINDOWED
	click_reader.hold_completion_time = Config.TEMPO_APARAFUSAR

	# Conecta os eventos do mouse ao controlador.
	click_reader.click.connect(_on_click)
	click_reader.double_click.connect(_on_double_click)
	click_reader.hold_completed.connect(_on_hold)

	# Conecta os eventos do controlador ao jogo.
	controller.tool_selected.connect(_on_tool_selected)
	controller.step_completed.connect(_on_step_completed)
	controller.slot_completed.connect(_on_slot_completed)
	controller.replacement_requested.connect(_on_replacement_requested)
	controller.wrong_action.connect(_on_wrong_action)
	controller.phase_changed.connect(update_interface)
	
	run_manager.time_changed.connect(_on_time_changed)
	run_manager.time_expired.connect(_on_time_expired)
	run_manager.run_finished.connect(_on_run_finished)

	run_manager.start_run()
	run_manager.set_paused(true)

	generate_new_board()
	await conveyor.enter_board()

	start_slot()
	board_transitioning = false
	
	run_manager.score_changed.connect(func(points: int): print("PONTUACAO: ", points))
	run_manager.level_changed.connect(func(new_level: int): print("NIVEL: ", new_level))
	run_manager.time_changed.connect(func(seconds: float): pass)
	
	run_manager.set_paused(false)
	
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
	
	# Concede pontos e recupera tempo.
	run_manager.on_slot_completed(completed_kind)
	
	# Marca o slot concluído visualmente.
	conveyor.update_slot_progress(current_slot + 1)

	current_slot += 1

	# Se ainda existem slots, continua na mesma peça.
	if current_slot < current_board.size():
		start_slot()
		return
		
	# Todos os slots da peça foram concluídos.
	run_manager.on_piece_completed()

	# Todos os slots foram concluídos.
	board_transitioning = true
	run_manager.set_paused(true)

	feedback_label.text = "PECA CONCLUIDA!"

	# A peça pronta sai.
	await conveyor.exit_board()

	# Gera a próxima peça.
	generate_new_board()

	# A nova peça entra.
	await conveyor.enter_board()

	click_reader.reset()
	board_transitioning = false
	run_manager.set_paused(false)

	start_slot()

# Um slot defeituoso precisa de outra peça.
func _on_replacement_requested() -> void:
	replacing = true
	run_manager.set_paused(true)

	feedback_label.text = "AGUARDE A NOVA PECA..."
	update_interface()

	await get_tree().create_timer(1.0).timeout

	if not run_manager.running:
		return

	controller.replacement_finished()
	replacing = false

	feedback_label.text = "NOVA PECA INSTALADA!"
	update_interface()

	run_manager.set_paused(false)

# O jogador realizou uma ação incorreta.
func _on_wrong_action(reason: String) -> void:
	print("[DEBUG] Acao incorreta: ", reason)
	run_manager.finish_run(RunManager.MOTIVO_ACAO_INCORRETA)

func _on_click() -> void:
	if board_transitioning or not run_manager.running:
		return

	controller.gesture_click()


func _on_double_click() -> void:
	if board_transitioning or not run_manager.running:
		return

	controller.gesture_double_click()


func _on_hold() -> void:
	if board_transitioning or not run_manager.running:
		return

	controller.gesture_hold()


# Atualiza o contador na tela.
func _on_time_changed(seconds: float) -> void:
	time_label.text = "TEMPO: %.2fs" % seconds

	# Altera a cor quando o tempo está baixo.
	if seconds <= 2.5:
		time_label.add_theme_color_override(
			"font_color",
			Color.RED
		)
	else:
		time_label.add_theme_color_override(
			"font_color",
			Color.WHITE
		)


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
	click_reader.reset()

	feedback_label.text = "GAME OVER!"

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
