extends LuaType


func _import(vm: LuauVM, v: Vector2, protected: bool) -> bool:
	if !LuaUtils.index_at_path(vm, "Vector2.new"):
		return false
	if vm.lua_type(-1) != LuauVM.LUA_TFUNCTION:
		return false
	vm.lua_pushnumber(v.x)
	vm.lua_pushnumber(v.y)
	if protected:
		if vm.lua_pcall(2, 1) != LuauVM.LUA_OK:
			return false
	else:
		vm.lua_call(2, 1)
	return true


func _is_type(vm: LuauVM, index: int) -> bool:
	if vm.lua_type(index) != vm.LUA_TTABLE:
		return false
	vm.lua_getfield(index, "__base")
	if !vm.lua_isvector(-1):
		vm.lua_pop()
		return false
	vm.lua_pop()
	
	vm.lua_getfield(index, "__size")
	if !vm.lua_isnumber(-1):
		vm.lua_pop()
		return false
	if !is_equal_approx(vm.lua_tonumber(-1), 2.0):
		vm.lua_pop()
		return false
	vm.lua_pop()
	return true


func _check(vm: LuauVM, index: int) -> void:
	if vm.lua_type(index) != vm.LUA_TTABLE:
		vm.luaL_typerror(index, "Vector2")
	vm.lua_getfield(index, "__size")
	if !vm.lua_isnumber(-1):
		vm.luaL_argcheck(false, index, "malformed Vector2 argument #%s" % index)
	if !is_equal_approx(vm.lua_tonumber(-1), 2.0):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Vector2, got %s)" % [index, LuaUtils.godot_typeof(vm, index)])
	vm.lua_pop()
	vm.lua_getfield(index, "__base")
	if !vm.lua_isvector(-1):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Vector2, got table)" % index)
	vm.lua_pop()


func _export(vm: LuauVM, index: int) -> Vector2:
	_check(vm, index)
	vm.lua_getfield(index, "__base")
	var v := vm.lua_tovector(-1)
	vm.lua_pop()
	return Vector2(v.x, v.y)
