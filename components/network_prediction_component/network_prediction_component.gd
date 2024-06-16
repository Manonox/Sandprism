extends Node
class_name NetworkPredictionComponent


const CLIENT_INPUT_SEND_SIZE := 10


@export var player: CharacterBody3D
@export var entity_component: EntityComponent
@export var pawn_component: PawnComponent
@export var player_movement: IPlayerMovement


var _current_tick: int = 0


var _input_history := History.new(Engine.physics_ticks_per_second)
var _state_history := History.new(Engine.physics_ticks_per_second)
var _default_delta := 0.0
var _resimulate_scheduled_from := -1

var _server_input_buffer := History.new(32)
var _server_last_input: StructuredTable



@onready var _entity_list := entity_component.entity_list
@onready var _server_remote_tick: int = _current_tick


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	_default_delta = delta
	if multiplayer.is_server():
		_server_physics_process(delta)
	elif !pawn_component.client_is_local_pawn:
		_non_local_physics_process(delta)
	else:
		_local_physics_process(delta)


func _server_physics_process(delta: float) -> void:
	var _received_input_string_tick := _server_remote_tick
	var _received_input_string := []
	
	var max_received_tick: int = -1
	for i in range(_server_input_buffer.size() - 1, -1, -1):
		var pair: Array = _server_input_buffer.at(i)
		var tick: int = pair[0]
		max_received_tick = max(tick, max_received_tick)
		if tick == _received_input_string_tick:
			_received_input_string.append(pair[1])
			_received_input_string_tick += 1
	
	for input in _received_input_string:
		var state := player_movement.make_state_table()
		player_movement.write_state(state)
		
		var command := EntityListCommand.new(EntityListCommand.COMMAND_REPLICATE_PAWNS, [
			entity_component.subspace.id,
			entity_component.index,
			state.pack(),
			_server_remote_tick
		])
		
		for peer_id in multiplayer.get_peers():
			_entity_list.push_command(peer_id, EntityList.STAGE_PROPERTIES, command)
		#_client_receive_state.rpc(_server_remote_tick, state.pack())
		
		_server_last_input = input
		player_movement.simulate(input, delta)
		_server_remote_tick += 1


@rpc("any_peer", "call_remote", "unreliable_ordered", 3)
func _server_receive_input(inputs: Array) -> void:
	if multiplayer.get_remote_sender_id() != pawn_component.server_current_peer_id:
		return
	if inputs.size() > CLIENT_INPUT_SEND_SIZE:
		return
	for pair in inputs:
		if not (pair is Array): return push_warning("wtf")
		if not (pair[0] is int): return push_warning("wtf")
		var tick: int = pair[0]
		if tick < _server_remote_tick: continue
		if not (pair[1] is PackedByteArray): return push_warning("wtf")
		var byte_array: PackedByteArray = pair[1]
		var input := player_movement.make_input_table()
		input.unpack(byte_array)
		_server_input_buffer.append([tick, input])


func _local_physics_process(delta: float) -> void:
	if _resimulate_scheduled_from != -1:
		_resimulate_from(_resimulate_scheduled_from)
		_resimulate_scheduled_from = -1
	
	var input := player_movement.make_input_table()
	player_movement.write_local_input(input)
	
	var state := player_movement.make_state_table()
	player_movement.write_state(state)
		
	_input_history.append([_current_tick, input])
	_state_history.append([_current_tick, state])
	
	_local_send_input()
	
	player_movement.simulate(input, delta)
	_current_tick += 1
	#print("cl sim(%s): %s" % [multiplayer.get_unique_id(), _current_tick])


func _local_send_input() -> void:
	var array := []
	var max_index := mini(_input_history.size() - 1, CLIENT_INPUT_SEND_SIZE - 1)
	array.resize(max_index + 1)
	for i in range(max_index, -1, -1):
		var pair = _input_history.at(i)
		array[i] = [pair[0], pair[1].pack()]
	_server_receive_input.rpc_id(1, array)


func _local_receive_state(tick: int, state: StructuredTable) -> void:
	var offset := _current_tick - tick - 1
	if offset > _state_history.max_size() - 1: return
	var array: Array = _state_history.at(offset)
	var past_state_tick: int = array[0]
	if tick != past_state_tick:
		return
	var past_state: StructuredTable = array[1]
	
	var prediction_error := !state.is_equal_approx(past_state)
	if prediction_error:
		_state_history.set_at(offset, [tick, state])
		_resimulate_scheduled_from = max(_resimulate_scheduled_from, offset)
		#print("prediction error!")
	else:
		pass
		# print("all g")


func _resimulate_from(from_index: int) -> void:
	var server_state: StructuredTable = _state_history.at(from_index)[1]
	player_movement.read_state(server_state)
	
	for i in range(from_index, -1, -1):
		var array: Array = _input_history.at(i)
		var tick: int = array[0]
		var input: StructuredTable = array[1]
		player_movement.simulate(input, _default_delta)
		
		if i > 0 and i < _state_history.size() - 1:
			var state := player_movement.make_state_table()
			player_movement.write_state(state)
			_state_history.set_at(i + 1, [tick + 1, state])



func _non_local_receive_state(tick: int, state: StructuredTable) -> void:
	player_movement.read_state(state)


func _non_local_physics_process(delta: float) -> void:
	pass


func client_receive_state(tick: int, state_byte_array: PackedByteArray) -> void:
	var state := player_movement.make_state_table()
	state.unpack(state_byte_array)
	
	if pawn_component.client_is_local_pawn:
		_local_receive_state(tick, state)
	else:
		_non_local_receive_state(tick, state)
