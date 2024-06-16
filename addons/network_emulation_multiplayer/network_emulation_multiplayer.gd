extends MultiplayerAPIExtension
class_name NetworkEmulationMultiplayer


signal network_process

var network_emulation_parameters : NetworkEmulationParameters
var base := SceneMultiplayer.new()

func _init(_nep: NetworkEmulationParameters = NetworkEmulationParameters.new()) -> void:
	network_emulation_parameters = _nep
	
	var cts := connected_to_server
	var cf := connection_failed
	var pc := peer_connected
	var pd := peer_disconnected
	base.connected_to_server.connect(func(): cts.emit())
	base.connection_failed.connect(func(): cf.emit())
	base.peer_connected.connect(func(id): pc.emit(id))
	base.peer_disconnected.connect(func(id): pd.emit(id))


func _poll() -> Error:
	var result := base.poll()
	if result == OK:
		network_process.emit()
	return result

func _rpc(peer: int, object: Object, method: StringName, args: Array) -> Error:
	var ping := network_emulation_parameters.get_fake_ping()
	await object.get_tree().create_timer(ping).timeout
	
	while randf() < network_emulation_parameters.duplicate_chance:
		await object.get_tree().create_timer(0.005).timeout
		if randf() < network_emulation_parameters.drop_chance:
			continue
		base.rpc(peer, object, method, args)
	
	
	if randf() < network_emulation_parameters.drop_chance:
		return OK
	return base.rpc(peer, object, method, args)

func _object_configuration_add(object, config: Variant) -> Error:
	#return base.object_configuration_add(object, config)
	return OK

func _object_configuration_remove(object, config: Variant) -> Error:
	#return base.object_configuration_remove(object, config)
	return OK

func _set_multiplayer_peer(p_peer: MultiplayerPeer):
	base.multiplayer_peer = p_peer

func _get_multiplayer_peer() -> MultiplayerPeer:
	return base.multiplayer_peer

func _get_unique_id() -> int:
	return base.get_unique_id()

func _get_remote_sender_id() -> int:
	return base.get_remote_sender_id()

func _get_peer_ids() -> PackedInt32Array:
	return base.get_peers()
