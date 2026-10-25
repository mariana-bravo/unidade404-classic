
class_name Conveyor
extends Node2D

# Informa que um movimento terminou.
signal movement_finished

# Posições de entrada, montagem e saída.
const ENTRY_POSITION := Vector2(-140, 90)
const WORK_POSITION := Vector2(160, 90)
const EXIT_POSITION := Vector2(460, 90)

const SLOT_WIDTH := 36.0
const SLOT_HEIGHT := 28.0
const SLOT_GAP := 12.0

const COLOR_PENDING := Color("#3b4655")
const COLOR_ACTIVE := Color("#a7792a")
const COLOR_COMPLETED := Color("#28654c")

# Duração de cada movimento, em segundos.
@export var movement_duration: float = 1.0

# Ativa uma demonstração ao executar a cena isolada.
@export var demo_mode: bool = true

@onready var board: Node2D = $Board
@onready var slots_container: Node2D = $Board/Slots

var slot_visuals: Array[ColorRect] = []

var moving: bool = false


func _ready() -> void:
	board.position = ENTRY_POSITION

	if demo_mode:
		await enter_board()
		await get_tree().create_timer(1.0).timeout
		await exit_board()


# Faz uma peça entrar pela esquerda.
func enter_board() -> void:
	if moving:
		return

	moving = true
	board.position = ENTRY_POSITION

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(
		board,
		"position",
		WORK_POSITION,
		movement_duration
	)

	await tween.finished

	moving = false
	movement_finished.emit()


# Faz a peça sair pela direita.
func exit_board() -> void:
	if moving:
		return

	moving = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(
		board,
		"position",
		EXIT_POSITION,
		movement_duration
	)

	await tween.finished

	moving = false
	movement_finished.emit()


# Recebe a lista de tipos sorteados pelo BoardGenerator.
func set_slots(slot_types: Array[int]) -> void:
	# Remove os indicadores da peça anterior.
	for slot in slot_visuals:
		slot.queue_free()

	slot_visuals.clear()

	var quantity := slot_types.size()

	# Calcula a largura total ocupada pelos indicadores.
	var total_width := (
		quantity * SLOT_WIDTH
		+ (quantity - 1) * SLOT_GAP
	)

	# Centraliza o conjunto de indicadores na peça.
	var start_x := -total_width / 2.0

	for i in range(quantity):
		var slot := ColorRect.new()

		slot.name = "Slot" + str(i + 1)
		slot.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)

		slot.position = Vector2(
			start_x + i * (SLOT_WIDTH + SLOT_GAP),
			-SLOT_HEIGHT / 2.0
		)

		slot.color = COLOR_PENDING
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		slots_container.add_child(slot)
		slot_visuals.append(slot)

		# Adiciona o texto indicando o tipo do slot.
		var label := Label.new()

		label.text = _get_slot_name(slot_types[i])
		label.position = Vector2.ZERO
		label.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		slot.add_child(label)

	# Destaca o primeiro slot.
	update_slot_progress(0)


func _get_slot_name(slot_kind: int) -> String:
	match slot_kind:
		InteractionController.SlotKind.NAIL:
			return "PR"

		InteractionController.SlotKind.SCREW:
			return "PA"

		InteractionController.SlotKind.BAD_NAIL:
			return "P.T."

		InteractionController.SlotKind.RUSTY_SCREW:
			return "P.E."

	return "?"


func update_slot_progress(completed_count: int) -> void:
	for i in range(slot_visuals.size()):
		if i < completed_count:
			slot_visuals[i].color = COLOR_COMPLETED

		elif i == completed_count:
			slot_visuals[i].color = COLOR_ACTIVE

		else:
			slot_visuals[i].color = COLOR_PENDING
