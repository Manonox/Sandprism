extends LuaMixin


var _transform := {
	getPosition = self._get_position,
	setPosition = self._set_position
}


func _include(vm: LuauVM) -> void:
	LuaUtils.merge_dictionary(vm, _transform)


func _get_position(vm: LuauVM) -> int:
	var node: Node = export(vm, 1)
	assert(node is Node3D, "Transform mixin requires Node3D")
	var node3d := node as Node3D
	LuaEnvironment.vector3.import(vm, node3d.position, false)
	return 1


func _set_position(vm: LuauVM) -> int:
	var node: Node = export(vm, 1)
	assert(node is Node3D, "Transform mixin requires Node3D")
	var node3d := node as Node3D
	
	var new_position : Vector3 = LuaEnvironment.vector3.export(vm, 2)
	node3d.position = new_position
	return 0
