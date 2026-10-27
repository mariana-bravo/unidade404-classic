class_name VisorHud
extends CanvasLayer
## HUD do visor do robô (GDD seção 11): tempo, pontos, nível, recorde e identidade.
## Contrato do GDD 16.2: set_score(points), set_time(seconds), set_level(level).
## A interface é montada por código, para ser fácil de trocar pela arte final.
## Todos os controles ignoram o mouse: assim nunca engolem o clique do jogador.
## Só chame os set_* depois de adicionar o HUD à cena (depois do _ready).

const COR_MOLDURA := Color(0.80, 0.82, 0.85)
const COR_TEXTO := Color(0.80, 1.00, 0.85)
const COR_BARRA := Color(0.80, 1.00, 0.85)
const COR_BARRA_BAIXA := Color(1.00, 0.72, 0.15)   # âmbar: o vermelho é reservado ao erro
const COR_FUNDO_BARRA := Color(0.08, 0.10, 0.10)
const Settings = preload("res://scripts/autoload/config.gd")
const LIMIAR_BAIXO := Settings.LIMIAR_TEMPO_BAIXO
const BARRA_X := 120.0
const BARRA_Y := 14.0
const BARRA_LARGURA := 80.0
const BARRA_ALTURA := 6.0
const LARGURA_TELA := 320.0
const ALTURA_TELA := 180.0
const ESPESSURA_MOLDURA := 3.0

@export var max_time: float = Settings.BARRA_MAX   # igual ao RunManager.BARRA_MAX

var _frame: Control
var _name_label: Label
var _serial_label: Label
var _score_label: Label
var _best_label: Label
var _level_label: Label
var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _low: bool = false
var _last_time: float = INF
var _pulse_tween: Tween


func _ready() -> void:
	_build_frame()
	_name_label = _make_label("---", Vector2(8, 4), Vector2(108, 10), HORIZONTAL_ALIGNMENT_LEFT)
	_serial_label = _make_label("Nº 000", Vector2(8, 14), Vector2(108, 10), HORIZONTAL_ALIGNMENT_LEFT)
	_make_label("TEMPO", Vector2(BARRA_X, 3), Vector2(BARRA_LARGURA, 10), HORIZONTAL_ALIGNMENT_CENTER)
	_bar_bg = _make_rect(self, Vector2(BARRA_X, BARRA_Y), Vector2(BARRA_LARGURA, BARRA_ALTURA), COR_FUNDO_BARRA)
	_bar_fill = _make_rect(self, Vector2(BARRA_X, BARRA_Y), Vector2(BARRA_LARGURA, BARRA_ALTURA), COR_BARRA)
	_level_label = _make_label("", Vector2(BARRA_X, 22), Vector2(BARRA_LARGURA, 10), HORIZONTAL_ALIGNMENT_CENTER)
	_score_label = _make_label("", Vector2(204, 4), Vector2(108, 10), HORIZONTAL_ALIGNMENT_RIGHT)
	_best_label = _make_label("", Vector2(204, 14), Vector2(108, 10), HORIZONTAL_ALIGNMENT_RIGHT)
	set_score(0)
	set_best()
	set_level(1)
	set_time(max_time)
	set_tint(Color.WHITE)


func _process(_delta: float) -> void:
	# Com pouco tempo, a barra pisca (GDD seção 11).
	if _low:
		_bar_fill.visible = floori(Time.get_ticks_msec() / 150.0) % 2 == 0
	elif not _bar_fill.visible:
		_bar_fill.visible = true


# ---------------- Contrato do GDD ----------------

func set_score(points: int) -> void:
	_score_label.text = "PONTOS %04d" % points


func set_time(seconds: float) -> void:
	var ratio := clampf(seconds / max_time, 0.0, 1.0)
	_bar_fill.size = Vector2(BARRA_LARGURA * ratio, BARRA_ALTURA)
	_low = ratio < LIMIAR_BAIXO
	_bar_fill.color = COR_BARRA_BAIXA if _low else COR_BARRA
	# Se o tempo subiu, um slot foi concluído: pulso rápido na barra.
	if seconds > _last_time + 0.05:
		_pulse_bar()
	_last_time = seconds


func set_level(level: int) -> void:
	_level_label.text = "NÍVEL %d" % level


# ---------------- Extras (identidade e recorde) ----------------

func set_best(points: int = -1) -> void:
	_best_label.text = "RECORDE ---" if points < 0 else "RECORDE %04d" % points


func set_robot(robot_name: String, serial: int) -> void:
	_name_label.text = robot_name
	# Nomes longos devem caber no canto sem invadir a barra.
	var font := _name_label.get_theme_font("font")
	var font_size := 8
	while font_size > 5 and font.get_string_size(robot_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _name_label.size.x:
		font_size -= 1
	_name_label.add_theme_font_size_override("font_size", font_size)
	_serial_label.text = "Nº %03d" % serial


## Cor da unidade atual: tinge só a moldura (o texto continua neutro).
func set_tint(color: Color) -> void:
	_frame.modulate = color


# ---------------- Construção da interface ----------------

func _build_frame() -> void:
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	var e := ESPESSURA_MOLDURA
	_make_rect(_frame, Vector2(0, 0), Vector2(LARGURA_TELA, e), COR_MOLDURA)
	_make_rect(_frame, Vector2(0, ALTURA_TELA - e), Vector2(LARGURA_TELA, e), COR_MOLDURA)
	_make_rect(_frame, Vector2(0, 0), Vector2(e, ALTURA_TELA), COR_MOLDURA)
	_make_rect(_frame, Vector2(LARGURA_TELA - e, 0), Vector2(e, ALTURA_TELA), COR_MOLDURA)


func _make_rect(parent: Node, pos: Vector2, tam: Vector2, cor: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = tam
	r.color = cor
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _make_label(texto: String, pos: Vector2, tam: Vector2, alinhamento: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.size = tam
	l.horizontal_alignment = alinhamento
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", COR_TEXTO)
	add_child(l)
	return l


func _pulse_bar() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_bar_fill.modulate = Color(1.8, 1.8, 1.8)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_bar_fill, "modulate", Color.WHITE, 0.25)
