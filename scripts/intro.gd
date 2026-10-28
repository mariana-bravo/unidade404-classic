
extends Control

const U = preload("res://scripts/ui/industrial_ui.gd")
const Settings = preload("res://scripts/autoload/config.gd")

var pages: Array[String] = []
var page: int = 0
var visible_chars: float = 0.0

const CHARS_PER_SECOND: float = 28.0
const QUESTION_DELAY: float = 2.0

@onready var text_label: RichTextLabel = $Story
@onready var hint_label: Label = $Hint

var _typing: bool = false
var _asking_calibration: bool = false
var _options_visible: bool = false
var _question_elapsed: float = 0.0

var _pending_question_click: bool = false
var _pending_click_elapsed: float = 0.0
var _transitioning: bool = false


func _draw() -> void:
	# Mantém o fundo original da intro / Keep the original intro background.
	draw_rect(Rect2(0, 0, 320, 180), U.BG)


func _ready() -> void:
	# Preserva a identidade visual / Preserve the visual identity.
	text_label.add_theme_font_override("normal_font", U.FONT)
	text_label.add_theme_font_size_override("normal_font_size", 14)
	text_label.add_theme_color_override("default_color", U.INK)

	hint_label.add_theme_font_override("font", U.FONT)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", U.MUTED)
	hint_label.text = "CLIQUE: COMPLETAR / PRÓXIMO"

	if GameState.robot_name.is_empty():
		GameState.new_robot()
	pages = [
		"A FÁBRICA NUNCA PARA.",
		"Humanos erram.\nEles têm justificativas.",
		"Robôs não têm.",
		"%s\nUNIDADE 404: ATIVADA.\n\nNÃO ERRE.\nNÃO DEMORE."
		% GameState.robot_name
	]

	_show_page()


func _process(delta: float) -> void:
	# Revela o texto gradualmente / Reveal text gradually.
	if _typing:
		visible_chars += CHARS_PER_SECOND * delta

		if visible_chars >= text_label.get_total_character_count():
			_typing = false
			text_label.visible_characters = -1
		else:
			text_label.visible_characters = int(visible_chars)

	# As opções aparecem dois segundos depois da pergunta.
	# Show the options two seconds after the question appears.
	if _asking_calibration and not _options_visible:
		_question_elapsed += delta

		if _question_elapsed >= QUESTION_DELAY:
			_options_visible = true
			hint_label.text = "1 CLIQUE: SIM  ·  2 CLIQUES: NÃO"
			hint_label.visible = true

	# Espera a janela de duplo clique antes de aceitar SIM.
	# Wait for the double-click window before accepting YES.
	if _asking_calibration and _options_visible:
		if _pending_question_click:
			_pending_click_elapsed += delta

			if _pending_click_elapsed >= Settings.JANELA_DUPLO:
				_pending_question_click = false
				_choose_calibration(true)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	get_viewport().set_input_as_handled()

	if _transitioning:
		return

	# Na pergunta, o clique simples e o duplo têm significados diferentes.
	# On the question, single and double clicks have different meanings.
	if _asking_calibration:
		if not _options_visible:
			return

		if _pending_question_click:
			_pending_question_click = false
			_choose_calibration(false)
		else:
			_pending_question_click = true
			_pending_click_elapsed = 0.0

		return

	_advance_story()


func _advance_story() -> void:
	# Um clique completa o texto que ainda está aparecendo.
	# A click completes text that is still being revealed.
	if _typing:
		_typing = false
		visible_chars = float(text_label.get_total_character_count())
		text_label.visible_characters = -1
		return

	page += 1

	if page >= pages.size():
		_show_calibration_question()
	else:
		_show_page()


func _show_page() -> void:
	# Exibe a próxima página da história / Display the next story page.
	text_label.clear()
	if page == pages.size() - 1:
		text_label.push_font_size(18)
		text_label.push_color(Config.PALETA[GameState.color_index])
		text_label.add_text(GameState.robot_name)
		text_label.pop()
		text_label.pop()
		text_label.add_text("\nUNIDADE 404: ATIVADA.\n\nNÃO ERRE.\nNÃO DEMORE.")
	else:
		text_label.add_text(pages[page])
	visible_chars = 0.0
	text_label.visible_characters = 0
	_typing = true

	hint_label.text = "CLIQUE: COMPLETAR / PRÓXIMO"
	hint_label.visible = true


func _show_calibration_question() -> void:
	# Exibe a pergunta antes de revelar os comandos.
	# Show the question before revealing the commands.
	_asking_calibration = true
	_options_visible = false
	_question_elapsed = 0.0
	_pending_question_click = false
	_pending_click_elapsed = 0.0

	text_label.text = "CALIBRAR UNIDADE?"
	visible_chars = 0.0
	text_label.visible_characters = 0
	_typing = true

	hint_label.text = ""
	hint_label.visible = false


func _choose_calibration(should_calibrate: bool) -> void:
	# Evita múltiplas trocas de cena / Prevent duplicate scene changes.
	if _transitioning:
		return

	_transitioning = true
	_pending_question_click = false

	if should_calibrate:
		get_tree().change_scene_to_file("res://scenes/calibration.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
