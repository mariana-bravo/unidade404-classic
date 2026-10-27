extends Control
## Contorno provisório do visor, inspirado na referência; usa a cor da unidade.
const U = preload("res://scripts/ui/industrial_ui.gd")
var tint: Color = U.UNIT
var station_width: float = 52.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var outline := PackedVector2Array([
		Vector2(2, 8), Vector2(9, 2), Vector2(42, 2), Vector2(50, 11),
		Vector2(98, 11), Vector2(106, 2), Vector2(214, 2), Vector2(222, 11),
		Vector2(270, 11), Vector2(278, 2), Vector2(311, 2), Vector2(317, 8),
		Vector2(317, 56), Vector2(308, 64), Vector2(308, 78), Vector2(317, 86),
		Vector2(317, 91), Vector2(308, 100), Vector2(308, 121), Vector2(317, 129),
		Vector2(317, 171), Vector2(310, 177), Vector2(278, 177), Vector2(270, 169),
		Vector2(222, 169), Vector2(214, 177), Vector2(106, 177), Vector2(98, 169),
		Vector2(50, 169), Vector2(42, 177), Vector2(9, 177), Vector2(2, 171),
		Vector2(2, 124), Vector2(11, 116), Vector2(11, 100), Vector2(2, 92),
		Vector2(2, 87), Vector2(11, 79), Vector2(11, 64), Vector2(2, 56), Vector2(2, 8)])
	draw_polyline(outline, tint, 1.0)
	var left := 160.0 - station_width / 2.0
	var right := 160.0 + station_width / 2.0
	for x in [left, right]:
		var direction := 1.0 if x == left else -1.0
		draw_polyline(PackedVector2Array([Vector2(x, 74), Vector2(x, 68), Vector2(x + direction * 3, 65), Vector2(x + direction * 10, 65)]), tint, 1.0)
		draw_polyline(PackedVector2Array([Vector2(x, 105), Vector2(x, 112), Vector2(x + direction * 3, 115), Vector2(x + direction * 10, 115)]), tint, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(157, 9), Vector2(163, 9), Vector2(160, 6)]), tint)
	draw_colored_polygon(PackedVector2Array([Vector2(157, 171), Vector2(163, 171), Vector2(160, 174)]), tint)
