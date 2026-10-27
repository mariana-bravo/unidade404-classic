class_name VisorHud
extends CanvasLayer
const U = preload("res://scripts/ui/industrial_ui.gd")
const VisorFrame = preload("res://scripts/ui/visor_frame.gd")
var _visor_frame: Control
@export var max_time: float = Config.BARRA_MAX
var _name_label: Label
var _score_label: Label
var _serial_label: Label
var _best_label: Label
var _level_label: Label
var _time_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _panel_canvas: Control
var _panel_tint: Color = U.UNIT
var _low: bool = false
var _last_time: float = INF
var _pulse_tween: Tween
var best_score: int = 0
var robot_serial: int = 0

func _ready() -> void:
	_visor_frame = VisorFrame.new()
	add_child(_visor_frame)
	_panel_canvas = Control.new()
	_panel_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_canvas.draw.connect(_draw_panels)
	add_child(_panel_canvas)
	_name_label = U.label(self, "---", 20, 25, 108, 10)
	_serial_label = U.label(self, "Nº 000", 20, 38, 56, 8, U.MUTED)
	_level_label = U.label(self, "NÍVEL 1", 78, 38, 50, 8, U.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	U.label(self, "TEMPO", 141, 23, 44, 8, U.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label = U.label(self, "08.0", 141, 36, 44, 16, U.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_bar_bg = U.rect(self, Vector2(141, 41), Vector2(44, 2), U.LINE)
	_bar_fill = U.rect(self, Vector2(141, 41), Vector2(44, 2), U.INK)
	U.label(self, "PONTOS", 236, 23, 62, 8, U.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	_score_label = U.label(self, "0000", 236, 36, 62, 14, U.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	_best_label = U.label(self, "REC. 0000", 236, 47, 62, 8, U.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	set_time(Config.BARRA_INICIAL)


func _draw_panels() -> void:
	U.visor_panel(_panel_canvas, Rect2(14, 14, 120, 30), _panel_tint)
	U.visor_panel(_panel_canvas, Rect2(137, 14, 52, 33), _panel_tint)
	U.visor_panel(_panel_canvas, Rect2(230, 14, 74, 38), _panel_tint)

func _process(_delta: float) -> void:
	_bar_fill.visible = not _low or floori(Time.get_ticks_msec() / 150.0) % 2 == 0

func set_score(points: int) -> void:
	_score_label.text = "%04d" % points
	U.fit_label(_score_label, 62, 14)

func set_time(seconds: float) -> void:
	var ratio := clampf(seconds / max_time, 0.0, 1.0)
	_low = ratio < Config.LIMIAR_TEMPO_BAIXO
	_time_label.text = "%04.1f" % maxf(0.0, seconds)
	_time_label.add_theme_color_override("font_color", U.AMBER if _low else U.INK)
	_bar_fill.size.x = 44 * ratio
	_bar_fill.color = U.AMBER if _low else U.INK
	if seconds > _last_time + 0.05:
		_pulse_bar()
	_last_time = seconds

func set_level(level: int) -> void:
	_level_label.text = "NÍVEL %d" % level

func set_best(points: int = 0) -> void:
	# Recorde sempre visível no canto superior direito.
	best_score = points
	_best_label.text = "REC. %04d" % points
	U.fit_label(_best_label, 62, 8)

func set_robot(robot_name: String, serial: int) -> void:
	_name_label.text = robot_name.to_upper()
	robot_serial = serial
	_serial_label.text = "Nº %03d" % serial
	U.fit_label(_name_label, 108)

func set_station_width(width: float) -> void:
	_visor_frame.station_width = clampf(width + 8, 52, 260)
	_visor_frame.queue_redraw()

func set_tint(color: Color) -> void:
	_visor_frame.tint = color
	_visor_frame.queue_redraw()
	_panel_tint = color
	_panel_canvas.queue_redraw()
	_name_label.add_theme_color_override("font_color", U.INK)

func _pulse_bar() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_bar_fill.modulate = Color(1.3, 1.3, 1.3)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_bar_fill, "modulate", Color.WHITE, 0.2)
