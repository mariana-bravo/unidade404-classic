class_name AssemblySlotVisual
extends Control
const FOCUS_FRAMES = [preload("res://art/HUD/404_arrow1.png"), preload("res://art/HUD/404_arrow2.png")]
const FOCUS_SHADER = preload("res://scripts/ui/visor_tint.gdshader")
var _focus: AnimatedSprite2D
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
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 4.0)
	frames.set_animation_loop("default", true)
	for texture in FOCUS_FRAMES:
		frames.add_frame("default", texture)
	_focus = AnimatedSprite2D.new()
	_focus.sprite_frames = frames
	_focus.centered = false
	_focus.position = ((size - FOCUS_FRAMES[0].get_size()) / 2.0).floor()
	var focus_material := ShaderMaterial.new()
	focus_material.shader = FOCUS_SHADER
	focus_material.set_shader_parameter("visor_color", Config.PALETA[GameState.color_index])
	_focus.material = focus_material
	add_child(_focus)
	_sync_focus()
func set_state(done: bool, selected: bool) -> void:
	completed = done
	active = selected
	_sync_focus()
	queue_redraw()
func _sync_focus() -> void:
	if _focus == null:
		return
	_focus.visible = active and not completed
	if _focus.visible:
		if not _focus.is_playing():
			_focus.frame = 0
			_focus.play()
	else:
		_focus.stop()

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
