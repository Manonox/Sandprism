extends Node
class_name InterpolationComponent


@export var enabled := true
@export var target : Node3D

var _previous_position : Vector3
var _previous_position_set : bool = false
var _target_position : Vector3
var _target_position_set : bool = false


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if target == null: return
	target.top_level = enabled
	if not enabled: return
	
	var t := Engine.get_physics_interpolation_fraction()
	if not _previous_position_set:
		return
	var interpolated_position : Vector3 = lerp(_previous_position, _target_position, t)
	target.global_position = interpolated_position


func record_position(v: Vector3) -> void:
	_previous_position = _target_position
	_previous_position_set = _target_position_set
	_target_position = v
	_target_position_set = true
