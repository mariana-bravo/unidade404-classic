extends Node
## CENA DE TESTE do VisorHud. Não faz parte do jogo final.
## S +10 pontos · L próximo nível · B recorde +100 · C troca a cor da unidade
## Q tempo -1 · W tempo +1 · ESPAÇO liga/desliga a descida automática do tempo

const CORES = [
	Color(0.55, 0.80, 1.00),   # azul
	Color(0.60, 1.00, 0.60),   # verde
	Color(1.00, 0.90, 0.40),   # amarelo
	Color(0.80, 0.65, 1.00),   # roxo
	Color(0.50, 1.00, 0.95),   # ciano
	Color(0.88, 0.90, 0.95),   # cinza claro
]

var hud: VisorHud
var score: int = 0
var best: int = 0
var level: int = 1
var time: float = 10.0
var auto_drain: bool = false
var color_index: int = 0


func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.15, 0.15, 0.18)
	fundo.size = Vector2(320, 180)
	add_child(fundo)

	hud = preload("res://scenes/visor_hud.tscn").instantiate() as VisorHud
	add_child(hud)
	hud.set_robot("Estagiário Desempregado", 1)
	hud.set_tint(CORES[color_index])


func _process(delta: float) -> void:
	if auto_drain:
		time = maxf(time - delta, 0.0)
		hud.set_time(time)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_S:
				score += 10
				hud.set_score(score)
			KEY_L:
				level += 1
				hud.set_level(level)
			KEY_B:
				best += 100
				hud.set_best(best)
			KEY_C:
				color_index = (color_index + 1) % CORES.size()
				hud.set_tint(CORES[color_index])
			KEY_Q:
				time = maxf(time - 1.0, 0.0)
				hud.set_time(time)
			KEY_W:
				time = minf(time + 1.0, 10.0)
				hud.set_time(time)
			KEY_SPACE:
				auto_drain = not auto_drain
