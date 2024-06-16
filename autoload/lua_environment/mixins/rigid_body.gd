extends LuaMixin


var _rigid_body := {
	setVelocity = self._set_velocity,
	getVelocity = self._get_velocity,
}


func _include(vm: LuauVM) -> void:
	LuaUtils.merge_dictionary(vm, _rigid_body)


func _set_velocity(vm: LuauVM) -> int:
	var node: Node = export(vm, 1)
	assert(node is RigidBody3D, "RigidBody mixin requires RigidBody3D")
	var rigidbody := node as RigidBody3D
	
	var velocity: Vector3 = LuaEnvironment.vector3.export(vm, 2)
	rigidbody.linear_velocity = velocity
	return 0

func _get_velocity(vm: LuauVM) -> int:
	var node: Node = export(vm, 1)
	assert(node is RigidBody3D, "RigidBody mixin requires RigidBody3D")
	var rigidbody := node as RigidBody3D
	
	LuaEnvironment.vector3.import(vm, rigidbody.linear_velocity, false)
	return 1
