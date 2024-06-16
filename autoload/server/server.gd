extends SubViewport


var current_scene : Node

func change_scene_to_file(path: String) -> void:
	change_scene_to_packed(load(path))

func change_scene_to_packed(packed_scene: PackedScene) -> void:
	if current_scene != null:
		remove_child(current_scene)
	var node := packed_scene.instantiate()
	add_child(node)
	current_scene = node
