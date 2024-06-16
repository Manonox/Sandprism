extends Node
class_name LuaEnv


var vm_to_instance := {}


@onready var ravenmind: LuauVM = $"LuauVM (Ravenmind)"

@onready var override_typeof: Node = $OverrideTypeof
@onready var init_require: Node = $InitRequire
@onready var require: Node = $Require


@onready var types: Node = $Types
@onready var mixins: Node = $Mixins
@onready var entities: Node = $Entities
@onready var libraries: LuaLibraries = $Libraries

@onready var entity: LuaEntities = $Entities as LuaEntities

@onready var vector2: LuaType = $Types/Vector2
@onready var vector3: LuaType = $Types/Vector3
@onready var vector4: LuaType = $Types/Vector4
@onready var color: LuaType = $Types/Color
@onready var angle: LuaType = $Types/Angle


func _ready() -> void:
	pass
	#ravenmind.stdout.connect(self._print)
	#apply(ravenmind)


func _print(message: String) -> void:
	print("Lua says: ", message)


func apply(vm: LuauVM) -> void:
	vm.stdout.connect(self._debug_print)
	vm.open_all_libraries()
	override_typeof.apply(vm)
	init_require.apply(vm)
	run_file(vm, "init.lua")
	require.apply(vm)
	libraries.load_libraries(vm)
	entities.load_entity_libraries(vm)
	init_require.apply(vm)
	run_file(vm, "post_init.lua")
	require.apply(vm, true)
	vm.stdout.disconnect(self._debug_print)


func get_lua_instance(vm: LuauVM) -> LuaInstance:
	return vm_to_instance[vm]
	#vm.lua_getfield(LuauVM.LUA_REGISTRYINDEX, LuaInstance.REGISTRY_SELF_KEY)
	#if vm.lua_isnoneornil(-1): return null
	#if !vm.lua_isvalidobject(-1): return null
	#var lua_instance := vm.lua_toobject(-1) as LuaInstance
	#vm.lua_pop()
	#return lua_instance


func run_file(vm: LuauVM, path: String) -> void:
	var code := FileAccess.open("res://lua/" + path, FileAccess.READ).get_as_text(true)
	var status := vm.do_string(code, "@lua/" + path)
	assert(status == vm.LUA_OK, vm.lua_tostring(-1))
	vm.lua_settop(0)


func _debug_print(message: String) -> void:
	print("[DEBUG] %s" % message)
