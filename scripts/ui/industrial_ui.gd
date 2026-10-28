extends RefCounted
## Tema AAP-64 compartilhado pela interface e pela prévia visual.
const FONT = preload("res://fonts/Tiny5-Regular.ttf")
const BG := Color("060608")
const PANEL := Color("122020")
const LINE := Color("333941")
const INK := Color("dae0ea")
const MUTED := Color("8b93af")
const UNIT := Color("92dcba")
const AMBER := Color("f9a31b")
const ERROR := Color("e86a73")
const SPACING := 4
const SMALL := 10
const TITLE := 20
const DISPLAY := 30

static func label(parent: Node, text: String, x: float, baseline: float, width: float = 272, font_size: int = 10, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.clip_text = true
	node.horizontal_alignment = align
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	node.position = Vector2(x, baseline - FONT.get_ascent(font_size))
	node.size = Vector2(width, FONT.get_height(font_size) + 2)
	return node

static func rect(parent: Node, position: Vector2, dimensions: Vector2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = position
	node.size = dimensions
	node.color = color
	parent.add_child(node)
	return node

static func text(canvas: CanvasItem, value: String, x: float, baseline: float, font_size: int = 10, color: Color = INK, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	canvas.draw_string(FONT, Vector2(x, baseline), value, align, width, font_size, color)

static func fit_label(node: Label, width: float, preferred_size: int = 10) -> void:
	var font_size := preferred_size
	while font_size > 8 and FONT.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	node.add_theme_font_size_override("font_size", font_size)

static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = LINE
	style.set_border_width_all(1)
	return style

# Painel do visor com cantos chanfrados; mantém a fábrica visível ao fundo.
static func visor_panel(canvas: CanvasItem, area: Rect2, tint: Color) -> void:
	var p := area.position
	var s := area.size
	var outline := PackedVector2Array([
		p + Vector2(3, 0), p + Vector2(s.x - 3, 0),
		p + Vector2(s.x, 3), p + Vector2(s.x, s.y - 3),
		p + Vector2(s.x - 3, s.y), p + Vector2(3, s.y),
		p + Vector2(0, s.y - 3), p + Vector2(0, 3),
		p + Vector2(3, 0)])
	canvas.draw_colored_polygon(outline, Color(BG, 0.76))
	canvas.draw_polyline(outline, Color(tint, 0.48), 1.0)
	canvas.draw_line(p + Vector2(4, 0), p + Vector2(minf(17, s.x - 4), 0), tint, 1.0)
