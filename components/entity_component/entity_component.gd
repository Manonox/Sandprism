extends Node
class_name EntityComponent


signal snapshot_received(snapshot: EntitySnapshot, tick: int)


@export var id: StringName
@export var multiplayer_synchronizer: MultiplayerSynchronizer
@export var network_prediction_component: NetworkPredictionComponent


var subspace: Subspace
var entity_list: EntityList
var index: int
var is_snapshot_dirty: bool = false

var previous_snapshot: EntitySnapshot

var replication_config: SceneReplicationConfig :
	get:
		if multiplayer_synchronizer == null:
			return null
		return multiplayer_synchronizer.replication_config


var root_node: Node


func _ready() -> void:
	if multiplayer_synchronizer != null:
		root_node = multiplayer_synchronizer.get_node(multiplayer_synchronizer.root_path)
		_set_previous_snapshot.call_deferred()


func get_empty_snapshot() -> EntitySnapshot:
	return EntitySnapshot.new(replication_config)


func get_snapshot() -> EntitySnapshot:
	if root_node == null: return null
	return get_empty_snapshot().read(root_node)


func get_snapshot_delta(current: EntitySnapshot, previous: EntitySnapshot) -> EntitySnapshot:
	if root_node == null: return null
	return EntitySnapshot.new(current).read_delta(root_node, previous)


func apply_snapshot(snapshot: EntitySnapshot, tick: int) -> void:
	assert(root_node != null, "wtf")
	snapshot.write(root_node)
	snapshot_received.emit(snapshot, tick)


func mark_snapshot_dirty() -> void:
	is_snapshot_dirty = true


func _set_previous_snapshot() -> void:
	previous_snapshot = get_snapshot()
