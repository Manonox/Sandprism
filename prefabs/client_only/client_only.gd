extends Node
class_name ClientOnly


var entity_list: EntityList

var previous_mouse_mode


@onready var player_hud: PlayerHUD = $PlayerHUD
@onready var console_overlay: ConsoleOverlay = %ConsoleOverlay
@onready var console := console_overlay.console
@onready var lua_console_receiver: LuaConsoleReceiver = $LuaConsoleReceiver


func _ready() -> void:
	entity_list.console_system.stdout.connect(lua_console_receiver.stdout.bind(console))
	entity_list.console_system.stderr.connect(lua_console_receiver.stderr.bind(console))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"console"):
		get_viewport().set_input_as_handled()
		console_overlay.visible = !console_overlay.visible
		if console_overlay.visible:
			previous_mouse_mode = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			console_overlay.console.focus_input()
		else:
			Input.mouse_mode = previous_mouse_mode
