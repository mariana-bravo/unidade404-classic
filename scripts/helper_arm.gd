
class_name HelperArm
extends Node2D

## Avisa quando a substituição visual terminou.
## Signals when the visual replacement has finished.
signal replacement_finished

const U = preload("res://scripts/ui/industrial_ui.gd")

# Tempos e posições ajustáveis no Inspector.
# Timings and positions configurable in the Inspector.
@export var travel_duration: float = 0.55
@export var placement_pause: float = 0.45
@export var entry_position: Vector2 = Vector2(160.0, -42.0)
@export var work_position: Vector2 = Vector2(160.0, 96.0)

var _busy: bool = false
var _carrying_part: bool = false
var _replacement_kind: int = InteractionController.SlotKind.NAIL


func _ready() -> void:
	# O braço começa fora da tela.
	# Start the arm off-screen.
	position = entry_position
	visible = false


## Anima a substituição de uma peça.
## Animates the replacement of a part.
##
## Recebe o tipo antigo ou o novo; visualmente, sempre coloca
## um prego ou parafuso em boas condições.
## Accepts the old or new kind; visually places a clean nail or screw.
func replace_part(requested_kind: int = InteractionController.SlotKind.NAIL) -> void:
	if _busy:
		return

	_busy = true

	if (
		requested_kind == InteractionController.SlotKind.SCREW
		or requested_kind == InteractionController.SlotKind.RUSTY_SCREW
	):
		_replacement_kind = InteractionController.SlotKind.SCREW
	else:
		_replacement_kind = InteractionController.SlotKind.NAIL

	_carrying_part = true
	position = entry_position
	visible = true
	queue_redraw()

	# O braço desce com a peça de reposição.
	# The arm descends while carrying the replacement part.
	await _move_to(work_position, true)

	# Simula o momento em que a peça é colocada no slot.
	# Simulates placing the part into the slot.
	await get_tree().create_timer(placement_pause).timeout

	_carrying_part = false
	queue_redraw()

	# Pequena pausa antes de retirar o braço.
	# Brief pause before withdrawing the arm.
	await get_tree().create_timer(0.12).timeout

	# O braço volta para fora da tela.
	# The arm withdraws off-screen.
	await _move_to(entry_position, false)

	visible = false
	_busy = false

	# O jogo pode continuar a partir deste sinal.
	# Gameplay can continue after this signal.
	replacement_finished.emit()


# Move o braço com uma transição suave.
# Moves the arm with a smooth transition.
func _move_to(target: Vector2, entering: bool) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT if entering else Tween.EASE_IN)
	tween.tween_property(self, "position", target, travel_duration)
	await tween.finished


# Desenha uma versão provisória em estilo industrial.
# Draws a temporary industrial-style version.
func _draw() -> void:
	# Trilho vertical que vem de cima da tela.
	# Vertical rail extending from above the screen.
	draw_line(
		Vector2(0, -160),
		Vector2(0, -50),
		U.LINE,
		10.0
	)
	draw_line(
		Vector2(0, -160),
		Vector2(0, -50),
		U.MUTED,
		2.0
	)

	# Junta mecânica.
	# Mechanical joint.
	var joint := Rect2(Vector2(-14, -56), Vector2(28, 18))
	draw_rect(joint, U.PANEL)
	draw_rect(joint, U.AMBER, false, 1.0)

	# Antebraço e pinça.
	# Forearm and gripper.
	draw_line(Vector2(0, -38), Vector2(0, -8), U.LINE, 7.0)
	draw_line(Vector2(0, -38), Vector2(0, -8), U.MUTED, 2.0)
	draw_line(Vector2(-10, -8), Vector2(10, -8), U.AMBER, 3.0)
	draw_line(Vector2(-8, -8), Vector2(-8, 10), U.LINE, 3.0)
	draw_line(Vector2(8, -8), Vector2(8, 10), U.LINE, 3.0)

	# Desenha a peça que está sendo transportada.
	# Draws the part being carried.
	if not _carrying_part:
		return

	if _replacement_kind == InteractionController.SlotKind.NAIL:
		# Prego novo: haste e cabeça.
		# New nail: shaft and head.
		draw_line(Vector2(0, 12), Vector2(0, 21), U.MUTED, 2.0)
		draw_line(Vector2(-5, 12), Vector2(5, 12), U.AMBER, 2.0)
	else:
		# Parafuso novo: cabeça circular e fenda.
		# New screw: circular head and slot.
		draw_circle(Vector2(0, 16), 4.0, U.MUTED, false, 2.0)
		draw_line(Vector2(-3, 16), Vector2(3, 16), U.AMBER, 2.0)
