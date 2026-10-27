
class_name Conveyor
extends Node2D
const U = preload("res://scripts/ui/industrial_ui.gd")
const BELT_SOURCE = preload("res://art/Conveyor Belt/404_belt.png")
const BELT_TILE_WIDTH := 32.0
const BELT_Y := 71.0
const BELT_HEIGHT := 33.0

# Informa que um movimento terminou.
signal movement_finished

# Posições de entrada, montagem e saída.
const ENTRY_POSITION := Vector2(-140, 88)
const WORK_POSITION := Vector2(160, 88)
const EXIT_POSITION := Vector2(460, 88)

const SLOT_WIDTH := 14.0
const SLOT_HEIGHT := 12.0
const SLOT_GAP := 2.0
const BOARD_SIZE := Vector2(34, 30)

# Duração de cada movimento, em segundos.
@export var movement_duration: float = 1.0

# Ativa uma demonstração ao executar a cena isolada.
@export var demo_mode: bool = true

@onready var board: Node2D = $Board
@onready var slots_container: Node2D = $Board/Slots

var slot_visuals: Array[AssemblySlotVisual] = []
var _belt_offset: float = 0.0
var _belt_tile: AtlasTexture

var moving: bool = false
var _movement_tween: Tween


func _ready() -> void:
	_belt_tile = AtlasTexture.new()
	_belt_tile.atlas = BELT_SOURCE
	_belt_tile.region = Rect2(0, BELT_Y, BELT_TILE_WIDTH, BELT_HEIGHT)
	board.position = ENTRY_POSITION
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color("5a6988")
	plate_style.border_color = Color("333941")
	plate_style.border_width_right = 2
	plate_style.border_width_bottom = 2
	$Board/BoardVisual.add_theme_stylebox_override("panel", plate_style)

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
	_movement_tween = tween
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
	_movement_tween = tween
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

	# Placa compacta: até duas colunas e duas linhas, na ordem de leitura.
	var visual: Panel = $Board/BoardVisual
	visual.position = -BOARD_SIZE / 2.0
	visual.size = BOARD_SIZE
	var rows := 1 if quantity <= 2 else 2
	var total_height := rows * SLOT_HEIGHT + (rows - 1) * SLOT_GAP

	for i in range(quantity):
		var slot := AssemblySlotVisual.new()
		slot.name = "Slot" + str(i + 1)
		slot.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
		var row := i / 2
		var columns := mini(2, quantity - row * 2)
		var row_width := columns * SLOT_WIDTH + (columns - 1) * SLOT_GAP
		slot.position = Vector2(-row_width / 2.0 + (i % 2) * (SLOT_WIDTH + SLOT_GAP), -total_height / 2.0 + row * (SLOT_HEIGHT + SLOT_GAP))
		slot.kind = slot_types[i]
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots_container.add_child(slot)
		slot_visuals.append(slot)

	# Destaca o primeiro slot.
	update_slot_progress(0)


func update_slot_progress(completed_count: int) -> void:
	for i in range(slot_visuals.size()):
		slot_visuals[i].set_state(i < completed_count, i == completed_count)

func get_board_width() -> float:
	return BOARD_SIZE.x

func _process(delta: float) -> void:
	if moving:
		var speed := (WORK_POSITION.x - ENTRY_POSITION.x) / maxf(movement_duration, 0.001)
		_belt_offset = fposmod(_belt_offset + delta * speed, BELT_TILE_WIDTH)
		queue_redraw()

func _draw() -> void:
	if _belt_tile == null:
		return
	# Repete só os 32x33 px úteis do PNG, sem editar o arquivo original.
	for i in range(-1, 11):
		draw_texture(_belt_tile, Vector2(i * BELT_TILE_WIDTH + floorf(_belt_offset), BELT_Y))


# Interrompe o movimento no game over e libera quem aguardava a animação.
func stop_movement() -> void:
	if is_instance_valid(_movement_tween) and _movement_tween.is_running():
		_movement_tween.kill()
		_movement_tween.finished.emit()
	moving = false


func pulse_slot(index: int) -> void:
	if index < 0 or index >= slot_visuals.size():
		return
	var slot := slot_visuals[index]
	slot.modulate = Color(1.3, 1.3, 1.3)
	var pulse := slot.create_tween()
	pulse.tween_property(slot, "modulate", Color.WHITE, 0.18)


# Atualiza apenas a aparência: o tipo original continua sendo usado na pontuação.
func show_replacement(index: int) -> void:
	if index < 0 or index >= slot_visuals.size():
		return
	var slot := slot_visuals[index]
	if slot.kind == InteractionController.SlotKind.BAD_NAIL:
		slot.kind = InteractionController.SlotKind.NAIL
	elif slot.kind == InteractionController.SlotKind.RUSTY_SCREW:
		slot.kind = InteractionController.SlotKind.SCREW
	slot.queue_redraw()
