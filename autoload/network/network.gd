extends Node


signal server_packet_received(peer_id: int, label: String, packet: PackedByteArray)
signal client_packet_received(label: String, packet: PackedByteArray)


const PORT := 13370
const TCP_PORT := 13371


@export var network_emulation_parameters := NetworkEmulationParameters.new()


var server_peer: ENetMultiplayerPeer
var peer_id_ips := {}
var ip_peer_ids := {}
var tcp_server: TCPServer
var client_tcp_peer: PacketPeerStream
var tcp_peers := {}

var server_tcp_thread: Thread
var client_tcp_thread: Thread


func _ready():
	var client_multiplayer := NetworkEmulationMultiplayer.new()
	client_multiplayer.network_emulation_parameters = network_emulation_parameters
	client_multiplayer.base.server_relay = false
	client_multiplayer.base.root_path = get_tree().root.get_path()
	get_tree().set_multiplayer(client_multiplayer)
	
	if not Server.is_node_ready():
		await Server.ready
	
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), Server.get_path())
	
	var server_multiplayer := NetworkEmulationMultiplayer.new()
	server_multiplayer.network_emulation_parameters = network_emulation_parameters
	server_multiplayer.base.server_relay = false
	server_multiplayer.base.root_path = Server.get_path()
	get_tree().set_multiplayer(server_multiplayer, Server.get_path())


func _physics_process(delta: float) -> void:
	_server_process()


func _server_process() -> void:
	if tcp_server == null: return
	if !tcp_server.is_connection_available(): return
	var peer := tcp_server.take_connection()
	var ip := peer.get_connected_host() as StringName
	if !ip_peer_ids.has(ip): return # hecker
	var peer_id: int = ip_peer_ids[ip]
	var packet_peer := PacketPeerStream.new()
	packet_peer.stream_peer = peer
	tcp_peers[peer_id] = packet_peer


func host() -> void:
	server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(PORT)
	Server.multiplayer.multiplayer_peer = server_peer
	server_peer.peer_connected.connect(self._register)
	
	tcp_server = TCPServer.new()
	tcp_server.listen(TCP_PORT)
	
	server_tcp_thread = Thread.new()
	server_tcp_thread.start(self._server_tcp_thread)


func _register(peer_id: int) -> void:
	var ip := server_peer.get_peer(peer_id).get_remote_address()
	peer_id_ips[peer_id] = ip
	ip_peer_ids[ip as StringName] = peer_id


func connect_to(ip: String) -> void:
	var client_peer := ENetMultiplayerPeer.new()
	client_peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = client_peer
	
	await get_tree().create_timer(0.5).timeout
	var tcp_peer := StreamPeerTCP.new()
	assert(tcp_peer.connect_to_host(ip, TCP_PORT) == OK)
	client_tcp_peer = PacketPeerStream.new()
	client_tcp_peer.stream_peer = tcp_peer
	
	client_tcp_thread = Thread.new()
	client_tcp_thread.start(self._client_tcp_thread)


func client_tcp_send(label: String, byte_array: PackedByteArray) -> Error:
	if client_tcp_peer == null:
		push_warning("Client TCP peer not ready!")
		return ERR_CONNECTION_ERROR
	return client_tcp_peer.put_packet(var_to_bytes([label, byte_array]))


func server_tcp_send(peer_id: int, label: String, byte_array: PackedByteArray) -> Error:
	return tcp_peers[peer_id].put_packet(var_to_bytes([label, byte_array]))


func server_tcp_broadcast(label: String, byte_array: PackedByteArray) -> void:
	for peer_id in tcp_peers:
		server_tcp_send(peer_id, label, byte_array)


func _server_tcp_thread() -> void:
	while true:
		await get_tree().create_timer(0.0).timeout
		for peer_id in tcp_peers:
			var peer: PacketPeerStream = tcp_peers[peer_id]
			peer.stream_peer.poll()
			for i in range(peer.get_available_packet_count()):
				_server_packet_received.call_deferred(peer_id, peer.get_packet())


func _client_tcp_thread() -> void:
	while true:
		await get_tree().create_timer(0.0).timeout
		client_tcp_peer.stream_peer.poll()
		for i in range(client_tcp_peer.get_available_packet_count()):
			_client_packet_received.call_deferred(client_tcp_peer.get_packet())


func _server_packet_received(peer_id: int, packet: PackedByteArray) -> void:
	var array_maybe = bytes_to_var(packet)
	if !(array_maybe is Array): return
	var array: Array = array_maybe
	if !(array[0] is String): return
	if !(array[1] is PackedByteArray): return
	server_packet_received.emit(peer_id, array[0], array[1])


func _client_packet_received(packet: PackedByteArray) -> void:
	var array_maybe = bytes_to_var(packet)
	if !(array_maybe is Array): return
	var array: Array = array_maybe
	if !(array[0] is String): return
	if !(array[1] is PackedByteArray): return
	client_packet_received.emit(array[0], array[1])
