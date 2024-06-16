extends RefCounted
class_name EntityListCommand


const COMMAND_NOP := 0

const COMMAND_RESET := 1

const COMMAND_CREATE_SUBSPACE := 2
const COMMAND_DESTROY_SUBSPACE := 3

const COMMAND_SPAWN_ENTITY := 4
const COMMAND_DESPAWN_ENTITY := 5
const COMMAND_POSSESS_ENTITY := 6
const COMMAND_REPLICATE := 7
const COMMAND_REPLICATE_PAWNS := 8

const COMMAND_NAMES := [
	"NOP",
	"RESET",
	"SPAWN_SUBSPACE",
	"DESTROY_SUBSPACE",
	"SPAWN_ENTITY",
	"DESPAWN_ENTITY",
	"POSSESS_ENTITY",
	"REPLICATE",
	"REPLICATE_PAWNS"
]


var type: int = COMMAND_NOP
var args: Array = []


func _init(type_: int, args_: Array = []) -> void:
	type = type_
	args = args_


func _to_string() -> String:
	return "<EntityListCommand#%s>:%s(%s)" % [get_instance_id(), COMMAND_NAMES[type], args]


func apply(entity_list: EntityList, tick: int = -1) -> void:
	entity_list.subspace_manager.replicating = true
	entity_list.entity_manager.replicating = true
	
	_apply(entity_list, tick)
	
	entity_list.subspace_manager.replicating = false
	entity_list.entity_manager.replicating = false


func _apply(entity_list: EntityList, tick: int) -> void:
	match type:
		COMMAND_RESET:
			entity_list.subspace_manager.destroy_all_subspaces()
		
		COMMAND_CREATE_SUBSPACE:
			var id: int = args[0]
			var nickname: String = args[1]
			var packed_scene_path: String = args[2]
			var packed_scene: PackedScene = load(packed_scene_path)
			var subspace := entity_list.subspace_manager.create_subspace_from_packed(packed_scene, id)
			subspace.nickname = nickname
		
		COMMAND_DESTROY_SUBSPACE:
			var id: int = args[0]
			entity_list.subspace_manager.destroy_subspace(id)
		
		COMMAND_SPAWN_ENTITY:
			var subspace_id: int = args[0]
			var index: int = args[1]
			var id: String = args[2]
			var subspace_maybe: Subspace = entity_list.subspace_manager.get_subspace_by_id(subspace_id)
			assert(subspace_maybe != null) # ?
			var subspace := subspace_maybe as Subspace
			subspace.spawn_entity(id as StringName, index)
		
		COMMAND_DESPAWN_ENTITY:
			var subspace_id: int = args[0]
			var index: int = args[1]
			var subspace_maybe: Subspace = entity_list.subspace_manager.get_subspace_by_id(subspace_id)
			assert(subspace_maybe != null) # ?
			var subspace := subspace_maybe as Subspace
			subspace.despawn_entity(index)
			
		COMMAND_POSSESS_ENTITY:
			var subspace_id: int = args[0]
			var index: int = args[1]
			var subspace_maybe: Subspace = entity_list.subspace_manager.subspaces_map.get(subspace_id)
			assert(subspace_maybe != null) # ?
			var subspace := subspace_maybe as Subspace
			entity_list.pawn_system.client_possess(subspace, index)
		
		COMMAND_REPLICATE_PAWNS:
			var subspace_id: int = args[0]
			var index: int = args[1]
			var subspace_maybe: Subspace = entity_list.subspace_manager.subspaces_map.get(subspace_id)
			if subspace_maybe == null: return
			var subspace := subspace_maybe as Subspace
			var entity_component := subspace.get_entity_component_by_index(index)
			if entity_component == null: return
			var network_prediction_component: NetworkPredictionComponent = entity_component.network_prediction_component
			if network_prediction_component == null: return
			var byte_array: PackedByteArray = args[2]
			var remote_tick: int = args[3]
			network_prediction_component.client_receive_state(remote_tick, byte_array)
		
		COMMAND_REPLICATE:
			var subspace_id: int = args[0]
			var index: int = args[1]
			var subspace_maybe: Subspace = entity_list.subspace_manager.subspaces_map.get(subspace_id)
			if subspace_maybe == null:
				return
			var subspace := subspace_maybe as Subspace
			var entity_component := subspace.get_entity_component_by_index(index)
			if entity_component == null:
				return
			var snapshot_byte_array: PackedByteArray = args[2]
			var snapshot := entity_component.get_empty_snapshot()
			if !snapshot.decode(snapshot_byte_array):
				return
			if snapshot.is_empty():
				return
			entity_component.apply_snapshot(snapshot, tick)


static func decode(byte_array: PackedByteArray) -> EntityListCommand:
	var type_ := byte_array.decode_s8(byte_array.size() - 1)
	byte_array.resize(byte_array.size() - 1)
	var args_maybe_ = byte_array.decode_var(0)
	var args_ := []
	if not (args_maybe_ is Array):
		type_ = COMMAND_NOP
	else:
		args_ = args_maybe_
	var command := EntityListCommand.new(type_, args_)
	return command


func to_byte_array() -> PackedByteArray:
	var byte_array := var_to_bytes(args)
	byte_array.resize(byte_array.size() + 1)
	byte_array.encode_s8(byte_array.size() - 1, type)
	return byte_array
