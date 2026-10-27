class_name AssemblySlotVisual
extends Control
const U = preload("res://scripts/ui/industrial_ui.gd")
const MODULE_BASE = preload("res://art/Parts/404_space.png")
const TEXTURES = {
	"wait_nail": preload("res://art/Parts/404_wait_nail.png"),
	"wait_screw": preload("res://art/Parts/404_wait_screw.png"),
	"bad_nail": preload("res://art/Parts/404_bad_nail.png"),
	"bad_screw": preload("res://art/Parts/404_bad_screw.png"),
	"empty_nail": preload("res://art/Parts/404_emply_nail.png"),
	"empty_screw": preload("res://art/Parts/404_emply_screw.png"),
	"complete_nail": preload("res://art/Parts/404_complit_nail.png"),
	"complete_screw": preload("res://art/Parts/404_complet_screw.png"),
}
var kind: int = 0
var completed: bool = false
var active: bool = false
var empty: bool = false
var replaced: bool = false
static func module_width(slot_kind: int) -> float:
	return 7.0 if slot_kind == InteractionController.SlotKind.SCREW or slot_kind == InteractionController.SlotKind.RUSTY_SCREW else 6.0
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func set_state(done: bool, selected: bool) -> void:
	completed = done
	active = selected
	queue_redraw()
func _draw() -> void:
	var screw := kind == InteractionController.SlotKind.SCREW or kind == InteractionController.SlotKind.RUSTY_SCREW
	var state := "wait"
	if completed:
		state = "complete"
	elif empty:
		state = "empty"
	elif not replaced and (kind == InteractionController.SlotKind.BAD_NAIL or kind == InteractionController.SlotKind.RUSTY_SCREW):
		state = "bad"
	var texture: Texture2D = TEXTURES[state + ("_screw" if screw else "_nail")]
	draw_texture_rect(MODULE_BASE, Rect2(Vector2.ZERO, size), true)
	draw_texture(texture, Vector2(floorf((size.x - texture.get_width()) / 2.0), 0))
	if active:
		var center := floorf(size.x / 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(center - 2, -5), Vector2(center + 2, -5), Vector2(center, -2)]), U.UNIT)
