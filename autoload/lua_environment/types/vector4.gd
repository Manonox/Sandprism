extends LuaType


func _import(vm: LuauVM, v: Vector4, protected: bool) -> bool:
	if !LuaUtils.index_at_path(vm, "Vector4.new"):
		return false
	if vm.lua_type(-1) != LuauVM.LUA_TFUNCTION:
		return false
	vm.lua_pushnumber(v.x)
	vm.lua_pushnumber(v.y)
	vm.lua_pushnumber(v.z)
	vm.lua_pushnumber(v.w)
	if protected:
		if vm.lua_pcall(4, 1) != LuauVM.LUA_OK:
			return false
	else:
		vm.lua_call(4, 1)
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
	if !is_equal_approx(vm.lua_tonumber(-1), 4.0):
		vm.lua_pop()
		return false
	vm.lua_pop()
	return true


func _check(vm: LuauVM, index: int) -> void:
	if vm.lua_type(index) != vm.LUA_TTABLE:
		vm.luaL_typerror(index, "Vector4")
	vm.lua_getfield(index, "__size")
	if !vm.lua_isnumber(-1):
		vm.luaL_argcheck(false, index, "malformed Vector4 argument #%s" % index)
	if !is_equal_approx(vm.lua_tonumber(-1), 4.0):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Vector4, got %s)" % [index, LuaUtils.godot_typeof(vm, index)])
	vm.lua_pop()
	vm.lua_getfield(index, "__base")
	if !vm.lua_isvector(-1):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Vector4, got table)" % index)
	vm.lua_pop()


func _export(vm: LuauVM, index: int) -> Vector4:
	_check(vm, index)
	vm.lua_getfield(index, "__base")
	var v := vm.lua_tovector(-1)
	vm.lua_pop()
	return v
