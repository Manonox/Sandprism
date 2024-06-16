extends Node
class_name LuaType



func import(vm: LuauVM, v, protected: bool) -> bool:
	return _import(vm, v, protected)

func _import(vm: LuauVM, v, protected: bool) -> bool:
	return false


func is_type(vm: LuauVM, index: int) -> bool:
	return _is_type(vm, index)

func _is_type(vm: LuauVM, index: int) -> bool:
	return false


func check(vm: LuauVM, index: int) -> void:
	_check(vm, index)

func _check(vm: LuauVM, index: int) -> void:
	pass


func export(vm: LuauVM, index: int):
	return _export(vm, index)
	
func export_or(vm: LuauVM, index: int, default):
	if vm.lua_isnoneornil(index):
		return default
	return _export(vm, index)

func _export(vm: LuauVM, index: int):
	pass

