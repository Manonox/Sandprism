extends Node


func apply(vm: LuauVM) -> void:
	vm.lua_pushcallable(self._typeof, "typeof")
	vm.lua_setglobal("typeof")


func _typeof(vm: LuauVM) -> int:
	vm.lua_pushstring(LuaUtils.godot_typeof(vm, 1))
	return 1
