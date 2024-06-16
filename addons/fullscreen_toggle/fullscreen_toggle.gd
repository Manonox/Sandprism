extends Node


var preferred_fullscreen_mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen_toggle"):
		var is_fullscreen := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN]
		var mode := DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else preferred_fullscreen_mode
		DisplayServer.window_set_mode(mode)
