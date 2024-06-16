extends Node
class_name ConsoleSystem


signal stdout(content: String, on_server: bool)
signal stderr(content: String, on_server: bool)


@export_group("Links")
@export var entity_list : EntityList


enum OutputType {
	Out,
	Err
}


func push_stdout(peer_id: int, content: String) -> void:
	_forward(peer_id, content, OutputType.Out)

func push_stderr(peer_id: int, content: String) -> void:
	_forward(peer_id, content, OutputType.Err)


func _forward(peer_id: int, content: String, type: OutputType) -> void:
	if multiplayer.is_server():
		_server(peer_id, content, type)
	elif multiplayer.get_unique_id() == peer_id:
		_client(content, type)


@rpc("authority", "call_remote", "reliable")
func _client(content: String, type: OutputType, on_server: bool = false) -> void:
	match type:
		OutputType.Out:
			stdout.emit(content, on_server)
		OutputType.Err:
			stderr.emit(content, on_server)


#@rpc("any_peer", "call_remote", "reliable")
func _server(peer_id: int, content: String, type: OutputType) -> void:
	_client.rpc_id(peer_id, content, type, true)
