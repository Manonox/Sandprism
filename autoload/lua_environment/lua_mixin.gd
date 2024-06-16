extends Node
class_name LuaMixin


func export(vm: LuauVM, index: int) -> Node:
	return LuaEnvironment.entity.export_mixin(vm, name, index)


func include(vm: LuauVM) -> void:
	_include(vm)


func _include(vm: LuauVM) -> void:
	pass
