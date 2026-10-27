extends Control
## Moldura original do visor, com cor da unidade e estação ajustável.
const U = preload("res://scripts/ui/industrial_ui.gd")
const HUD = preload("res://art/HUD/404_hud.png")
const TINT_SHADER = preload("res://scripts/ui/visor_tint.gdshader")
var tint: Color = U.UNIT:
	set(value):
		tint = value
		if material != null:
			material.set_shader_parameter("visor_color", tint)
var station_width: float = 52.0
var show_station: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var visor_material := ShaderMaterial.new()
	visor_material.shader = TINT_SHADER
	visor_material.set_shader_parameter("visor_color", tint)
	material = visor_material

func _draw() -> void:
	# Mantém a moldura em 320x180 e separa a mira central para acompanhar a caixa.
	for region in [Rect2(0, 0, 320, 64), Rect2(0, 116, 320, 64), Rect2(0, 64, 128, 52), Rect2(192, 64, 128, 52)]:
		draw_texture_rect_region(HUD, region, region)
	if show_station:
		var left := floorf(160.0 - station_width / 2.0)
		var right := floorf(160.0 + station_width / 2.0)
		draw_texture_rect_region(HUD, Rect2(left, 64, 32, 52), Rect2(128, 64, 32, 52))
		draw_texture_rect_region(HUD, Rect2(right - 32, 64, 32, 52), Rect2(160, 64, 32, 52))
