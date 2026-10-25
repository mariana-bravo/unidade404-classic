
extends Node2D

# Referências aos nós da cena.
@onready var click_reader: ClickReader = $ClickReader
@onready var controller: InteractionController = $InteractionController

# Referências aos elementos da interface.
@onready var slot_label: Label = $SlotLabel
@onready var tool_label: Label = $ToolLabel
@onready var phase_label: Label = $PhaseLabel
@onready var feedback_label: Label = $FeedbackLabel

# Sequência provisória de slots.
const SLOTS = [
	InteractionController.SlotKind.NAIL,
	InteractionController.SlotKind.SCREW,
	InteractionController.SlotKind.BAD_NAIL,
	InteractionController.SlotKind.RUSTY_SCREW
]

const SLOT_NAMES = [
	"PREGO",
	"PARAFUSO",
	"PREGO TORTO",
    "PARAFUSO ENFERRUJADO"
]

var current_slot: int = 0
var score: int = 0
var replacing: bool = false


func _ready() -> void:
	# O jogo utiliza reconhecimento de duplo clique.
	click_reader.mode = ClickReader.Mode.WINDOWED
	click_reader.hold_completion_time = Config.TEMPO_APARAFUSAR

	# Conecta os eventos do mouse ao controlador.
	click_reader.click.connect(controller.gesture_click)
	click_reader.double_click.connect(controller.gesture_double_click)
	click_reader.hold_completed.connect(controller.gesture_hold)

	# Conecta os eventos do controlador ao jogo.
	controller.tool_selected.connect(_on_tool_selected)
	controller.step_completed.connect(_on_step_completed)
	controller.slot_completed.connect(_on_slot_completed)
	controller.replacement_requested.connect(_on_replacement_requested)
	controller.wrong_action.connect(_on_wrong_action)

	start_slot()


# Inicia o slot atual.
func start_slot() -> void:
	replacing = false
	click_reader.reset()

	controller.set_slot(SLOTS[current_slot])

	feedback_label.text = "SELECIONE A FERRAMENTA"

	update_interface()


# Atualiza os textos da tela.
func update_interface() -> void:
	slot_label.text = "SLOT %d/4 - %s" % [
		current_slot + 1,
		SLOT_NAMES[current_slot]
	]

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
	current_slot += 1

	if current_slot >= SLOTS.size():
		current_slot = 0
		score += 50
		print("PECA CONCLUIDA! PONTUACAO: ", score)

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
	controller.set_slot(SLOTS[current_slot])
	update_interface()
