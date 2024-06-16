extends Node



@export var client_only_scene: PackedScene


@onready var entity_list: EntityList = %EntityList


func _ready() -> void:
	if !multiplayer.is_server():
		var client_only: ClientOnly = client_only_scene.instantiate()
		client_only.entity_list = entity_list
		add_child(client_only)
	
