class_name HelperArm
extends Node2D

## Entrega visual da peça e fim de toda a animação são eventos separados.
signal part_placed
signal replacement_finished

const U = preload("res://scripts/ui/industrial_ui.gd")
const NAIL_PART = preload("res://art/Parts/404_wait_nail.png")
const SCREW_PART = preload("res://art/Parts/404_wait_screw.png")
# Os PNGs incluem o módulo metálico. Remove apenas o cinza da placa na pinça.
const CARRIED_PART_SHADER := """shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (distance(pixel.rgb, vec3(109.0, 117.0, 141.0) / 255.0) < 0.005) {
		discard;
	}
	COLOR = pixel;
}
"""
var _part_sprite: Sprite2D
@export var travel_duration: float = 0.55
@export var placement_pause: float = 0.45
@export var entry_position: Vector2 = Vector2(160.0, -42.0)
@export var work_position: Vector2 = Vector2(160.0, 96.0)

var _busy: bool = false
var _carrying_part: bool = false
var _replacement_kind: int = InteractionController.SlotKind.NAIL
var _operation: int = 0
var _movement_tween: Tween

func _ready() -> void:
	_part_sprite = Sprite2D.new()
	_part_sprite.centered = false
	_part_sprite.visible = false
	var shader := Shader.new()
	shader.code = CARRIED_PART_SHADER
	var part_material := ShaderMaterial.new()
	part_material.shader = shader
	_part_sprite.material = part_material
	add_child(_part_sprite)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = entry_position
	visible = false

## O alvo opcional é global. Sem alvo, usa as posições configuradas no Inspector.
func replace_part(requested_kind: int = InteractionController.SlotKind.NAIL, target: Vector2 = Vector2.INF) -> void:
	if _busy:
		return
	_busy = true
	_operation += 1
	var operation := _operation
	_replacement_kind = InteractionController.SlotKind.SCREW if requested_kind == InteractionController.SlotKind.SCREW or requested_kind == InteractionController.SlotKind.RUSTY_SCREW else InteractionController.SlotKind.NAIL
	var destination := work_position
	var entry := entry_position
	if target != Vector2.INF:
		var head_offset := 12.0 if _replacement_kind == InteractionController.SlotKind.NAIL else 16.0
		destination = get_parent().to_local(target) - Vector2(0, head_offset)
		entry.x = destination.x
	_carrying_part = true
	var screw := _replacement_kind == InteractionController.SlotKind.SCREW
	var region := Rect2(0, 4, 7, 9) if screw else Rect2(0, 5, 6, 8)
	var texture := AtlasTexture.new()
	texture.atlas = SCREW_PART if screw else NAIL_PART
	texture.region = region
	texture.filter_clip = true
	_part_sprite.texture = texture
	var center_y := 16.0 if screw else 12.0
	_part_sprite.position = Vector2(-region.size.x / 2.0, center_y - region.size.y / 2.0)
	_part_sprite.visible = true
	position = entry
	visible = true
	queue_redraw()
	await _move_to(destination, true)
	if operation != _operation:
		return
	await get_tree().create_timer(placement_pause).timeout
	if operation != _operation:
		return
	_carrying_part = false
	_part_sprite.visible = false
	queue_redraw()
	part_placed.emit()
	await get_tree().create_timer(0.12).timeout
	if operation != _operation:
		return
	await _move_to(entry, false)
	if operation != _operation:
		return
	visible = false
	_busy = false
	replacement_finished.emit()

func _move_to(target: Vector2, entering: bool) -> void:
	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_SINE)
	_movement_tween.set_ease(Tween.EASE_OUT if entering else Tween.EASE_IN)
	_movement_tween.tween_property(self, "position", target, travel_duration)
	await _movement_tween.finished

func cancel() -> void:
	_operation += 1
	_busy = false
	_carrying_part = false
	_part_sprite.visible = false
	visible = false
	if is_instance_valid(_movement_tween) and _movement_tween.is_running():
		var cancelled_tween := _movement_tween
		cancelled_tween.kill()
		cancelled_tween.finished.emit()

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
