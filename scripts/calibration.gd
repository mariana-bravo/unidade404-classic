extends Control

const U = preload("res://scripts/ui/industrial_ui.gd")
const CONVEYOR_SCENE_PATH := "res://scenes/conveyor.tscn"
const DESIGN_SIZE := Vector2(320.0, 180.0)

# Correspondem aos tipos de encaixe usados pelo jogo.
# Match the slot kinds used by the game.
const SLOT_NAIL := 0
const SLOT_SCREW := 1
const SLOT_BAD_NAIL := 2
const SLOT_RUSTY_SCREW := 3

signal calibration_completed
signal calibration_skipped

# Telas curtas no estilo da intro. As peças vêm da cena real da esteira.
# Short intro-style pages. Parts come from the real conveyor scene.
const PAGES: Array[Dictionary] = [
	{
		"title": "A LINHA DE PRODUÇÃO",
		"body": "Na fábrica, as peças chegam pela esteira. Seu trabalho é identificar cada encaixe e seguir a instrução. Use somente o botão esquerdo do mouse.",
		"slots": [SLOT_NAIL],
		"caption": "EXEMPLO: PREGO"
	},
	{
		"title": "ESCOLHA A FERRAMENTA",
		"body": "Antes de cada encaixe: 1 clique seleciona o MARTELO; 2 cliques rápidos selecionam a CHAVE DE FENDA. Depois, 1 clique fixa o prego; segure para aparafusar.",
		"slots": [SLOT_NAIL, SLOT_SCREW],
		"caption": "PREGO + PARAFUSO"
	},
	{
		"title": "PEÇAS COM VÁRIOS ENCAIXES",
		"body": "Uma peça pode ter vários encaixes. Trabalhe da esquerda para a direita. Em cada encaixe, escolha a ferramenta necessária e faça o gesto indicado.",
		"slots": [SLOT_NAIL, SLOT_SCREW, SLOT_BAD_NAIL, SLOT_RUSTY_SCREW],
		"caption": "PEÇA MISTA: 4 ENCAIXES"
	},
	{
		"title": "PREGO DEFEITUOSO",
		"body": "Selecione o martelo (1 clique). Depois, dê 2 cliques rápidos para pedir a substituição. Aguarde o braço auxiliar; quando o prego novo chegar, dê 1 clique para fixá-lo.",
		"slots": [SLOT_BAD_NAIL],
		"caption": "PREGO A SUBSTITUIR"
	},
	{
		"title": "PARAFUSO ENFERRUJADO",
		"body": "Selecione a chave (2 cliques rápidos). Dê 1 clique curto e depois segure para remover o parafuso. Aguarde o braço auxiliar; segure novamente para aparafusar o novo.",
		"slots": [SLOT_RUSTY_SCREW],
		"caption": "PARAFUSO A SUBSTITUIR"
	}
]

const HOLD_TO_GO_BACK_SECONDS := 0.45
const PREVIEW_PANEL_POSITION := Vector2(159.0, 44.0)
const PREVIEW_PANEL_SIZE := Vector2(155.0, 96.0)
const PREVIEW_SCALE := 0.42

# Posição da estação de trabalho na cena conveyor.gd.
# Work-station position used by conveyor.gd.
const CONVEYOR_WORK_POSITION := Vector2(160.0, 112.0)

@onready var heading_label: Label = $Heading
@onready var status_label: Label = $Status
@onready var info_label: Label = $Info
@onready var clicks: ClickReader = $ClickReader

var _page_index: int = 0
var _conveyor: Node2D
var _preview_clip: Control
var _caption_label: Label
var _leaving: bool = false

# Clique curto avança; manter pressionado volta uma tela.
# Short click advances; holding the button goes back one page.
var _left_pressed: bool = false
var _left_hold_seconds: float = 0.0
var _hold_action_used: bool = false


func _ready() -> void:
	# Mantém a identidade visual da intro e do menu.
	# Match the look of the intro and main menu.
	_configure_label(
		heading_label,
		Vector2(8, 4),
		Vector2(304, 14),
		11,
		U.AMBER
	)
	_configure_label(
		status_label,
		Vector2(8, 18),
		Vector2(304, 10),
		8,
		U.MUTED
	)
	_configure_label(
		info_label,
		Vector2(12, 39),
		Vector2(136, 91),
		9,
		U.INK
	)

	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	heading_label.text = "UNIDADE 404: TUTORIAL"

	# A tela usa seu próprio clique para navegar; desativa o leitor do jogo.
	# This screen handles navigation itself; disable the game's gesture reader.
	clicks.set_process(false)
	clicks.set_process_input(false)
	clicks.set_process_unhandled_input(false)

	_create_piece_preview()
	_create_caption_label()
	_show_page(0)
	queue_redraw()

	# Coloca a peça na estação de trabalho real antes de congelar a prévia.
	# Move the item to the real work station before freezing the preview.
	if is_instance_valid(_conveyor) and _conveyor.has_method("enter_board"):
		await _conveyor.call("enter_board")
		if is_instance_valid(_conveyor) and _conveyor.has_method("stop_movement"):
			_conveyor.call("stop_movement")


func _configure_label(
	label: Label,
	label_position: Vector2,
	label_size: Vector2,
	font_size: int,
	font_color: Color
) -> void:
	# Posiciona e estiliza os rótulos / Position and style the labels.
	label.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	label.position = label_position
	label.size = label_size
	label.clip_text = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", U.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.z_index = 3


func _create_piece_preview() -> void:
	# Cria uma janela recortada para manter esteira e peça no painel direito.
	# Clip the preview so the belt and part stay inside the right panel.
	_preview_clip = Control.new()
	_preview_clip.name = "PiecePreviewClip"
	_preview_clip.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_preview_clip.position = PREVIEW_PANEL_POSITION
	_preview_clip.size = PREVIEW_PANEL_SIZE
	_preview_clip.clip_contents = true
	_preview_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_clip.z_index = 1
	add_child(_preview_clip)

	if not ResourceLoader.exists(CONVEYOR_SCENE_PATH):
		return

	var packed := load(CONVEYOR_SCENE_PATH) as PackedScene
	if packed == null:
		return

	var instance := packed.instantiate()
	if not instance is Node2D:
		instance.queue_free()
		return

	_conveyor = instance as Node2D
	_conveyor.name = "TutorialPiecePreview"

	# A prévia é estática; ela só mostra assets, não inicia uma partida.
	# The preview is static; it shows assets without starting a game.
	for property_info in _conveyor.get_property_list():
		if str(property_info.get("name", "")) == "demo_mode":
			_conveyor.set("demo_mode", false)
			break

	_preview_clip.add_child(_conveyor)

	# Centraliza a estação de trabalho no painel.
	# Center the work station inside the panel.
	_conveyor.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	_conveyor.position = (
		PREVIEW_PANEL_SIZE / 2.0
		- CONVEYOR_WORK_POSITION * PREVIEW_SCALE
	)
	_conveyor.z_index = 1


func _create_caption_label() -> void:
	# A legenda fica acima da prévia e nunca é coberta pelos sprites.
	# Keep the caption above the preview so sprites never cover it.
	_caption_label = Label.new()
	_caption_label.name = "PreviewCaption"
	_caption_label.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_caption_label.position = Vector2(163, 30)
	_caption_label.size = Vector2(147, 12)
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_label.add_theme_font_override("font", U.FONT)
	_caption_label.add_theme_font_size_override("font_size", 8)
	_caption_label.add_theme_color_override("font_color", U.AMBER)
	_caption_label.z_index = 4
	add_child(_caption_label)


func _show_page(index: int) -> void:
	if index < 0 or index >= PAGES.size():
		return

	_page_index = index
	var page: Dictionary = PAGES[_page_index]

	status_label.text = "%s   %02d/%02d" % [
		str(page["title"]),
		_page_index + 1,
		PAGES.size()
	]

	info_label.text = str(page["body"])
	_caption_label.text = str(page["caption"])

	# Usa os tipos reais de encaixe, com o mesmo set_slots() do jogo.
	# Use real slot kinds through the same set_slots() method as gameplay.
	if is_instance_valid(_conveyor) and _conveyor.has_method("set_slots"):
		var slot_types: Array[int] = []

		for slot_type in page["slots"]:
			slot_types.append(int(slot_type))

		_conveyor.call("set_slots", slot_types)

		if _conveyor.has_method("update_slot_progress"):
			_conveyor.call("update_slot_progress", 0)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Só há um input físico: botão esquerdo. Curto avança; segurar volta.
	# One physical input: left mouse button. Short press advances; hold goes back.
	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	get_viewport().set_input_as_handled()

	if event.pressed:
		_left_pressed = true
		_left_hold_seconds = 0.0
		_hold_action_used = false
	else:
		if not _left_pressed:
			return

		if not _hold_action_used:
			_advance_page()

		_left_pressed = false
		_left_hold_seconds = 0.0
		_hold_action_used = false


func _process(delta: float) -> void:
	if not _left_pressed or _hold_action_used or _leaving:
		return

	_left_hold_seconds += delta

	if _left_hold_seconds >= HOLD_TO_GO_BACK_SECONDS:
		_hold_action_used = true

		if _page_index > 0:
			_show_page(_page_index - 1)


func _advance_page() -> void:
	if _leaving:
		return

	if _page_index < PAGES.size() - 1:
		_show_page(_page_index + 1)
	else:
		_leaving = true
		calibration_completed.emit()
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _draw() -> void:
	# Fundo e painéis semitransparentes do visor.
	# Background and semi-transparent visor panels.
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), U.BG, true)

	U.visor_panel(self, Rect2(6, 28, 148, 112), U.AMBER)
	U.visor_panel(self, Rect2(159, 28, 155, 112), U.LINE)

	if _page_index <= 0:
		U.text(
			self,
			"CLIQUE ESQUERDO: PRÓXIMA TELA",
			8, 174, 8, U.MUTED, 304,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	elif _page_index == PAGES.size() - 1:
		U.text(
			self,
			"CLIQUE: INICIAR PRODUÇÃO  /  SEGURE: VOLTAR",
			8, 174, 7, U.MUTED, 304,
			HORIZONTAL_ALIGNMENT_CENTER
		)
	else:
		U.text(
			self,
			"CLIQUE: PRÓXIMA  /  SEGURE: VOLTAR",
			8, 174, 8, U.MUTED, 304,
			HORIZONTAL_ALIGNMENT_CENTER
		)
