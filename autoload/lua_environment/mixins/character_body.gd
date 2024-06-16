extends LuaMixin


var _character_body := {
	setVelocity = self._set_velocity,
	getVelocity = self._get_velocity,
}


func _include(vm: LuauVM) -> void:
	LuaUtils.merge_dictionary(vm, _character_body)


func _set_velocity(vm: LuauVM) -> int:
	var character_body := LuaEnvironment.entity.export_mixin(vm, &"CharacterBody", 1) as CharacterBody3D
	var velocity := LuaEnvironment.vector3.export(vm, 2) as Vector3
	character_body.velocity = velocity
	return 0

func _get_velocity(vm: LuauVM) -> int:
	var character_body := LuaEnvironment.entity.export_mixin(vm, &"CharacterBody", 1) as CharacterBody3D
	LuaEnvironment.vector3.import(vm, character_body.velocity, false)
	return 1
