extends LuaEntity


@export var packed_scene : PackedScene

func _construct(vm: LuauVM) -> void:
	var position : Vector3 = LuaEnvironment.vector3.export(vm, 1)
	var scene := get_tree().current_scene
	var node : Node3D = packed_scene.instantiate()
	scene.add_child(node)
	node.position = position
	LuaEnvironment.entity.import(vm, node)
