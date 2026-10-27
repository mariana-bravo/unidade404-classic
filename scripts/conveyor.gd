
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

const LEFT_EDGE = preload("res://art/Parts/404_left.png")
const RIGHT_EDGE = preload("res://art/Parts/404_right.png")
const SPACER = preload("res://art/Parts/404_space.png")
const SLOT_HEIGHT := 20.0
const SLOT_GAP := 2.0
var board_width: float = 0.0

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
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Board/BoardVisual.hide()

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
	# Bordas, espaçadores e slots formam uma única caixa horizontal.
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()
	slot_visuals.clear()
	board_width = LEFT_EDGE.get_width() + RIGHT_EDGE.get_width()
	for kind in slot_types:
		board_width += AssemblySlotVisual.module_width(kind)
	board_width += maxi(0, slot_types.size() - 1) * SLOT_GAP
	var x := -floorf(board_width / 2.0)
	_add_board_module(LEFT_EDGE, x)
	x += LEFT_EDGE.get_width()
	for i in range(slot_types.size()):
		var slot := AssemblySlotVisual.new()
		slot.name = "Slot" + str(i + 1)
		slot.kind = slot_types[i]
		slot.size = Vector2(AssemblySlotVisual.module_width(slot.kind), SLOT_HEIGHT)
		slot.position = Vector2(x, -SLOT_HEIGHT / 2.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots_container.add_child(slot)
		slot_visuals.append(slot)
		x += slot.size.x
		if i < slot_types.size() - 1:
			_add_board_module(SPACER, x)
			x += SLOT_GAP
	_add_board_module(RIGHT_EDGE, x)
	update_slot_progress(0)


func _add_board_module(texture: Texture2D, x: float) -> void:
	var module := Sprite2D.new()
	module.texture = texture
	module.centered = false
	module.position = Vector2(x, -SLOT_HEIGHT / 2.0)
	slots_container.add_child(module)

func update_slot_progress(completed_count: int) -> void:
	for i in range(slot_visuals.size()):
		slot_visuals[i].set_state(i < completed_count, i == completed_count)

func get_board_width() -> float:
	return board_width

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
	slot_visuals[index].empty = false
	slot_visuals[index].replaced = true
	slot_visuals[index].queue_redraw()


func show_empty(index: int) -> void:
	if index < 0 or index >= slot_visuals.size():
		return
	slot_visuals[index].empty = true
	slot_visuals[index].queue_redraw()


# Centro do slot em coordenadas globais, para a entrega pelo braço auxiliar.
func get_slot_position(index: int) -> Vector2:
	var slot := slot_visuals[index]
	return slot.get_global_transform() * (slot.size / 2.0)
