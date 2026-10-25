extends Control
var held: bool = false
var elapsed: float = 0.0
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        get_viewport().set_input_as_handled()
        held = event.pressed
        if held:
            elapsed = 0.0
func _process(delta: float) -> void:
    if held:
        elapsed += delta
        if elapsed >= Config.MENU_SEGURAR:
            held = false
            get_tree().change_scene_to_file("res://scenes/menu.tscn")
