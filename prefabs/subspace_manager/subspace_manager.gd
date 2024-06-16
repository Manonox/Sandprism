extends Node
class_name SubspaceManager


signal subspace_created(id: int, subspace: Subspace)
signal subspace_destroyed(id: int, subspace: Subspace)


@export var subspace_scene: PackedScene

@export_group("Links")
@export var entity_list: EntityList


var subspaces: Array[Node] :
	get:
		return _subspaces.get_children()


var replicating := false
var subspaces_map := {}
var current_subspace: Subspace


var _incremental_subspace_id := 0


@onready var subspace_viewer: TextureRect = $SubspaceViewer
@onready var _subspaces: Node = $Subspaces


func _ready() -> void:
	pass


func create_subspace(id: int = -1) -> Subspace:
	if id == -1:
		id = _incremental_subspace_id
		_incremental_subspace_id += 1
	
	var subspace := subspace_scene.instantiate() as Subspace
	subspace.id = id
	subspace.entity_list = entity_list
	subspace.entity_spawned.connect(self._emit_entity_in_subspace_spawned.bind(subspace))
	subspace.entity_despawned.connect(self._emit_entity_in_subspace_despawned.bind(subspace))
	subspaces_map[id] = subspace
	_subspaces.add_child(subspace)
	if !replicating:
		_emit_subspace_created.call_deferred(id, subspace)
		
	id += 1 # TODO: wrap..?
	return subspace


func _emit_subspace_created(id: int, subspace: Subspace) -> void:
	subspace_created.emit(id, subspace)

func _emit_entity_in_subspace_spawned(index: int, id: StringName, node: Node, subspace: Subspace) -> void:
	entity_list.entity_manager.entity_spawned.emit(subspace, index, id, node)

func _emit_entity_in_subspace_despawned(index: int, id: StringName, node: Node, subspace: Subspace) -> void:
	entity_list.entity_manager.entity_despawned.emit(subspace, index, id, node)


func create_subspace_from_node(node: Node, id: int = -1) -> Subspace:
	var subspace := create_subspace(id)
	subspace.level_node = node
	return subspace


func create_subspace_from_packed(packed_scene: PackedScene, id: int = -1) -> Subspace:
	var node := packed_scene.instantiate()
	return create_subspace_from_node(node, id)


func create_subspace_from_level(level: Level, id: int = -1) -> Subspace:
	var subspace := create_subspace_from_packed(level.packed_scene, id)
	subspace.level_scene_path = level.path
	return subspace


func destroy_subspace(x) -> void:
	var id: int
	var subspace: Subspace
	if x is int:
		id = x as int
		if !subspaces_map.has(id):
			return
		subspace = subspaces_map[id]
	if x is Subspace:
		id = x.id
		subspace = x
	_subspaces.remove_child(subspace)
	subspaces_map.erase(id)
	subspace.queue_free()
	if !replicating:
		subspace_destroyed.emit(id, subspace)


func destroy_all_subspaces() -> void:
	for subspace in subspaces:
		destroy_subspace(subspace)


func get_subspace_by_id(id: int) -> Subspace:
	return subspaces_map.get(id)


func view_subspace(x) -> void:
	var id: int
	var subspace: Subspace
	if x is int:
		id = x as int
		if !subspaces_map.has(id):
			return
		subspace = subspaces_map[id]
	if x is Subspace:
		id = x.id
		subspace = x
	
	subspace_viewer.texture = subspace.get_texture()
	current_subspace = subspace


func _input(event: InputEvent) -> void:
	if current_subspace != null:
		current_subspace.push_input(event)
		#push_text_input(text: String) ???
