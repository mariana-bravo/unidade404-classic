
extends Node2D

# Referências aos nós da cena.
@onready var conveyor: Conveyor = $Conveyor
@onready var click_reader: ClickReader = $ClickReader
@onready var controller: InteractionController = $InteractionController
@onready var board_generator: BoardGenerator = $BoardGenerator

# Referências aos elementos da interface.
@onready var tool_label: Label = $ToolLabel
@onready var phase_label: Label = $PhaseLabel
@onready var feedback_label: Label = $FeedbackLabel

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

	generate_new_board()
	await conveyor.enter_board()

	start_slot()
	board_transitioning = false

func generate_new_board() -> void:
	var level: int = GameState.level

	current_board = board_generator.generate_board(level)
	current_slot = 0
	conveyor.set_slots(current_board)
	print(
		"Nível: ", level,
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
	score += 10

	# Marca o slot concluído visualmente.
	conveyor.update_slot_progress(current_slot + 1)

	current_slot += 1

	# Se ainda existem slots, continua na mesma peça.
	if current_slot < current_board.size():
		start_slot()
		return

	# Todos os slots foram concluídos.
	score += 50
	board_transitioning = true

	feedback_label.text = "PECA CONCLUIDA!"

	# A peça pronta sai.
	await conveyor.exit_board()

	# Progressão provisória até a integração com o Dev 3.
	GameState.level += 1

	# Gera a próxima peça.
	generate_new_board()

	# A nova peça entra.
	await conveyor.enter_board()

	click_reader.reset()
	board_transitioning = false

	start_slot()

# Um slot defeituoso precisa de outra peça.
func _on_replacement_requested() -> void:
	replacing = true
	feedback_label.text = "AGUARDE A NOVA PECA..."
	update_interface()

	# Simula o braço auxiliar.
	await get_tree().create_timer(1.0).timeout

	controller.replacement_finished()
	replacing = false

	feedback_label.text = "NOVA PECA INSTALADA!"
	update_interface()


# O jogador realizou uma ação incorreta.
func _on_wrong_action(reason: String) -> void:
	print("ERRO: ", reason)

	feedback_label.text = reason
	click_reader.reset()

	# No protótipo, o erro reinicia o mesmo slot.
	controller.set_slot(current_board[current_slot])
	update_interface()

func _on_click() -> void:
	if board_transitioning:
		return

	controller.gesture_click()


func _on_double_click() -> void:
	if board_transitioning:
		return

	controller.gesture_double_click()


func _on_hold() -> void:
	if board_transitioning:
		return

	controller.gesture_hold()
