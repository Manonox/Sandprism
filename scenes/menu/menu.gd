extends Control




@export var game_scene : PackedScene

@onready var host_button: Button = %HostButton
@onready var connect_button: Button = %ConnectButton
@onready var ip_line_edit: LineEdit = %IPLineEdit


func _ready() -> void:
	pass


func _on_host_button_pressed() -> void:
	_disable_buttons()
	Network.host()
	Server.change_scene_to_packed(game_scene)
	get_tree().create_timer(0.1).timeout.connect(self._connect)


func _on_connect_button_pressed() -> void:
	_disable_buttons()
	var ip := ip_line_edit.text
	_connect(ip)


func _connect(ip: String = "") -> void:
	if ip.is_empty():
		ip = "127.0.0.1"
	get_tree().change_scene_to_packed(game_scene)
	Network.connect_to(ip)


func _disable_buttons() -> void:
	host_button.disabled = true
	connect_button.disabled = true
	ip_line_edit.editable = false
