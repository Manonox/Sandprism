extends Node
class_name LuaInstanceSystem


const MAX_PROJECT_SIZE := 32 * 1024


@export var lua_instance_scene: PackedScene
@export var entity_list: EntityList


var _project_queue := []


func _ready() -> void:
	if multiplayer.is_server():
		Network.server_packet_received.connect(self._server_packet_received)
	else:
		Network.client_packet_received.connect(self._client_packet_received)


func run_project(peer_id: int, project: Project) -> void:
	var lua_instance := spawn_lua_instance(peer_id)
	var entity_component := lua_instance.get_node(^"EntityComponent") as EntityComponent
	var subspace_id := entity_component.subspace.id
	var lua_instance_index := entity_component.index
	var project_byte_array := project.pack()
	project_byte_array = project_byte_array.compress()
	var array := [subspace_id, lua_instance_index, project_byte_array]
	var byte_array := var_to_bytes(array)
	
	Network.server_tcp_broadcast("lua_instance_project", byte_array)
	lua_instance.receive_project.call_deferred(project)


func spawn_lua_instance(peer_id: int) -> LuaInstance:
	var pawn_component_maybe: PawnComponent = entity_list.pawn_system.peer_pawns.get(peer_id)
	if pawn_component_maybe == null: return
	var pawn_component := pawn_component_maybe as PawnComponent
	var pawn := pawn_component.get_parent()
	var entity_component := pawn.get_node(^"EntityComponent") as EntityComponent
	var subspace := entity_component.subspace
	
	var lua_instance := entity_list.entity_manager.spawn_entity(subspace, &"LuaInstance") as LuaInstance
	lua_instance.owner_peer_id = peer_id
	return lua_instance


func _server_packet_received(peer_id: int, label: String, byte_array: PackedByteArray) -> void:
	if label != "project_run": return
	byte_array = byte_array.decompress(MAX_PROJECT_SIZE)
	var project := Project.unpack(byte_array)
	if project == null: return
	run_project(peer_id, project)


func _client_packet_received(label: String, byte_array: PackedByteArray) -> void:
	if label != "lua_instance_project": return
	var array_maybe = bytes_to_var(byte_array)
	if !(array_maybe is Array): return
	var array := array_maybe as Array
	if !(array[0] is int): return
	if !(array[1] is int): return
	if !(array[2] is PackedByteArray): return
	var subspace_id := array[0] as int
	var lua_instance_index := array[1] as int
	var project_byte_array := array[2] as PackedByteArray
	project_byte_array = project_byte_array.decompress(MAX_PROJECT_SIZE)
	var project := Project.unpack(project_byte_array)
	_project_queue.append([subspace_id, lua_instance_index, project])


func _on_queue_timer_timeout() -> void:
	for i in range(_project_queue.size() - 1, -1, -1):
		var entry: Array = _project_queue[i]
		var subspace := entity_list.subspace_manager.get_subspace_by_id(entry[0])
		if subspace == null: continue
		var entity_component := subspace.get_entity_component_by_index(entry[1])
		if entity_component == null: continue
		var lua_instance := entity_component.get_parent() as LuaInstance
		lua_instance.receive_project(entry[2])
		_project_queue.remove_at(i)
