extends SubViewport
class_name Subspace


signal entity_spawned(index: int, id: StringName, x: Node)
signal entity_despawned(index: int)


const MAX_ENTITIES := 2 ** 16 - 1
const NODE_NAME_FORMAT := "%s(%s)"


var nickname: StringName = &"Subspace" :
	set(value):
		nickname = value
		name = NODE_NAME_FORMAT % [nickname, id]

var id: int = -1 :
	set(value):
		id = value
		name = NODE_NAME_FORMAT % [nickname, id]


var level_node: Node :
	set(value):
		if level_node != null:
			level_container.remove_child(level_node)
		level_node = value
		level_container.add_child(level_node)

var level_scene_path: String

var entity_list: EntityList

var entities: Array :
	get:
		return _entity_components.values()

var _entity_components := {}
var _next_entity_index: int = 1


@onready var level_container: Node = $LevelContainer
@onready var _entities: Node = $Entities


func _ready() -> void:
	world_3d = world_3d.duplicate(true)
	own_world_3d = true
	
	if !multiplayer.is_server():
		var viewport := get_parent().get_viewport()
		size = viewport.get_visible_rect().size
		viewport.size_changed.connect(func():
			size = viewport.get_visible_rect().size)


func _process(_delta: float) -> void:
	if !multiplayer.is_server():
		var viewport := get_parent().get_viewport()
		clone_properties(viewport) # Bruh


func spawn_entity(x, index: int = -1) -> Node:
	var entity: EntityListEntity
	if x is StringName: # Entity id
		entity = entity_list.registered_entities[x] as EntityListEntity
	if x is EntityListEntity: # EntityListEntity itself
		entity = x
	assert(entity != null)
	
	if index == -1:
		index = _next_entity_index
		_increment_next_entity_index()
	
	assert(!_entity_components.has(index))
	
	var node := entity.prefab.instantiate()
	node.name = var_to_str(index)
	var entity_component := node.get_node(^"EntityComponent") as EntityComponent
	entity_component.entity_list = entity_list
	entity_component.id = entity.id
	entity_component.subspace = self
	entity_component.index = index
	_entity_components[index] = entity_component
	_entities.add_child(node)
	
	if !entity_list.entity_manager.replicating:
		_emit_entity_spawned.call_deferred(index, entity.id, node)
	return node

func _emit_entity_spawned(index_: int, id_: StringName, node_: Node) -> void:
	entity_spawned.emit(index_, id_, node_)


func _increment_next_entity_index() -> int:
	_next_entity_index = _next_entity_index % MAX_ENTITIES + 1
	while _entity_components.has(_next_entity_index):
		_next_entity_index = _next_entity_index % MAX_ENTITIES + 1
	return _next_entity_index


func despawn_entity(x) -> void:
	var entity_component: EntityComponent
	
	if x is int:
		assert(_entity_components.size() > x and _entity_components[x] != null)
		entity_component = _entity_components[x]
	if x is Node:
		entity_component = x.get_node(^"EntityComponent")
	if x is EntityComponent:
		entity_component = x
	
	var node := entity_component.get_parent()
	_entities.remove_child(node)
	_entity_components.erase(entity_component.index)
	node.queue_free()
	if !entity_list.entity_manager.replicating:
		_emit_entity_despawned.call_deferred(entity_component.index)

func _emit_entity_despawned(index_: int) -> void:
	entity_despawned.emit(index_)
	

func get_entity_component_by_index(index: int) -> EntityComponent:
	return _entity_components.get(index)




# OTHER

const _properties_to_clone : Array[StringName] = [
	&"audio_listener_enable_2d",
	&"audio_listener_enable_3d",
	&"canvas_cull_mask",
	&"canvas_item_default_texture_filter",
	&"canvas_item_default_texture_repeat",
	&"canvas_transform",
	&"debug_draw",
	&"disable_3d",
	&"fsr_sharpness",
	&"global_canvas_transform",
	&"gui_disable_input",
	&"gui_embed_subwindows",
	&"gui_snap_controls_to_pixels",
	&"handle_input_locally",
	&"mesh_lod_threshold",
	&"msaa_2d",
	&"msaa_3d",
	&"physics_object_picking",
	&"physics_object_picking_sort",
	&"positional_shadow_atlas_16_bits",
	&"positional_shadow_atlas_quad_0",
	&"positional_shadow_atlas_quad_1",
	&"positional_shadow_atlas_quad_2",
	&"positional_shadow_atlas_quad_3",
	&"positional_shadow_atlas_size",
	&"scaling_3d_mode",
	&"scaling_3d_scale",
	&"screen_space_aa",
	&"sdf_oversize",
	&"sdf_scale",
	&"snap_2d_transforms_to_pixel",
	&"snap_2d_vertices_to_pixel",
	&"texture_mipmap_bias",
	&"transparent_bg",
	&"use_debanding",
	&"use_hdr_2d",
	&"use_occlusion_culling",
	&"use_taa",
	&"use_xr",
	&"vrs_mode",
	&"vrs_texture",
]

func clone_properties(source: Viewport) -> void:
	for property in _properties_to_clone:
		var value = source.get(property)
		set(property, value)
