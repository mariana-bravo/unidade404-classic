class_name RunManager
extends Node
## Guarda os números da vida atual do robô: pontos, nível e barra de tempo
## (GDD seções 6.2, 7 e 8). Não desenha nada e não conhece o resto do jogo:
## quem precisa dos números escuta os sinais.

signal score_changed(points: int)
signal level_changed(level: int)
signal time_changed(seconds: float)
signal time_low
signal time_expired
signal run_finished(reason: String, score: int, life_time: float)

const MOTIVO_ACAO_INCORRETA := "acao_incorreta"
const MOTIVO_TEMPO_ESGOTADO := "tempo_esgotado"

const Settings = preload("res://scripts/autoload/config.gd")
const BARRA_INICIAL := Settings.BARRA_INICIAL
const BARRA_MAX := Settings.BARRA_MAX
const LIMIAR_TEMPO_BAIXO := Settings.LIMIAR_TEMPO_BAIXO   # abaixo de 25% da barra dispara time_low
const PONTOS_POR_SLOT := 10
const PONTOS_POR_PECA := 50

var score: int = 0
var pieces_done: int = 0
var level: int = 1
var time_left: float = BARRA_INICIAL
var life_time: float = 0.0
var running: bool = false
var training: bool = false   # calibração: a barra não desce e não mata
var _low_emitted: bool = false


## Começa uma vida nova do zero. Na calibração, use start_run(true).
func start_run(is_training: bool = false) -> void:
	score = 0
	pieces_done = 0
	level = 1
	time_left = BARRA_INICIAL
	life_time = 0.0
	training = is_training
	_low_emitted = false
	running = true
	score_changed.emit(score)
	level_changed.emit(level)
	time_changed.emit(time_left)


func _process(delta: float) -> void:
	if not running or training:
		return
	life_time += delta
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		time_changed.emit(time_left)
		time_expired.emit()
		finish_run(MOTIVO_TEMPO_ESGOTADO)
		return
	time_changed.emit(time_left)
	_check_low_time()


## Chamar quando o jogador conclui um slot. `kind` é um TimeModel.SlotKind.
func on_slot_completed(kind: int, tempo_esteira: float = 0.0) -> void:
	if not running:
		return
	add_points(PONTOS_POR_SLOT)
	var bonus := TimeModel.tempo_concedido(kind, pieces_done, tempo_esteira)
	time_left = minf(time_left + bonus, BARRA_MAX)
	time_changed.emit(time_left)
	_check_low_time()


## Chamar quando a peça inteira termina (depois do último slot).
func on_piece_completed() -> void:
	if not running:
		return
	pieces_done += 1
	add_points(PONTOS_POR_PECA)
	var new_level := TimeModel.nivel(pieces_done)
	if new_level != level:
		level = new_level
		level_changed.emit(level)


func add_points(amount: int) -> void:
	if not running:
		return
	score += amount
	score_changed.emit(score)


## Encerra a vida (erro do jogador ou tempo esgotado). Só funciona uma vez.
func finish_run(reason: String) -> void:
	if not running:
		return
	running = false
	run_finished.emit(reason, score, life_time)


func get_time_ratio() -> float:
	return time_left / BARRA_MAX


func _check_low_time() -> void:
	var low := get_time_ratio() < LIMIAR_TEMPO_BAIXO
	if low and not _low_emitted:
		_low_emitted = true
		time_low.emit()
	elif not low:
		_low_emitted = false
