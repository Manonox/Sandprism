extends Node
class_name EntityList


const STAGE_SUBSPACE := 0
const STAGE_ENTITY := 1
const STAGE_INITIALIZATION := 2
const STAGE_POSSESS := 3
const STAGE_COUNT_UNRELIABLE := 4

const STAGE_PROPERTIES := 4
const STAGE_COUNT := 5


@export var main_level: Level
@export var available_entities: Array[EntityListEntity]

@export_group("Links")
@export var subspace_manager: SubspaceManager
@export var entity_manager: EntityManager
@export var pawn_system: PawnSystem
@export var replication_system: ReplicationSystem
@export var console_system: ConsoleSystem


var registered_entities := {}
var tick := 0
var commands := {}


func _ready() -> void:
	for entity in available_entities:
		registered_entities[entity.id] = entity
	
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(self._server_peer_connected)
		multiplayer.peer_disconnected.connect(self._server_peer_disconnected)
		
		var subspace := subspace_manager.create_subspace_from_level(main_level)
		subspace.nickname = "Overworld"
	else:
		multiplayer.connected_to_server.connect(self._client_connected_to_server)


func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		_server_physics_process(_delta)
	if multiplayer.is_server() or tick > 0:
		tick += 1


func push_command(peer_id: int, stage: int, command: EntityListCommand) -> void:
	if !commands.has(peer_id):
		commands[peer_id] = []
		commands[peer_id].resize(STAGE_COUNT)
		commands[peer_id].fill([])
	#print("SV -> %s: %s" % [peer_id, command])
	commands[peer_id][stage].push_back(command)


func _server_physics_process(_delta: float) -> void:
	for peer_id in multiplayer.get_peers():
		if !commands.has(peer_id):
			continue
		var peer_commands: Array = commands[peer_id]
		
		var reliable_snapshot := EntityListSnapshot.new(tick)
		for stage in range(STAGE_COUNT_UNRELIABLE):
			reliable_snapshot.commands.append_array(peer_commands[stage])
			peer_commands[stage].clear()
		if !reliable_snapshot.is_empty():
			_client_receive_reliable_snapshot.rpc_id(peer_id, reliable_snapshot.to_byte_array())
		
		var unreliable_snapshot := EntityListSnapshot.new(tick)
		for stage in range(STAGE_COUNT_UNRELIABLE, STAGE_COUNT):
			unreliable_snapshot.commands.append_array(peer_commands[STAGE_PROPERTIES])
			peer_commands[stage].clear()
		if !unreliable_snapshot.is_empty():
			_client_receive_unreliable_snapshot.rpc_id(peer_id, unreliable_snapshot.to_byte_array())


func _server_peer_connected(peer_id: int) -> void:
	pass

func _server_peer_disconnected(peer_id: int) -> void:
	commands.erase(peer_id)


@rpc("authority", "call_remote", "reliable")
func _client_receive_reliable_snapshot(byte_array: PackedByteArray) -> void:
	_apply_received_encoded_snapshot(byte_array)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _client_receive_unreliable_snapshot(byte_array: PackedByteArray) -> void:
	_apply_received_encoded_snapshot(byte_array)

func _apply_received_encoded_snapshot(byte_array: PackedByteArray) -> void:
	var snapshot := EntityListSnapshot.decode(byte_array)
	if !snapshot.is_valid: return
	snapshot.apply(self)


func _client_connected_to_server() -> void:
	_on_sync_timer_timeout()


func _on_sync_timer_timeout() -> void:
	if !multiplayer.is_server():
		_server_receive_sync_request.rpc_id(1, Time.get_ticks_msec())

@rpc("any_peer", "call_remote", "unreliable")
func _server_receive_sync_request(_client_ticks_msec: int) -> void:
	_sync.rpc_id(multiplayer.get_remote_sender_id(), _client_ticks_msec, tick)

@rpc("authority", "call_remote", "unreliable")
func _sync(_ticks_msec: int, tick_: int) -> void:
	var reverse_trip_ms := Time.get_ticks_msec() - _ticks_msec
	var add := reverse_trip_ms / 2000.0 * Engine.physics_ticks_per_second
	tick = tick_ + roundi(add) + 1 # "+ 1" (..?)
