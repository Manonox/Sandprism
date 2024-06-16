extends Node
class_name PawnComponent


signal peer_changed(peer_id: int)


var server_current_peer_id := 0
var client_is_local_pawn := false


func server_is_possessed() -> int:
	return server_current_peer_id > 0
