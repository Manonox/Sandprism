extends Node
class_name ReplicationSystem


@export_group("Links")
@export var entity_list : EntityList
@export var subspace_manager : SubspaceManager
@export var entity_manager : EntityManager


func _ready() -> void:
	subspace_manager.subspace_created.connect(self._subspace_created)
	subspace_manager.subspace_destroyed.connect(self._subspace_destroyed)

	entity_manager.entity_spawned.connect(self._entity_spawned)
	entity_manager.entity_despawned.connect(self._entity_despawned)
	
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(self._server_peer_connected)


func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		_replicate()


func is_subspace_visible(peer_id: int, subspace: Subspace) -> bool:
	return true


func is_entity_visible(peer_id: int, subspace: Subspace, node: Node) -> bool:
	return true


func _subspace_created(id: int, subspace: Subspace) -> void:
	var command := EntityListCommand.new(EntityListCommand.COMMAND_CREATE_SUBSPACE, [id, subspace.nickname as String, subspace.level_scene_path])
	for peer_id in multiplayer.get_peers():
		entity_list.push_command(peer_id, EntityList.STAGE_SUBSPACE, command)

func _subspace_destroyed(id: int, subspace: Subspace) -> void:
	var command := EntityListCommand.new(EntityListCommand.COMMAND_DESTROY_SUBSPACE, [id])
	for peer_id in multiplayer.get_peers():
		entity_list.push_command(peer_id, EntityList.STAGE_SUBSPACE, command)


func _entity_spawned(subspace: Subspace, index: int, id: StringName, node: Node) -> void:
	var args := [subspace.id, index, id as String]
	var command := EntityListCommand.new(EntityListCommand.COMMAND_SPAWN_ENTITY, args)
	for peer_id in multiplayer.get_peers():
		entity_list.push_command(peer_id, EntityList.STAGE_ENTITY, command)
	
	var entity_component := node.get_node(^"EntityComponent") as EntityComponent
	var snapshot := entity_component.get_snapshot()
	if snapshot == null: return
	var initialization_args := [subspace.id, index, snapshot.to_byte_array()]
	var initialization_command := EntityListCommand.new(EntityListCommand.COMMAND_REPLICATE, initialization_args)
	for peer_id in multiplayer.get_peers():
		entity_list.push_command(peer_id, EntityList.STAGE_INITIALIZATION, initialization_command)

func _entity_despawned(subspace: Subspace, index: int) -> void:
	var args := [subspace.id, index]
	var command := EntityListCommand.new(EntityListCommand.COMMAND_DESPAWN_ENTITY, args)
	for peer_id in multiplayer.get_peers():
		entity_list.push_command(peer_id, EntityList.STAGE_ENTITY, command)


func _replicate() -> void:
	for subspace: Subspace in subspace_manager.subspaces:
		for entity_component: EntityComponent in subspace.entities:
			var snapshot := entity_component.get_snapshot()
			if snapshot == null: continue
			var delta_snapshot: EntitySnapshot
			#if entity_component.is_snapshot_dirty:
			delta_snapshot = snapshot
			#else:
				#delta_snapshot = entity_component.get_snapshot_delta(snapshot, entity_component.previous_snapshot)
			if delta_snapshot == null or delta_snapshot.is_empty(): continue
			entity_component.previous_snapshot = snapshot
			
			var entity := entity_component.get_parent()
			
			var args := [subspace.id, entity_component.index, delta_snapshot.to_byte_array()]
			var command := EntityListCommand.new(EntityListCommand.COMMAND_REPLICATE, args)
			
			for peer_id in multiplayer.get_peers():
				if !is_entity_visible(peer_id, subspace, entity):
					continue
				if !is_subspace_visible(peer_id, subspace):
					continue
				entity_list.push_command(peer_id, EntityList.STAGE_PROPERTIES, command)


func _server_peer_connected(peer_id: int) -> void:
	for subspace: Subspace in subspace_manager.subspaces:
		if !is_subspace_visible(peer_id, subspace):
			continue
		var command := EntityListCommand.new(EntityListCommand.COMMAND_CREATE_SUBSPACE, [subspace.id, subspace.nickname, subspace.level_scene_path])
		entity_list.push_command(peer_id, EntityList.STAGE_SUBSPACE, command)
		
		for entity_component: EntityComponent in subspace.entities:
			var args := [subspace.id, entity_component.index, entity_component.id as String]
			var entity_command := EntityListCommand.new(EntityListCommand.COMMAND_SPAWN_ENTITY, args)
			entity_list.push_command(peer_id, EntityList.STAGE_ENTITY, entity_command)
			
			var initialization_args := [subspace.id, entity_component.index, entity_component.get_snapshot().to_byte_array()]
			var initialization_command := EntityListCommand.new(EntityListCommand.COMMAND_REPLICATE, initialization_args)
			entity_list.push_command(peer_id, EntityList.STAGE_PROPERTIES, initialization_command)
