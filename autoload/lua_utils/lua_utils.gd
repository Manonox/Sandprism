extends RefCounted
class_name LuaUtils


static func merge(vm: LuauVM) -> void:
	vm.lua_pushnil() # [t1, t2]
	while vm.lua_next(-2): # [t1, t2, nil]
		vm.lua_pushvalue(-2) # [t1, t2, k, v]
		vm.lua_insert(-2) # [t1, t2, k, v, k]
		vm.lua_rawset(-5) # [t1, t2, k, k, v]
		# [t1, t2, k]
	# [t1, t2]


static func merge_dictionary(vm: LuauVM, dictionary: Dictionary) -> void:
	vm.lua_pushdictionary(dictionary)
	merge(vm)
	vm.lua_pop()


static func view_stack(vm: LuauVM) -> String:
	var top := vm.lua_gettop()
	if top == 0:
		return ">\t<empty>\n"
	
	var result := ""
	for i in range(top, 0, -1):
		var s := vm.lua_typename(vm.lua_type(i))
		var v = vm.lua_tovariant(i)
		if v != null:
			s += "<%s>" % v
		result += "%s\t%s: %s\n" % [">" if i == top else "", i, s]
	return result


static func godot_typeof(vm: LuauVM, index: int) -> String:
	var type_id : int = vm.lua_type(index)
	if not type_id in [LuauVM.LUA_TTABLE, LuauVM.LUA_TUSERDATA]:
		return vm.lua_typename(type_id)
	
	if not vm.luaL_getmetafield(index, "__type"):
		return vm.lua_typename(type_id)
		
	if vm.lua_type(-1) != LuauVM.LUA_TSTRING:
		vm.lua_pop()
		return vm.lua_typename(type_id)
	var __type := vm.lua_tostring(-1)
	vm.lua_pop()
	return __type


static func index_at_path(vm: LuauVM, path: String) -> bool:
	var keys := path.split(".", false)
	var global_key := keys[0]
	vm.lua_getglobal(global_key)
	for i in range(1, keys.size()):
		if vm.lua_type(-1) != LuauVM.LUA_TTABLE:
			vm.lua_pop()
			return false
		var key := keys[i]
		vm.lua_getfield(-1, key)
		vm.lua_remove(-2)
	return true


static func invoke_event_at_path(vm: LuauVM, path: String, nargs: int, nresults: int) -> Error:
	if !LuaUtils.index_at_path(vm, path): # [..nargs..]
		return ERR_CANT_RESOLVE
	if !vm.lua_istable(-1): # [???, ..nargs.., Event]
		vm.lua_pop(nargs + 1)
		return ERR_CANT_RESOLVE
	vm.lua_insert(-nargs - 1)
	vm.lua_getfield(-nargs - 1, "invoke")  # [???, Event, ..nargs..]
	if !vm.lua_isfunction(-1): # [???, Event, ..nargs.., .invoke]
		vm.lua_pop(nargs + 2)
		return ERR_INVALID_DATA
	vm.lua_insert(-nargs - 2)
	if vm.lua_pcall(nargs + 1, nresults) != LuauVM.LUA_OK:
		return ERR_SCRIPT_FAILED
	return OK
