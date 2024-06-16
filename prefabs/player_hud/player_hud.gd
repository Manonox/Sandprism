extends Control
class_name PlayerHUD


@onready var peer_id_label: Label = $PeerIDLabel
@onready var current_tick_label: Label = $CurrentTickLabel

@onready var entity_list: EntityList = get_parent().entity_list
@onready var pawn_system: PawnSystem = entity_list.pawn_system
@onready var project_editor: ProjectEditor = $ProjectEditor


func _ready() -> void:
	position = Vector2(0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"lua_open_editor"):
		project_editor.visible = !project_editor.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if project_editor.visible else Input.MOUSE_MODE_CAPTURED
		if project_editor.visible:
			project_editor.luau_edit.grab_focus()


func _process(delta: float) -> void:
	peer_id_label.text = "ID: %s" % multiplayer.get_unique_id()
	var pawn := pawn_system.client_local_pawn
	if pawn == null:
		current_tick_label.text = "Tick: N/A"
		return
	var player: Node = pawn.get_parent()
	var network_prediction_component: NetworkPredictionComponent = player.get_node(^"NetworkPredictionComponent")
	var tick := network_prediction_component._current_tick
	current_tick_label.text = "Tick: %s" % tick
