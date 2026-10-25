extends Control
## CENA DE TESTE do RunManager e do TimeModel. Não faz parte do jogo final.
## 1 prego · 2 parafuso · 3 prego torto · 4 parafuso enferrujado (slot concluído)
## N peça concluída · P pausa · E erro · T treino liga/desliga · R recomeça

var rm: RunManager
var label: Label
var log_lines: Array[String] = []
var total_checks: int = 0
var ok_checks: int = 0


func _ready() -> void:
	_testar_time_model()

	label = Label.new()
	label.position = Vector2(8, 8)
	label.add_theme_font_size_override("font_size", 8)
	add_child(label)

	rm = RunManager.new()
	add_child(rm)
	rm.score_changed.connect(func(p: int) -> void: _log("pontos = %d" % p))
	rm.level_changed.connect(func(l: int) -> void: _log("nível = %d" % l))
	rm.time_low.connect(func() -> void: _log("TEMPO BAIXO"))
	rm.time_expired.connect(func() -> void: _log("TEMPO ESGOTADO"))
	rm.run_finished.connect(_on_run_finished)
	rm.start_run()


func _process(_delta: float) -> void:
	label.text = "TEMPO: %.2f / %.0f s\nPONTOS: %d\nNÍVEL: %d (peças: %d)\nVIDA: %.1f s\nrodando: %s · pausa: %s · treino: %s\n\n%s" % [
		rm.time_left, RunManager.BARRA_MAX, rm.score, rm.level, rm.pieces_done,
		rm.life_time, rm.running, rm.paused, rm.training, "\n".join(log_lines)]


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_1: rm.on_slot_completed(TimeModel.SlotKind.NAIL)
			KEY_2: rm.on_slot_completed(TimeModel.SlotKind.SCREW)
			KEY_3: rm.on_slot_completed(TimeModel.SlotKind.BAD_NAIL)
			KEY_4: rm.on_slot_completed(TimeModel.SlotKind.RUSTY_SCREW)
			KEY_N: rm.on_piece_completed()
			KEY_P: rm.set_paused(not rm.paused)
			KEY_E: rm.finish_run(RunManager.MOTIVO_ACAO_INCORRETA)
			KEY_T: rm.training = not rm.training
			KEY_R: rm.start_run(rm.training)


func _on_run_finished(reason: String, score: int, life_time: float) -> void:
	_log("FIM: %s | %d pts | %.1f s" % [reason, score, life_time])


func _log(texto: String) -> void:
	print(texto)
	log_lines.append(texto)
	if log_lines.size() > 6:
		log_lines.pop_front()


func _check(nome: String, obtido: float, esperado: float) -> void:
	total_checks += 1
	var ok := absf(obtido - esperado) < 0.011
	if ok:
		ok_checks += 1
	print("[%s] %s: obtido %.3f, esperado %.3f" % ["OK" if ok else "FALHOU", nome, obtido, esperado])


func _testar_time_model() -> void:
	print("--- Conferindo o TimeModel com os valores do GDD ---")
	_check("T_MIN prego", TimeModel.t_min(TimeModel.SlotKind.NAIL), 1.36)
	_check("T_MIN parafuso", TimeModel.t_min(TimeModel.SlotKind.SCREW), 1.82)
	_check("T_MIN prego torto", TimeModel.t_min(TimeModel.SlotKind.BAD_NAIL), 1.93)
	_check("T_MIN parafuso enferrujado", TimeModel.t_min(TimeModel.SlotKind.RUSTY_SCREW), 3.35)

	_check("nível com 0 peças", TimeModel.nivel(0), 1)
	_check("nível com 4 peças", TimeModel.nivel(4), 1)
	_check("nível com 5 peças", TimeModel.nivel(5), 2)
	_check("nível com 24 peças", TimeModel.nivel(24), 5)
	_check("nível com 25 peças", TimeModel.nivel(25), 6)
	_check("nível com 100 peças", TimeModel.nivel(100), 6)

	_check("margem 0 peças", TimeModel.margem(0), 2.5)
	_check("margem 5 peças", TimeModel.margem(5), 2.2)
	_check("margem 10 peças", TimeModel.margem(10), 1.9)
	_check("margem 15 peças", TimeModel.margem(15), 1.7)
	_check("margem 20 peças", TimeModel.margem(20), 1.5)
	_check("margem 25 peças (teto)", TimeModel.margem(25), 1.3)
	_check("margem 35 peças", TimeModel.margem(35), 1.2)
	_check("margem 45 peças (piso)", TimeModel.margem(45), 1.1)
	_check("margem 100 peças (piso)", TimeModel.margem(100), 1.1)

	_check("prego rende no nível 1", TimeModel.tempo_concedido(TimeModel.SlotKind.NAIL, 0), 3.40)
	_check("prego rende no teto", TimeModel.tempo_concedido(TimeModel.SlotKind.NAIL, 25), 1.77)
	_check("enferrujado rende no piso", TimeModel.tempo_concedido(TimeModel.SlotKind.RUSTY_SCREW, 45), 3.69)
	print("Resultado: %d de %d conferências OK" % [ok_checks, total_checks])
