extends Node
class_name EntityManager


signal entity_spawned(subspace: Subspace, index: int, id: StringName, node: Node)
signal entity_despawned(subspace: Subspace, index: int)


@export var entity_list: EntityList


var replicating := false


func spawn_entity(subspace, entity) -> Node:
	return _coerce_subspace(subspace).spawn_entity(entity)

func despawn_entity(subspace, entity) -> void:
	return _coerce_subspace(subspace).despawn_entity(entity)

func _coerce_subspace(s) -> Subspace:
	var subspace: Subspace
	if s is int: # Subspace id
		subspace = entity_list.subspace_manager.subspaces_map[s] as Subspace
	if s is Subspace: # Subspace itself
		subspace = s
	assert(subspace != null)
	return subspace
