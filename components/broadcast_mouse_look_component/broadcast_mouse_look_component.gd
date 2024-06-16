extends Node
class_name BroadcastMouseLookComponent


@export var pawn_component: PawnComponent
@export var mouse_look_component: MouseLookComponent


@onready var _client_last_look: Vector3


func _physics_process(_delta: float) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if pawn_component.client_is_local_pawn:
		_local_broadcast()


func _local_broadcast() -> void:
	var look := mouse_look_component.rotation_degrees
	if _client_last_look.is_equal_approx(look):
		return
	_client_last_look = look
	_server_receive.rpc_id(1, look)


@rpc("any_peer", "call_remote", "unreliable_ordered", 2)
func _server_receive(rotation_degrees: Vector3) -> void:
	var from := multiplayer.get_remote_sender_id()
	if from != pawn_component.server_current_peer_id: return
	_receive(rotation_degrees)
	for peer_id in multiplayer.get_peers():
		if peer_id == from: continue
		_receive.rpc_id(peer_id, rotation_degrees)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receive(rotation_degrees: Vector3) -> void:
	mouse_look_component.set_look_rotation(rotation_degrees)
