extends Node
class_name LuaInstance


const REGISTRY_SELF_KEY := "lua_instance"

var project: Project
var owner_peer_id := 0

var is_halted: bool
var is_on_server: bool
var thread: Thread


@onready var vm: LuauVM = $LuauVM
@onready var entity_component: EntityComponent = $EntityComponent


func _ready() -> void:
	is_on_server = multiplayer.is_server()
	
	_insert_self()
	LuaEnvironment.apply.call_deferred(vm)
	_connect_stdout.call_deferred()


func _process(delta: float) -> void:
	if is_halted: return
	vm.lua_pushnumber(delta)
	if LuaUtils.invoke_event_at_path(vm, "Engine.onProcess", 1, 0) == ERR_SCRIPT_FAILED:
		_stderr("Engine.onProcess: " + vm.lua_tostring(-1))
		vm.lua_pop()
		halt()


func _physics_process(delta: float) -> void:
	if is_halted: return
	vm.lua_pushnumber(delta)
	if LuaUtils.invoke_event_at_path(vm, "Engine.onPhysicsProcess", 1, 0) == ERR_SCRIPT_FAILED:
		_stderr("Engine.onPhysicsProcess: " + vm.lua_tostring(-1))
		vm.lua_pop()
		halt()


func _insert_self() -> void:
	vm.lua_pushobject(self)
	vm.lua_setfield(LuauVM.LUA_REGISTRYINDEX, REGISTRY_SELF_KEY)
	LuaEnvironment.vm_to_instance[vm] = self


func _connect_stdout() -> void:
	vm.stdout.connect(self._stdout)


func run() -> void:
	var meta := project.metadata
	var main_file_maybe = meta.get("main_file", "main.lua")
	if !(main_file_maybe is String): return # Bad "main_file" key
	var main_file: String = main_file_maybe
	if !project.map.has(main_file): return # Missing main file
	var main_bytes_maybe = project.map[main_file]
	if !(main_bytes_maybe is PackedByteArray): return # ?
	var main_bytes: PackedByteArray = main_bytes_maybe
	var code := main_bytes.get_string_from_utf8()
	if code.is_empty(): return # Empty main file
	
	#thread = Thread.new()
	#thread.start(self.run_code.bind(code, main_file))
	run_code(code, main_file)


func run_code(code: String, main_file: String) -> void:
	var status := vm.do_string(code, "@%s" % main_file)
	if status != LuauVM.LUA_OK:
		var error_message := vm.lua_tostring(1)
		_stderr(error_message)
		halt()
	vm.lua_settop(0)


func halt() -> void:
	is_halted = true


func receive_project(project_: Project) -> void:
	project = project_
	run()


func _stdout(message: String) -> void:
	entity_component.entity_list.console_system.push_stdout(owner_peer_id, message)


func _stderr(message: String) -> void:
	entity_component.entity_list.console_system.push_stderr(owner_peer_id, message)


func _on_luau_vm_interrupt() -> void:
	pass
	#print("interrupt! :D")
