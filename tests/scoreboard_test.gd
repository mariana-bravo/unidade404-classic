extends Node
const Store = preload("res://scripts/autoload/scoreboard_data.gd")
var checks := 0
var failures := 0
var path: String

func _ready() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _write_bytes(bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _run() -> void:
	path = "user://scoreboard_test_%d.dat" % Time.get_ticks_usec()
	var store := Store.new()
	store.save_path = path
	add_child(store)
	_check(store.get_entries().is_empty() and store.get_best_score() == 0, "Arquivo ausente inicia vazio")
	_check(store.submit_run("Operário Cansado", 100, 60.75), "Primeira vida entra")
	_check(store.last_save_error == OK, "Primeira gravacao tem sucesso")
	var saved := FileAccess.get_file_as_bytes(path)
	_check(saved.slice(0, 4).get_string_from_ascii() == "U404" and saved[4] == 1, "Cabecalho binario versionado")
	store.submit_run("Sucata Sem Memória", 300, 120.5)
	store.submit_run("Autômato de Taubaté", 200, 80.25)
	_check(store.get_best_score() == 300 and store.get_entries().size() == 3, "Top 3 ordenado")
	_check(not store.submit_run("Descartado", 50, 500.0), "Quarta colocacao descartada")
	store.submit_run("Máquina Desligada", 200, 90.125)
	_check(store.get_entries()[1]["name"] == "Máquina Desligada", "Empate por maior tempo")
	_check(not store.submit_run("Empate exato", 200, 80.25), "Empate exato preserva anteriores")
	var copy := store.get_entries()
	copy[0]["score"] = 0
	_check(store.get_best_score() == 300, "Consulta nao modifica dados internos")
	var reloaded := Store.new()
	reloaded.save_path = path
	add_child(reloaded)
	_check(reloaded.get_entries() == store.get_entries(), "Reabertura preserva nomes acentuados e precisao")
	_check(FileAccess.file_exists(path + ".bak"), "Backup criado")
	var backup_entries: Array = store._read_file(path + ".bak")["entries"]
	_write_bytes("arquivo invalido".to_utf8_buffer())
	reloaded.load_scores()
	_check(reloaded.get_entries() == backup_entries, "Principal corrompido recupera backup")
	reloaded.submit_run("Novo Recorde", 400, 180.0)
	_check(reloaded.last_save_error == OK and reloaded._read_file(path + ".bak")["entries"] == backup_entries, "Salvar apos recuperacao preserva backup valido")
	DirAccess.remove_absolute(path + ".bak")
	var valid := FileAccess.get_file_as_bytes(path)
	_write_bytes(valid.slice(0, 10))
	reloaded.load_scores()
	_check(reloaded.get_entries().is_empty(), "Truncamento sem backup inicia vazio")
	var bad_version := valid.duplicate()
	bad_version[4] = 99
	_write_bytes(bad_version)
	reloaded.load_scores()
	_check(reloaded.get_entries().is_empty(), "Versao desconhecida rejeitada")
	var bad_count := valid.duplicate()
	bad_count[6] = 4
	_write_bytes(bad_count)
	reloaded.load_scores()
	_check(reloaded.get_entries().is_empty(), "Quantidade fora do limite rejeitada")
	var trailing := valid.duplicate()
	trailing.append(0)
	_write_bytes(trailing)
	reloaded.load_scores()
	_check(reloaded.get_entries().is_empty(), "Bytes extras rejeitados")
	_check(not store.submit_run("", 100, 1.0) and not store.submit_run("Nome", -1, 1.0), "Nome vazio e pontos negativos rejeitados")
	_check(not store.submit_run("Nome", 100, NAN) and not store.submit_run("Nome", 100, INF), "Tempos nao finitos rejeitados")
	_check(not store.submit_run("x".repeat(257), 100, 1.0), "Nome excessivo rejeitado")
	store.save_path = "user://pasta_inexistente_%d/scoreboard.dat" % Time.get_ticks_usec()
	_check(store.submit_run("Vida em memória", 1000, 12.0) and store.last_save_error != OK and store.get_best_score() == 1000, "Falha de gravacao preserva resultado em memoria")

	ScoreboardData.save_path = path
	ScoreboardData.load_scores()
	var screen := preload("res://scenes/scoreboard.tscn").instantiate()
	add_child(screen)
	_check(screen._rows[0][0].text == "---", "Tabela vazia mostra tracos")
	ScoreboardData.submit_run("Estagiário Desempregado", 1250, 143.72)
	_check(screen._rows[0][0].text == "Estagiário Desempregado" and screen._rows[0][1].text == "02:23" and screen._rows[0][2].text == "1250", "Tabela mostra nome tempo e pontos")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	screen._unhandled_input(event)
	screen._process(0.3)
	_check(screen._progress.value > 0.0, "Segurar mostra progresso")
	event.pressed = false
	screen._unhandled_input(event)
	_check(not screen.held and is_zero_approx(screen._progress.value), "Soltar cancela retorno")
	if "--capture" in OS.get_cmdline_user_args():
		ScoreboardData.submit_run("Autômato de Taubaté", 900, 119.0)
		ScoreboardData.submit_run("Sucata Sem Memória", 800, 60.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/scoreboard_preview.png")
	screen.free()
	store.free()
	reloaded.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	print("SCOREBOARD: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
