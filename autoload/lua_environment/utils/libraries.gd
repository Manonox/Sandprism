extends Node
class_name LuaLibraries


func load_libraries(vm: LuauVM) -> void:
	for library: LuaLibrary in get_children():
		var success := library.include(vm)
		if !success:
			continue
		
		var library_name := library.name
		if !library.name_override.is_empty():
			library_name = library.name_override
		
		if library.global:
			vm.lua_setglobal(library_name)
		else:
			LuaEnvironment.require.add_package(vm, library_name)
