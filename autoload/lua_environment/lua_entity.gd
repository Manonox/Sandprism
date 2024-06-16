extends Node
class_name LuaEntity


@export var mixins : Array[StringName] = []
@export var spawnable : bool = false
@export var constructor_ignores_library : bool = true


var mixin_set := {}


func _ready() -> void:
	for mixin in mixins:
		mixin_set[mixin] = true 


func construct(vm: LuauVM) -> int:
	if not spawnable:
		vm.luaL_error("%s is not spawnable" % name)
	
	if constructor_ignores_library and vm.lua_gettop() >= 1:
		vm.lua_remove(1)
	_construct(vm)
	return 1

func include(vm: LuauVM) -> void:
	_include(vm)

func metatable(vm: LuauVM) -> void:
	_metatable(vm)

func extend_library(vm: LuauVM) -> void:
	_extend_library(vm)


func _construct(vm: LuauVM) -> void:
	pass

func _include(vm: LuauVM) -> void:
	pass

func _metatable(vm: LuauVM) -> void:
	pass

func _extend_library(vm: LuauVM) -> void:
	pass
