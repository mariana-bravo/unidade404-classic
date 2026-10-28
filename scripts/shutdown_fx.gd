class_name ShutdownFx
extends CanvasLayer
## Sequência isolada: apresentação e escolha de destino; não altera a partida.
signal reboot_requested
signal menu_requested
signal boot_finished

enum State { HIDDEN, SHUTTING_DOWN, PROTECTED, READY, REBOOTING, LEAVING }
const U = preload("res://scripts/ui/industrial_ui.gd")
const POWER_DOWN = preload("res://audio/sfx/power_down.ogg")
const BOOT = preload("res://audio/sfx/boot.ogg")
const ALARM = preload("res://audio/sfx/error.ogg")
const SCREEN_SHADER := """shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 image_scale = vec2(1.0);
void fragment() {
	vec2 uv = (SCREEN_UV - vec2(0.5)) / max(image_scale, vec2(0.0001)) + vec2(0.5);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = texture(screen_texture, uv);
	}
}
"""

var state: State = State.HIDDEN
var elapsed: float = 0.0
var _physical_down: bool = false
var _requires_release: bool = false
var _power_played: bool = false
var _alarm_beat: int = -1
var _led: ColorRect
var _collapse: ColorRect
var _material: ShaderMaterial
var _results: Control
var _title: Label
var _cause: Label
var _identity: Label
var _points: Label
var _life: Label
var _action_bg: ColorRect
var _boot_panel: Control
var _boot_name: Label
var _boot_serial: Label
var _boot_fill: ColorRect
var _rank: Label
var _hint: Label
var _boot_text: Label
var _alarm: AudioStreamPlayer
var _power: AudioStreamPlayer

func _ready() -> void:
	layer = 20
	var shader := Shader.new()
	shader.code = SCREEN_SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_collapse = ColorRect.new()
	_collapse.size = Vector2(320, 180)
	_collapse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collapse.material = _material
	_collapse.visible = false
	add_child(_collapse)
	_results = Control.new()
	_results.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_results.visible = false
	add_child(_results)
	U.rect(_results, Vector2.ZERO, Vector2(320, 180), U.BG)
	_title = U.label(_results, "UNIDADE DESLIGADA", 24, 40, 272, 20, U.ERROR)
	_cause = U.label(_results, "", 24, 59, 272, 10, U.MUTED)
	_identity = U.label(_results, "", 24, 85)
	U.label(_results, "PONTOS", 24, 106, 120, 10, U.MUTED)
	U.label(_results, "TEMPO", 170, 106, 120, 10, U.MUTED)
	_points = U.label(_results, "", 24, 126, 120, 20)
	_life = U.label(_results, "", 170, 126, 126, 20)
	_rank = U.label(_results, "", 24, 141, 272, 10, U.AMBER)
	_action_bg = U.rect(_results, Vector2(24, 149), Vector2(272, 14), U.PANEL)
	_hint = U.label(_results, "", 34, 159, 252, 10, U.MUTED)
	_boot_panel = Control.new()
	_boot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boot_panel.visible = false
	add_child(_boot_panel)
	move_child(_boot_panel, 0)
	U.rect(_boot_panel, Vector2.ZERO, Vector2(320, 180), U.BG)
	_boot_text = U.label(_boot_panel, "INICIALIZANDO", 24, 49, 272, 20, U.UNIT)
	_boot_serial = U.label(_boot_panel, "", 24, 82, 272, 10, U.MUTED)
	_boot_name = U.label(_boot_panel, "", 24, 106, 272, 20)
	U.rect(_boot_panel, Vector2(24, 132), Vector2(272, 3), U.LINE)
	_boot_fill = U.rect(_boot_panel, Vector2(24, 132), Vector2(0, 3), U.UNIT)
	_alarm = AudioStreamPlayer.new()
	_alarm.stream = ALARM
	_alarm.volume_db = -17.0
	add_child(_alarm)
	_power = AudioStreamPlayer.new()
	_power.volume_db = -12.0
	add_child(_power)

func begin(result: Dictionary, wall_led: ColorRect) -> void:
	if state != State.HIDDEN:
		return
	_led = wall_led
	_physical_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_requires_release = _physical_down
	_cause.text = "TEMPO ESGOTADO" if result["reason"] == RunManager.MOTIVO_TEMPO_ESGOTADO else "AÇÃO INCORRETA"
	_identity.text = result["name"].to_upper()
	_identity.add_theme_color_override("font_color", Config.PALETA[GameState.color_index])
	var seconds := int(result["life_seconds"])
	_points.text = str(result["score"])
	_life.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	U.fit_label(_points, 120, 20)
	_rank.text = "NOVO RECORDE" if result["new_best"] else ("ENTROU NO PLACAR" if result["ranked"] else "")
	_hint.text = "AGUARDE..."
	_action_bg.color = U.PANEL
	_hint.add_theme_color_override("font_color", U.MUTED)
	_collapse.visible = true
	_material.set_shader_parameter("image_scale", Vector2.ONE)
	state = State.SHUTTING_DOWN
	elapsed = 0.0
	_alarm_beat = -1
	_power_played = false

func begin_boot(robot_name: String) -> void:
	state = State.REBOOTING
	elapsed = 0.0
	_results.visible = false
	_collapse.visible = true
	_boot_panel.visible = true
	_boot_text.text = "INICIALIZANDO"
	_boot_serial.text = "Nº %03d" % GameState.serial
	_boot_name.text = robot_name.to_upper()
	_boot_name.add_theme_color_override("font_color", Config.PALETA[GameState.color_index])
	U.fit_label(_boot_name, 272, 20)
	_boot_fill.size.x = 0
	_material.set_shader_parameter("image_scale", Vector2(0.008, 0.012))
	_power.stream = BOOT
	_power.play()

func _process(delta: float) -> void:
	elapsed += delta
	match state:
		State.SHUTTING_DOWN:
			var t := elapsed / Config.DESLIGAMENTO_DURACAO
			if t < 0.4:
				var beat := floori(elapsed / 0.22)
				if is_instance_valid(_led):
					_led.color = U.ERROR if beat % 2 == 0 else Color("3b1725")
				if beat != _alarm_beat:
					_alarm_beat = beat
					_alarm.play()
			else:
				_alarm.stop()
				if not _power_played:
					_power_played = true
					_power.stream = POWER_DOWN
					_power.play()
			if t >= 0.4 and t < 0.8:
				_material.set_shader_parameter("image_scale", Vector2(1.0, lerpf(1.0, 0.012, (t - 0.4) / 0.4)))
			elif t >= 0.8:
				_material.set_shader_parameter("image_scale", Vector2(lerpf(1.0, 0.008, clampf((t - 0.8) / 0.15, 0.0, 1.0)), 0.012))
			if elapsed >= Config.DESLIGAMENTO_DURACAO:
				_alarm.stop()
				_collapse.visible = false
				_results.visible = true
				state = State.PROTECTED
				elapsed = 0.0
		State.PROTECTED:
			if elapsed >= Config.GAME_OVER_PROTECAO:
				state = State.READY
				elapsed = 0.0
				_requires_release = _physical_down
				_hint.text = "CLIQUE: JOGAR NOVAMENTE"
				_action_bg.color = U.AMBER
				_hint.add_theme_color_override("font_color", U.BG)
		State.READY:
			if elapsed >= Config.GAME_OVER_ESPERA:
				state = State.LEAVING
				menu_requested.emit()
		State.REBOOTING:
			var t := clampf(elapsed / Config.REBOOT_DURACAO, 0.0, 1.0)
			_material.set_shader_parameter("image_scale", Vector2(lerpf(0.008, 1.0, minf(t / 0.25, 1.0)), lerpf(0.012, 1.0, clampf((t - 0.25) / 0.45, 0.0, 1.0))))
			_boot_fill.size.x = 272 * t
			_boot_text.text = "UNIDADE ATIVADA" if t >= 0.7 else "INICIALIZANDO"
			if elapsed >= Config.REBOOT_DURACAO + Config.REBOOT_LEITURA:
				_collapse.visible = false
				_boot_panel.visible = false
				state = State.HIDDEN
				boot_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if state == State.HIDDEN or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	_physical_down = event.pressed
	if state != State.READY:
		return
	if _requires_release:
		if not event.pressed:
			_requires_release = false
		return
	if event.pressed:
		state = State.LEAVING
		reboot_requested.emit()

func _exit_tree() -> void:
	for player in [_alarm, _power]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
