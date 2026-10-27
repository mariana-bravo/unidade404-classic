
class_name Conveyor
extends Node2D
const U = preload("res://scripts/ui/industrial_ui.gd")

# Informa que um movimento terminou.
signal movement_finished

# Posições de entrada, montagem e saída.
const ENTRY_POSITION := Vector2(-140, 112)
const WORK_POSITION := Vector2(160, 112)
const EXIT_POSITION := Vector2(460, 112)

const SLOT_WIDTH := 44.0
const SLOT_HEIGHT := 26.0
const SLOT_GAP := 8.0

# Duração de cada movimento, em segundos.
@export var movement_duration: float = 1.0

# Ativa uma demonstração ao executar a cena isolada.
@export var demo_mode: bool = true

@onready var board: Node2D = $Board
@onready var slots_container: Node2D = $Board/Slots

var slot_visuals: Array[AssemblySlotVisual] = []
var _belt_offset: float = 0.0

var moving: bool = false
var _movement_tween: Tween


func _ready() -> void:
	board.position = ENTRY_POSITION
	$Board/BoardVisual.add_theme_stylebox_override("panel", U.panel_style())

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

	# Calcula a largura total ocupada pelos indicadores.
	var total_width := (
		quantity * SLOT_WIDTH
		+ (quantity - 1) * SLOT_GAP
	)

	# Centraliza o conjunto de indicadores na peça.
	var start_x := -total_width / 2.0

	for i in range(quantity):
		var slot := AssemblySlotVisual.new()
		slot.name = "Slot" + str(i + 1)
		slot.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
		slot.position = Vector2(start_x + i * (SLOT_WIDTH + SLOT_GAP), -SLOT_HEIGHT / 2.0)
		slot.kind = slot_types[i]
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots_container.add_child(slot)
		slot_visuals.append(slot)

	# Destaca o primeiro slot.
	update_slot_progress(0)


func update_slot_progress(completed_count: int) -> void:
	for i in range(slot_visuals.size()):
		slot_visuals[i].set_state(i < completed_count, i == completed_count)

func _process(delta: float) -> void:
	if moving:
		_belt_offset = fmod(_belt_offset + delta * 32, 16)
		queue_redraw()

func _draw() -> void:
	for y in [84, 137]:
		draw_line(Vector2(12, y), Vector2(308, y), U.LINE)
		for i in range(19):
			var x := 12 + posmod(i * 16 + int(_belt_offset), 296)
			draw_rect(Rect2(x, y + 2, 6, 2), U.LINE)


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
