class_name AssemblySlotVisual
extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
var kind: int = 0
var completed: bool = false
var active: bool = false

func set_state(done: bool, selected: bool) -> void:
	completed = done
	active = selected
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), U.PANEL if completed else U.BG)
	draw_rect(Rect2(Vector2.ZERO, size), U.AMBER if active else U.LINE, false)
	var center := size / 2.0
	var color := U.AMBER if active else U.MUTED
	if completed:
		draw_line(center + Vector2(-5, 0), center + Vector2(-1, 4), U.UNIT, 2)
		draw_line(center + Vector2(-1, 4), center + Vector2(6, -4), U.UNIT, 2)
	elif kind == InteractionController.SlotKind.NAIL:
		draw_line(center + Vector2(0, 7), center - Vector2(0, 6), color, 2)
		draw_line(center - Vector2(6, 6), center + Vector2(6, -6), color, 2)
	elif kind == InteractionController.SlotKind.BAD_NAIL:
		draw_line(center + Vector2(4, 7), center - Vector2(2, 6), color, 2)
		draw_line(center - Vector2(7, 6), center + Vector2(3, -6), color, 2)
	else:
		draw_circle(center, 6, color, false, 1)
		draw_line(center - Vector2(4, 3), center + Vector2(4, 3), color, 2)
		if kind == InteractionController.SlotKind.RUSTY_SCREW:
			draw_rect(Rect2(center + Vector2(-8, -8), Vector2(2, 2)), U.AMBER)
			draw_rect(Rect2(center + Vector2(6, 5), Vector2(2, 2)), U.AMBER)
