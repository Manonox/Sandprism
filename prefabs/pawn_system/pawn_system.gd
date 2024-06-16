extends Node
class_name PawnSystem


@export var player_pawn_entity: EntityListEntity

@export_group("Links")
@export var entity_list: EntityList
@export var subspace_manager: SubspaceManager


var peer_pawns := {}
var client_local_pawn: PawnComponent


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(self._server_peer_connected)
		multiplayer.peer_disconnected.connect(self._server_peer_disconnected)


func _server_peer_connected(peer_id: int) -> void:
	await get_tree().create_timer(0.1).timeout
	var overworld : Subspace = subspace_manager.get_subspace_by_id(0)
	var player_pawn := overworld.spawn_entity(player_pawn_entity)
	player_pawn.position = Vector3(randf_range(-2.0, 2.0), 2.0, 0.0)
	var entity_component := player_pawn.get_node(^"EntityComponent") as EntityComponent
	server_possess.call_deferred(peer_id, overworld, entity_component.index)


func _server_peer_disconnected(peer_id: int) -> void:
	peer_pawns.erase(peer_id)


func server_possess(peer_id: int, subspace: Subspace, index: int) -> void:
	assert(multiplayer.is_server())
	var command := EntityListCommand.new(EntityListCommand.COMMAND_POSSESS_ENTITY, [subspace.id, index])
	entity_list.push_command(peer_id, EntityList.STAGE_ENTITY, command)
	
	var entity_component := subspace.get_entity_component_by_index(index)
	var entity: Node3D = entity_component.get_parent()
	var pawn_component := entity.get_node(^"PawnComponent") as PawnComponent
	assert(!pawn_component.server_is_possessed())
	
	peer_pawns[peer_id] = pawn_component
	pawn_component.server_current_peer_id = peer_id
	pawn_component.peer_changed.emit(peer_id)

func client_possess(subspace: Subspace, index: int) -> void:
	assert(!multiplayer.is_server())
	var entity_component := subspace.get_entity_component_by_index(index)
	var entity := entity_component.get_parent()
	var pawn_component := entity.get_node(^"PawnComponent") as PawnComponent
	
	peer_pawns[multiplayer.get_unique_id()] = pawn_component
	if client_local_pawn != null:
		client_local_pawn.client_is_local_pawn = false
		client_local_pawn.peer_changed.emit(0)
	client_local_pawn = pawn_component
	client_local_pawn.client_is_local_pawn = true
	client_local_pawn.peer_changed.emit(multiplayer.get_unique_id())
	entity_list.subspace_manager.view_subspace(subspace)
