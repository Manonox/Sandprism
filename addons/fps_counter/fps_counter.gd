extends Label



func _process(_delta: float) -> void:
	text = "FPS: {0}".format([Engine.get_frames_per_second()])
