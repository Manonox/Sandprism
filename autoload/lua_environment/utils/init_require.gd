extends Node


func apply(vm: LuauVM) -> void:
	vm.lua_pushcallable(self._init_require)
	vm.lua_setglobal("require")


func _init_require(vm: LuauVM) -> int:
	var raw_path := vm.luaL_checkstring(1)
	var path := _normalize_require_path(raw_path)
	vm.luaL_argcheck(not raw_path.is_empty(), 1, "incorrect require path")
		
	var full_path : String = "res://lua/" + path + ".lua"
	vm.luaL_argcheck(full_path.is_absolute_path(), 1, "non-absolute path require path")
	
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		full_path = "res://lua/" + path + "/init.lua"
		file = FileAccess.open(full_path, FileAccess.READ)
	
	vm.luaL_argcheck(file != null, 1, "can't find file \"%s\"" % raw_path)
		
	var contents := file.get_as_text()
	var status := vm.lua_loadstring(contents, "@lua/" + path)
	if status != vm.LUA_OK:
		vm.lua_error()
	
	status = vm.lua_pcall(0, 1, 0)
	if status != vm.LUA_OK:
		vm.lua_error()
	
	return 1


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
