extends Node
class_name LuaLibrary


@export var global: bool = true
@export var name_override: String


func include(vm: LuauVM) -> bool:
	return _include(vm)


func _include(vm: LuauVM) -> bool:
	return false
