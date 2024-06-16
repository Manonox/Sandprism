extends Node


const _package_library := {
	loaded = {},
	path = "?.lua;?/init.lua;lib/?.lua;lib/?/init.lua",
}


func apply(vm: LuauVM, keep_package: bool = false) -> void:
	if !keep_package:
		vm.lua_pushdictionary(_package_library)
		vm.lua_setglobal("package")
	
	vm.lua_pushcallable(self._require, "require")
	vm.lua_setglobal("require")


func add_package(vm: LuauVM, key: String) -> void:
	assert(vm.lua_gettop() >= 1, "LuaEnvironment: push a value to vm before calling add_package")
	assert(not vm.lua_isnoneornil(-1), "LuaEnvironment: push a value to vm before calling add_package")
	vm.lua_getglobal("package")
	assert(vm.lua_istable(-1), "LuaEnvironment: package library is missing")
		
	vm.lua_getfield(-1, "loaded")
	assert(vm.lua_istable(-1), "LuaEnvironment: bad package.loaded")
	
	vm.lua_pushvalue(-3)
	vm.lua_setfield(-2, key)
	vm.lua_pop(3)


func _require(vm: LuauVM) -> int:
	var raw_path := vm.luaL_checkstring(1)
	var path := _normalize_require_path(raw_path)
	
	vm.luaL_argcheck(not path.is_empty(), 1, "incorrect require path")
	
	vm.lua_getglobal("package") # []
	if not vm.lua_istable(-1):
		vm.luaL_error("package library is missing")
		# interrupt
		
	vm.lua_getfield(-1, "path") # [package]
	if not vm.lua_isstring(-1):
		vm.luaL_error("bad package.path")
		
	var package_path := vm.lua_tostring(-1)
	vm.lua_pop(1) # [package, package.path]
	
	vm.lua_getfield(-1, "loaded") # [package]
	if not vm.lua_istable(-1):
		vm.luaL_error("bad package.loaded")
	
	vm.lua_getfield(-1, raw_path) # [package, package.loaded]
	if not vm.lua_isnil(-1):
		vm.lua_remove(-2) # [package, package.loaded, package.loaded[path]]
		vm.lua_remove(-2) # [package, package.loaded[path]]
		return 1 # [package.loaded[path]]
	vm.lua_pop() # [package, package.loaded, nil]
	
	var search_paths := _expand_package_path(package_path, path)
	if search_paths.size() == 0:
		vm.luaL_error("empty require path")
		# interrupt
	
	vm.luaL_error("require is currently disabled")
	
	#for path in search_paths:
		#var full_path : String = vm.require_dir + "/" + path
		#if not full_path.is_absolute_path():
			#continue
		#var file := FileAccess.open(full_path, FileAccess.READ)
		#if file == null:
			#continue
			#
		#var contents := file.get_as_text()
		#
		#var status := vm.lua_loadstring(contents, "@" + path) # [package, package.loaded]
		#if status != vm.LUA_OK:
			#vm.lua_error()
			## interrupt
			#
		#status = vm.lua_pcall(0, 1, 0) # [package, package.loaded, <loadstring>]
		#if status != vm.LUA_OK:
			#vm.lua_error()
			## interrupt
		#
		#if vm.lua_isnil(-1): # [package, package.loaded, <require_result or nil>]
			#vm.lua_pop() # [package, package.loaded, <require_result or nil>]
			#vm.lua_pushboolean(true) # [package, package.loaded]
			#
		#vm.lua_pushvalue(-1) # [package, package.loaded, <require_result>]
		#vm.lua_setfield(-3, raw_path) # [package, package.loaded, <require_result>, <require_result>]
		#vm.lua_remove(-2) # [package, package.loaded, <require_result>]
		#vm.lua_remove(-2) # [package, <require_result>]
		#return 1 # [<require_result>]
	#
	#vm.luaL_error("can't find file %s (%d paths checked)" % [raw_path, search_paths.size()])
	# interrupt
	return 0


func _expand_package_path(package_path: String, subs: String) -> Array:
	var paths := package_path.split(";", false, 32)
	for i in range(paths.size()):
		paths[i] = paths[i].replace("?", subs)
	return paths


func _normalize_require_path(s: String) -> String:
	s = s.to_lower()
	
	var ends_with_dotlua := s.ends_with(".lua")
	var is_modern := s.find("/") != -1 or ends_with_dotlua
	if not is_modern and ends_with_dotlua:
		return ""
	
	if not is_modern:
		return s.replace(".", "/")
	
	if s.find("..") != -1 or s.find(":") != -1:
		return ""
	
	if ends_with_dotlua:
		s = s.left(-4)
	return s
