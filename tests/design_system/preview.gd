extends Control
## F6: clique avança, segurar volta. Dados fictícios, sem persistência.
const S = preload("res://tests/design_system/industrial_style.gd")
const PAGES := ["ATIVAÇÃO", "LINHA", "REGISTROS", "DESCARTE", "REBOOT", "SISTEMA"]
var page: int = 0
var clock: float = 0.0
var holding: bool = false
var hold_time: float = 0.0
var _navigated: bool = false
var _capture: bool = false
var _prior_mouse_mode: Input.MouseMode

func _ready() -> void:
	_prior_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capture = "--capture" in OS.get_cmdline_user_args()
	if _capture:
		call_deferred("_capture_pages")

func _exit_tree() -> void:
	Input.mouse_mode = _prior_mouse_mode

func _process(delta: float) -> void:
	if not _capture:
		clock += delta
	if holding:
		hold_time += delta
		if hold_time >= 0.8 and not _navigated:
			_navigated = true
			_change_page(-1)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if event.pressed:
		holding = true
		hold_time = 0.0
		_navigated = false
	else:
		if holding and not _navigated:
			_change_page(1)
		holding = false

func _change_page(direction: int) -> void:
	page = posmod(page + direction, PAGES.size())
	clock = 0.0
	queue_redraw()

func _box(x: float, y: float, w: float, h: float, color: Color, border: Color = Color.TRANSPARENT) -> void:
	var rect := Rect2(x, y, w, h)
	draw_rect(rect, color)
	if border.a > 0.0:
		draw_rect(rect, border, false, 1.0)

func _text(text: String, x: float, baseline: float, font_size: int = 10, color: Color = S.INK, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(S.FONT, Vector2(x, baseline), text, align, width, font_size, color)

func _line(x: float, y: float, width: float, color: Color = S.LINE) -> void:
	draw_line(Vector2(x, y), Vector2(x + width, y), color)

func _tag(text: String, x: float, y: float, width: float, color: Color) -> void:
	_box(x, y, width, 13, Color(color, 0.08), color)
	_text(text, x + 4, y + 9, 10, color)

func _draw() -> void:
	_box(0, 0, 320, 180, S.BG)
	match page:
		0: _menu()
		1: _game()
		2: _scores()
		3: _shutdown()
		4: _boot()
		5: _system()
	# Navegação discreta da prévia, sem cabeçalho ou rodapé de sistema.
	_text("CLIQUE: PRÓXIMA / SEGURAR: ANTERIOR", 24, 175, 10, Color(S.MUTED, 0.6))
	if holding:
		_box(24, 179, 272 * minf(hold_time / 0.8, 1.0), 1, S.AMBER)

func _menu() -> void:
	_text("UNIDADE", 40, 49, 30)
	_text("404", 212, 54, 40, S.AMBER)
	_text("FUTURO NÃO ENCONTRADO", 40, 69, 10, S.MUTED)
	var selected := int(clock / 2.0) % 3
	var options := ["JOGAR", "PLACAR", "SAIR"]
	for i in range(3):
		var y := 88 + i * 22
		if i == selected:
			_box(40, y, 240, 18, S.PANEL)
			_box(40, y, 2, 18, S.AMBER)
		_text(options[i], 52, y + 12, 10, S.INK if i == selected else S.MUTED)

func _game() -> void:
	_text("OPERÁRIO CANSADO", 20, 25, 10, S.UNIT)
	_text("PONTOS", 254, 25, 10, S.MUTED)
	_text("1250", 238, 44, 20, S.INK, 62, HORIZONTAL_ALIGNMENT_RIGHT)
	_text("NÍVEL 3", 20, 44, 10, S.MUTED)
	var time_left := 8.0 - fmod(clock, 6.8)
	var color := S.AMBER if time_left < 2.5 else S.INK
	_text("TEMPO", 139, 25, 10, S.MUTED)
	_text("%04.1f" % time_left, 115, 65, 30, color)
	_box(88, 71, 144, 3, S.LINE)
	_box(88, 71, 144 * time_left / 10.0, 3, color)
	for y in [84, 137]:
		_line(12, y, 296)
		for i in range(19):
			_box(12 + posmod(i * 16 + int(clock * 8), 296), y + 2, 6, 2, S.LINE)
	_box(43, 94, 234, 36, S.PANEL, S.LINE)
	for x in [47, 271]:
		for y in [98, 124]:
			_box(x, y, 2, 2, S.MUTED)
	for i in range(4):
		var x := 60 + i * 52
		var active := i == 2
		_box(x, 99, 43, 26, Color(S.AMBER, 0.08) if active else S.BG, S.AMBER if active else S.LINE)
		var center := Vector2(x + 21, 111)
		if i == 0:
			draw_line(center - Vector2(6, 0), center + Vector2(6, 0), S.UNIT, 2)
			_text("OK", x + 16, 122, 10, S.UNIT)
		elif i == 1:
			draw_circle(center, 5, S.MUTED, false, 1)
			draw_line(center - Vector2(3, 3), center + Vector2(3, 3), S.MUTED)
		elif i == 2:
			draw_circle(center, 6, S.AMBER, false, 1)
			draw_line(center - Vector2(4, 2), center + Vector2(3, 3), S.AMBER, 2)
			_box(x + 3, 102, 2, 2, S.AMBER)
		else:
			draw_line(center + Vector2(0, 6), center - Vector2(3, 5), S.MUTED, 2)
			draw_line(center - Vector2(7, 5), center + Vector2(2, -5), S.MUTED, 2)
	_text("PREPARADO", 20, 153, 10, S.AMBER)
	_tag("CHAVE", 235, 145, 37, S.UNIT)
	var progress := fmod(clock, 1.4) / 1.4
	draw_arc(Vector2(292, 150), 8, 0, TAU, 32, S.LINE, 2)
	draw_arc(Vector2(292, 150), 8, -PI / 2, -PI / 2 + TAU * progress, 32, S.AMBER, 2)

func _scores() -> void:
	_text("PLACAR", 24, 40, 20)
	_text("UNIDADE", 40, 77, 10, S.MUTED)
	_text("VIDA", 191, 77, 10, S.MUTED)
	_text("PONTOS", 258, 77, 10, S.MUTED)
	var names := ["ESTAGIÁRIO DESEMPREGADO", "AUTÔMATO DE TAUBATÉ", "SUCATA SEM MEMÓRIA"]
	var times := ["02:23", "01:59", "01:00"]
	var scores := ["1250", "0900", "0800"]
	for i in range(3):
		var y := 84 + i * 23
		_box(12, y, 296, 20, S.PANEL if i == 0 else S.BG)
		if i == 0:
			_box(12, y, 2, 20, S.AMBER)
		_line(12, y + 20, 296)
		_text("%02d" % (i + 1), 18, y + 13, 10, S.AMBER if i == 0 else S.MUTED)
		_text(names[i], 40, y + 13, 10, S.INK)
		_text(times[i], 191, y + 13, 10, S.MUTED)
		_text(scores[i], 261, y + 13, 10, S.AMBER if i == 0 else S.INK, 40, HORIZONTAL_ALIGNMENT_RIGHT)

func _shutdown() -> void:
	_text("UNIDADE DESLIGADA", 24, 40, 20, S.ERROR)
	_text("AÇÃO INCORRETA", 24, 59, 10, S.MUTED)
	_text("ESTAGIÁRIO DESEMPREGADO", 24, 85, 10)
	_text("PONTOS", 24, 106, 10, S.MUTED)
	_text("TEMPO", 170, 106, 10, S.MUTED)
	_text("1250", 24, 126, 20)
	_text("02:23", 170, 126, 20)
	_text("NOVO RECORDE", 24, 141, 10, S.AMBER)
	var ready := fmod(clock, 5.0) > 1.5
	_box(24, 149, 272, 14, S.AMBER if ready else S.PANEL)
	_text("JOGAR NOVAMENTE" if ready else "AGUARDE...", 34, 159, 10, S.BG if ready else S.MUTED)

func _boot() -> void:
	var progress := minf(fmod(clock, 4.0) / 2.4, 1.0)
	_text("UNIDADE ATIVADA" if progress >= 1.0 else "INICIALIZANDO", 24, 49, 20, S.UNIT if progress >= 1.0 else S.INK)
	_text("Nº 019", 24, 82, 10, S.MUTED)
	_text("UNIDADE EM GREVE", 24, 106, 20)
	_box(24, 132, 272, 3, S.LINE)
	_box(24, 132, 272 * progress, 3, S.UNIT)

func _system() -> void:
	_text("PALETA E ESTADOS", 12, 43, 20)
	var colors := [S.BG, S.PANEL, S.INK, S.UNIT, S.AMBER, S.ERROR]
	var names := ["FUNDO", "PAINEL", "TEXTO", "UNIDADE", "ATENÇÃO", "ERRO"]
	for i in range(6):
		_box(12 + i * 50, 56, 46, 21, colors[i], S.LINE)
		_text(names[i], 12 + i * 50, 91, 10, S.MUTED)
	_tag("NEUTRO", 12, 103, 66, S.MUTED)
	_tag("SELEÇÃO", 85, 103, 66, S.UNIT)
	_tag("PREPARO", 158, 103, 66, S.AMBER)
	_tag("FALHA", 231, 103, 77, S.ERROR)
	_text("Aa 404", 12, 143, 30)
	_text("TINY5", 160, 138, 10, S.MUTED)

func _capture_pages() -> void:
	var target := "res://tests/design_system/previews"
	DirAccess.make_dir_recursive_absolute(target)
	for index in range(PAGES.size()):
		page = index
		clock = 2.6
		queue_redraw()
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png("%s/%02d.png" % [target, index + 1])
		if error != OK:
			get_tree().quit(1)
			return
	print("DESIGN SYSTEM: 6 telas renderizadas")
	get_tree().quit()
