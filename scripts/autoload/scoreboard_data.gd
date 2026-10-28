extends Node
## Binário little-endian: U404, versão u16, quantidade u8;
## por linha: tamanho UTF-8 u16, nome, pontos u32, segundos float64, cor RGBA u32 (v2; lê também v1 sem cor).
signal changed

const MAGIC := "U404"
const VERSION := 2
const LEGACY_COLOR := Color("dae0ea")
const MAX_ENTRIES := 3
const MAX_NAME_BYTES := 256
const MAX_FILE_BYTES := 1024
var save_path: String = "user://scoreboard.dat"
var last_save_error: Error = OK
var _entries: Array[Dictionary] = []

func _ready() -> void:
	load_scores()

func get_entries() -> Array[Dictionary]:
	return _entries.duplicate(true)

func get_best_score() -> int:
	return int(_entries[0]["score"]) if not _entries.is_empty() else 0

func submit_run(robot_name: String, score: int, life_seconds: float, robot_color: Color = LEGACY_COLOR) -> bool:
	if not _valid_entry(robot_name, score, life_seconds):
		return false
	var entry := {"name": robot_name, "score": score, "life_seconds": life_seconds, "color": robot_color.to_rgba32()}
	# Empate exato mantém as vidas que já estavam no placar.
	var index := 0
	while index < _entries.size() and not _better(entry, _entries[index]):
		index += 1
	if index >= MAX_ENTRIES:
		return false
	_entries.insert(index, entry)
	_entries.resize(mini(_entries.size(), MAX_ENTRIES))
	last_save_error = save_scores()
	if last_save_error != OK:
		push_warning("Não foi possível salvar o placar; os resultados continuam disponíveis nesta sessão.")
	changed.emit()
	return true

func load_scores() -> void:
	var result := _read_file(save_path)
	if not result["valid"]:
		result = _read_file(save_path + ".bak")
	_entries.clear()
	if result["valid"]:
		for entry in result["entries"]:
			_entries.append(entry)
		_entries.sort_custom(_better)
	changed.emit()

func save_scores() -> Error:
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(MAGIC.to_ascii_buffer())
	file.store_16(VERSION)
	file.store_8(_entries.size())
	for entry in _entries:
		var name_bytes: PackedByteArray = entry["name"].to_utf8_buffer()
		file.store_16(name_bytes.size())
		file.store_buffer(name_bytes)
		file.store_32(entry["score"])
		file.store_double(entry["life_seconds"])
		file.store_32(entry["color"])
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	if not _read_file(temporary)["valid"]:
		return ERR_FILE_CORRUPT
	# Nunca substituir um backup válido por um arquivo principal corrompido.
	if _read_file(save_path)["valid"]:
		error = DirAccess.copy_absolute(save_path, save_path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, save_path)

func _read_file(path: String) -> Dictionary:
	var invalid := {"valid": false, "entries": []}
	if not FileAccess.file_exists(path):
		return invalid
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return invalid
	var size := file.get_length()
	if size < 7 or size > MAX_FILE_BYTES:
		return invalid
	if file.get_buffer(4).get_string_from_ascii() != MAGIC:
		return invalid
	var version := file.get_16()
	if version != 1 and version != VERSION:
		return invalid
	var count := file.get_8()
	if count > MAX_ENTRIES:
		return invalid
	var entries: Array[Dictionary] = []
	for i in range(count):
		if size - file.get_position() < 2:
			return invalid
		var length := file.get_16()
		if length < 1 or length > MAX_NAME_BYTES or size - file.get_position() < length + (16 if version >= 2 else 12):
			return invalid
		var bytes := file.get_buffer(length)
		var robot_name := bytes.get_string_from_utf8()
		if robot_name.to_utf8_buffer() != bytes:
			return invalid
		var score := file.get_32()
		var seconds := file.get_double()
		var color := file.get_32() if version >= 2 else LEGACY_COLOR.to_rgba32()
		if not _valid_entry(robot_name, score, seconds):
			return invalid
		entries.append({"name": robot_name, "score": score, "life_seconds": seconds, "color": color})
	if file.get_position() != size or file.get_error() != OK:
		return invalid
	return {"valid": true, "entries": entries}

func _valid_entry(robot_name: String, score: int, seconds: float) -> bool:
	return not robot_name.strip_edges().is_empty() and robot_name.to_utf8_buffer().size() <= MAX_NAME_BYTES \
		and not "\n" in robot_name and not "\r" in robot_name and not "\t" in robot_name \
		and score >= 0 and score <= 4294967295 and is_finite(seconds) and seconds >= 0.0

func _better(a: Dictionary, b: Dictionary) -> bool:
	return a["score"] > b["score"] or (a["score"] == b["score"] and a["life_seconds"] > b["life_seconds"])
