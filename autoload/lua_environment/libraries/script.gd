extends LuaLibrary


var _script_library := {
	isClient = self._is_client,
	isServer = self._is_server,
	
	getOwner = self._get_owner,
	getOwnerId = self._get_owner_id,
}


func _include(vm: LuauVM) -> bool:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	if lua_instance == null: return false
	vm.lua_pushdictionary(_script_library)
	
	if !lua_instance.is_on_server:
		vm.lua_pushcallable(self._get_client_id, "getClientId")
		vm.lua_setfield(-2, "getClientId")
	return true


func _is_client(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	vm.lua_pushboolean(!lua_instance.is_on_server)
	return 1


func _is_server(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	vm.lua_pushboolean(lua_instance.is_on_server)
	return 1


func _get_owner(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	var peer_id := lua_instance.owner_peer_id
	var pawn_component: PawnComponent = lua_instance.entity_component.entity_list.pawn_system.peer_pawns.get(peer_id)
	if pawn_component == null:
		vm.lua_pushnil()
		return 1
	var pawn := pawn_component.get_parent()
	LuaEnvironment.entity.import(vm, pawn)
	return 1


func _get_owner_id(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	vm.lua_pushnumber(lua_instance.owner_peer_id)
	return 1


func _get_client(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	var peer_id := lua_instance.multiplayer.get_unique_id()
	var pawn_component: PawnComponent = lua_instance.entity_component.entity_list.pawn_system.peer_pawns.get(peer_id)
	if pawn_component == null:
		vm.lua_pushnil()
		return 1
	var pawn := pawn_component.get_parent()
	LuaEnvironment.import(vm, pawn)
	return 1


func _get_client_id(vm: LuauVM) -> int:
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	vm.lua_pushnumber(lua_instance.multiplayer.get_unique_id())
	return 1
