extends CharacterBody3D


@onready var pawn_component: PawnComponent = $PawnComponent
@onready var camera: Camera3D = %Camera
@onready var visual: Node3D = %Visual
@onready var body: Node3D = $Body
@onready var head: Node3D = $Body/Head
@onready var interpolation_component: InterpolationComponent = $InterpolationComponent
@onready var mouse_look_component: MouseLookComponent = $MouseLookComponent


func _ready() -> void:
	mouse_look_component.enabled = false


func _physics_process(delta: float) -> void:
	interpolation_component.record_position(position)


func is_local() -> bool:
	return pawn_component.client_is_local_pawn


func _on_pawn_component_peer_changed(_peer_id: int) -> void:
	if is_local():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_look_component.enabled = is_local()
	camera.current = is_local()
	visual.visible = !is_local()

