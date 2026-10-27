class_name TimeModel
extends RefCounted
## Modelo de tempo do jogo (GDD seção 6.2).
## Só tem funções puras: não é nó, não tem cena e não guarda estado.
## Por isso dá para testar só com print.

const Settings = preload("res://scripts/autoload/config.gd")

enum SlotKind { NAIL, SCREW, BAD_NAIL, RUSTY_SCREW }

# --- Constantes de leitura de clique (GDD seção 3.4) ---
const TOQUE := 0.10
const INTERVALO_DUPLO := 0.12
const JANELA_DUPLO := Settings.JANELA_DUPLO
const TEMPO_APARAFUSAR := Settings.TEMPO_APARAFUSAR
const TRAVA_POS_ACAO := Settings.TRAVA_POS_ACAO

# --- Tempos de reação humana (GDD seção 6.2). Validar em playtest. ---
const REACAO_ESCOLHA := 0.45
const REACAO_SIMPLES := 0.25

# --- Duração mecânica de cada gesto ---
const CLIQUE_SIMPLES := TOQUE + JANELA_DUPLO                # 0,38 s
const DUPLO_CLIQUE := TOQUE + INTERVALO_DUPLO + TOQUE       # 0,32 s

# --- Progressão (GDD seção 7) ---
const PECAS_POR_NIVEL := 5
const NIVEL_TETO := 6
const MARGENS = [2.5, 2.2, 1.9, 1.7, 1.5, 1.3]
const MARGEM_QUEDA_POR_PECA := 0.01
const MARGEM_PISO := 1.10


## Tempo mínimo que uma pessoa precisa para fazer o slot sem hesitar.
static func t_min(kind: int) -> float:
	match kind:
		SlotKind.NAIL:
			return REACAO_ESCOLHA + CLIQUE_SIMPLES + CLIQUE_SIMPLES + TRAVA_POS_ACAO
		SlotKind.SCREW:
			return REACAO_ESCOLHA + DUPLO_CLIQUE + TEMPO_APARAFUSAR + TRAVA_POS_ACAO
		SlotKind.BAD_NAIL:
			return REACAO_ESCOLHA + CLIQUE_SIMPLES + DUPLO_CLIQUE + REACAO_SIMPLES \
				+ CLIQUE_SIMPLES + TRAVA_POS_ACAO
		SlotKind.RUSTY_SCREW:
			return REACAO_ESCOLHA + DUPLO_CLIQUE + CLIQUE_SIMPLES + TEMPO_APARAFUSAR \
				+ REACAO_SIMPLES + TEMPO_APARAFUSAR + TRAVA_POS_ACAO
	push_error("TimeModel.t_min: tipo de slot desconhecido: %s" % kind)
	return 0.0


## Nível atual: sobe a cada 5 peças concluídas e para no teto (nível 6).
static func nivel(pecas_concluidas: int) -> int:
	var n := 1 + floori(float(pecas_concluidas) / PECAS_POR_NIVEL)
	return mini(n, NIVEL_TETO)


## Margem de folga: cai a cada nível. Depois do teto, cai devagar até o piso.
static func margem(pecas_concluidas: int) -> float:
	var n := nivel(pecas_concluidas)
	if n < NIVEL_TETO:
		return float(MARGENS[n - 1])
	var pecas_no_teto := pecas_concluidas - (NIVEL_TETO - 1) * PECAS_POR_NIVEL
	var m: float = float(MARGENS[NIVEL_TETO - 1]) - MARGEM_QUEDA_POR_PECA * pecas_no_teto
	return maxf(m, MARGEM_PISO)


## Segundos que a barra ganha ao concluir um slot.
static func tempo_concedido(kind: int, pecas_concluidas: int, tempo_esteira: float = 0.0) -> float:
	var automatico := 0.0
	if kind == SlotKind.BAD_NAIL or kind == SlotKind.RUSTY_SCREW:
		automatico = Settings.TEMPO_SUBSTITUICAO
	# Recompensa fixa por tipo: tentativas e hesitação não aumentam o bônus.
	return t_min(kind) * margem(pecas_concluidas) + automatico + maxf(0.0, tempo_esteira)
