extends Control


@export_flags("Left", "Right", "Middle") var button_mask: int

func _gui_input(event):
	if event is InputEventMouseButton:
		var i : int = 2 ** (event.button_index - 1)
		if i & button_mask > 0:
			capture()
			get_viewport().set_input_as_handled()


func capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("mouse_release"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
