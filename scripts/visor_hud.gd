class_name VisorHud
extends CanvasLayer
const U = preload("res://scripts/ui/industrial_ui.gd")
const VisorFrame = preload("res://scripts/ui/visor_frame.gd")
var _visor_frame: Control
@export var max_time: float = Config.BARRA_MAX
var _name_label: Label
var _score_label: Label
var _level_label: Label
var _time_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _identity_accent: ColorRect
var _low: bool = false
var _last_time: float = INF
var _pulse_tween: Tween
var best_score: int = 0
var robot_serial: int = 0

func _ready() -> void:
	_visor_frame = VisorFrame.new()
	add_child(_visor_frame)
	# Placas discretas mantêm a leitura sobre a arte da fábrica.
	var shade := Color(U.BG, 0.86)
	U.rect(self, Vector2(16, 14), Vector2(119, 33), shade)
	U.rect(self, Vector2(136, 14), Vector2(52, 14), shade)
	U.rect(self, Vector2(111, 30), Vector2(98, 28), U.BG)
	U.rect(self, Vector2(235, 14), Vector2(69, 33), shade)
	_name_label = U.label(self, "---", 20, 25, 114, 10)
	_level_label = U.label(self, "NÍVEL 1", 20, 44, 80, 10, U.MUTED)
	U.label(self, "PONTOS", 254, 25, 46, 10, U.MUTED)
	_score_label = U.label(self, "0000", 238, 44, 62, 20, U.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	U.label(self, "TEMPO", 139, 25, 60, 10, U.MUTED)
	_time_label = U.label(self, "08.0", 115, 55, 100, 30)
	_bar_bg = U.rect(self, Vector2(88, 61), Vector2(144, 3), U.LINE)
	_bar_fill = U.rect(self, Vector2(88, 61), Vector2(144, 3), U.INK)
	_identity_accent = U.rect(self, Vector2(12, 18), Vector2(2, 8), U.UNIT)
	set_time(Config.BARRA_INICIAL)

func _process(_delta: float) -> void:
	_bar_fill.visible = not _low or floori(Time.get_ticks_msec() / 150.0) % 2 == 0

func set_score(points: int) -> void:
	_score_label.text = "%04d" % points
	U.fit_label(_score_label, 62, 20)

func set_time(seconds: float) -> void:
	var ratio := clampf(seconds / max_time, 0.0, 1.0)
	_low = ratio < Config.LIMIAR_TEMPO_BAIXO
	_time_label.text = "%04.1f" % maxf(0.0, seconds)
	_time_label.add_theme_color_override("font_color", U.AMBER if _low else U.INK)
	_bar_fill.size.x = 144 * ratio
	_bar_fill.color = U.AMBER if _low else U.INK
	if seconds > _last_time + 0.05:
		_pulse_bar()
	_last_time = seconds

func set_level(level: int) -> void:
	_level_label.text = "NÍVEL %d" % level

func set_best(points: int = 0) -> void:
	# O recorde permanece no placar e no resultado, liberando espaço no HUD.
	best_score = points

func set_robot(robot_name: String, serial: int) -> void:
	_name_label.text = robot_name.to_upper()
	robot_serial = serial
	U.fit_label(_name_label, 114)

func set_station_width(width: float) -> void:
	_visor_frame.station_width = clampf(width + 8, 52, 260)
	_visor_frame.queue_redraw()

func set_tint(color: Color) -> void:
	_visor_frame.tint = color
	_visor_frame.queue_redraw()
	_identity_accent.color = color
	_name_label.add_theme_color_override("font_color", color)

func _pulse_bar() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_bar_fill.modulate = Color(1.3, 1.3, 1.3)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_bar_fill, "modulate", Color.WHITE, 0.2)
