extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var conveyor = load("res://scenes/conveyor.tscn").instantiate()
	conveyor.demo_mode = false
	root.add_child(conveyor)
	var kinds: Array[int] = []
	for count in range(1, 5):
		kinds.append(count - 1)
		conveyor.set_slots(kinds)
		assert(conveyor.slot_visuals.size() == count)
		var expected := 8.0 + (count - 1) * 2.0
		var previous_right := -100.0
		for slot in conveyor.slot_visuals:
			expected += slot.size.x
			assert(slot.position.y == -10.0)
			assert(slot.position.x > previous_right)
			previous_right = slot.position.x
		assert(conveyor.get_board_width() == expected)
		assert(conveyor.slots_container.get_child_count() == count * 2 + 1)
		conveyor.update_slot_progress(count)
		for slot in conveyor.slot_visuals:
			assert(slot.completed and not slot.active)
	kinds.assign([2, 3])
	conveyor.set_slots(kinds)
	var width: float = conveyor.get_board_width()
	for index in range(2):
		conveyor.show_empty(index)
		assert(conveyor.slot_visuals[index].empty)
		conveyor.show_replacement(index)
		assert(not conveyor.slot_visuals[index].empty)
		assert(conveyor.slot_visuals[index].replaced)
		assert(conveyor.slot_visuals[index].kind == index + 2)
	assert(conveyor.get_board_width() == width)
	await process_frame
	conveyor.queue_free()
	await process_frame
	print("PASS: caixas de 1 a 4 slots, ordem, limpeza, estados e largura da substituicao")
	quit()
