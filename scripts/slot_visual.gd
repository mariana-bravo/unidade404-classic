class_name AssemblySlotVisual
extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
const NAIL_TEXTURE = preload("res://art/Parts/404_nail_sprite.tres")
const BENT_NAIL_TEXTURE = preload("res://art/Parts/404_bent_nail_sprite.tres")
const SCREW_TEXTURE = preload("res://art/Parts/404_screw_sprite.tres")
const RUSTY_SCREW_TEXTURE = preload("res://art/Parts/404_rusty_screw_sprite.tres")
var kind: int = 0
var completed: bool = false
var active: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_state(done: bool, selected: bool) -> void:
	completed = done
	active = selected
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	if active:
		# Pequeno marcador lateral, sem contorno em volta da peça.
		draw_colored_polygon(PackedVector2Array([Vector2(0, 4), Vector2(3, 6), Vector2(0, 8)]), U.UNIT)
	if completed:
		draw_line(center + Vector2(-3, 0), center + Vector2(-1, 2), U.UNIT, 2)
		draw_line(center + Vector2(-1, 2), center + Vector2(4, -3), U.UNIT, 2)
	elif kind == InteractionController.SlotKind.NAIL:
		_draw_part(NAIL_TEXTURE)
	elif kind == InteractionController.SlotKind.SCREW:
		_draw_part(SCREW_TEXTURE)
	elif kind == InteractionController.SlotKind.BAD_NAIL:
		_draw_part(BENT_NAIL_TEXTURE)
	elif kind == InteractionController.SlotKind.RUSTY_SCREW:
		_draw_part(RUSTY_SCREW_TEXTURE)


func _draw_part(texture: Texture2D) -> void:
	# A região do AtlasTexture exclui as margens transparentes dos PNGs originais.
	var available := Vector2(maxf(size.x - 4, 1), maxf(size.y - 2, 1))
	var dimensions := texture.get_size()
	var factor := minf(available.x / dimensions.x, available.y / dimensions.y)
	var target := (dimensions * factor).round()
	var position := Vector2(4, floorf((size.y - target.y) / 2.0))
	draw_texture_rect(texture, Rect2(position, target), false)
