class_name BoardGenerator
extends Node

# Sorteador próprio deste componente.
var rng := RandomNumberGenerator.new()

# Gera uma peça de acordo com o nível.
func generate_board(level: int) -> Array[int]:
	var slots: Array[int] = []

	var quantity := _choose_slot_count(level)
	var defect_chance := _get_defect_chance(level)

	for i in range(quantity):
		# Sorteia se o slot será prego ou parafuso.
		var is_screw := rng.randf() < 0.5

		# Sorteia independentemente se terá defeito.
		var is_defective := rng.randf() < defect_chance

		var slot_kind: int

		if is_screw:
			if is_defective:
				slot_kind = InteractionController.SlotKind.RUSTY_SCREW
			else:
				slot_kind = InteractionController.SlotKind.SCREW
		else:
			if is_defective:
				slot_kind = InteractionController.SlotKind.BAD_NAIL
			else:
				slot_kind = InteractionController.SlotKind.NAIL

		slots.append(slot_kind)

	return slots

# Sorteia a quantidade de slots usando pesos.
func _choose_slot_count(level: int) -> int:
	var roll := rng.randf()

	if level <= 1:
		return 1

	if level == 2:
		return 1 if roll < 0.70 else 2

	if level == 3:
		return 2

	if level == 4:
		return 2 if roll < 0.60 else 3

	if level == 5:
		return 3 if roll < 0.40 else 4

	return 4

# Determina a chance de defeito de cada slot.
func _get_defect_chance(level: int) -> float:
	if level <= 2:
		return 0.0

	if level == 3:
		return 0.15

	if level == 4:
		return 0.25

	if level == 5:
		return 0.30

	return 0.35

func _ready() -> void:
	for level in range(1, 7):
		var board := generate_board(level)
		print("Nível ", level, ": ", board)
