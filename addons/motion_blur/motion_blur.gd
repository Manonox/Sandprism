extends MeshInstance3D



@export_range(0.0, 10.0, 0.01) var linear_multiplier : float = 1.0
@export_range(0.0, 10.0, 0.01) var angular_multiplier : float = 1.0
@export_range(0.0, 1.0, 0.01) var intensity : float = 0.28
@export_range(2, 50) var iteration_count : int = 15
@export_range(0.0, 10.0, 0.01) var falloff_radius : float = 0.0

var cam_pos_prev := Vector3()
var cam_rot_prev := Quaternion()


func _process(_delta):
	if multiplayer.is_server():
		queue_free()
	var mat: ShaderMaterial = get_surface_override_material(0)
	# Linear velocity is just difference in positions between two frames.
	var cam := get_viewport().get_camera_3d()
	if cam == null: return
	var velocity := cam.global_transform.origin - cam_pos_prev
	
	# Angular velocity is a little more complicated, as you can see.
	# See https://math.stackexchange.com/questions/160908/how-to-get-angular-velocity-from-difference-orientation-quaternion-and-time
	var cam_rot := Quaternion(cam.global_transform.basis)
	var cam_rot_diff := cam_rot - cam_rot_prev
	var cam_rot_conj := conjugate(cam_rot)
	var ang_vel := (cam_rot_diff * 2.0) * cam_rot_conj;
	var vec_ang_vel := Vector3(ang_vel.x, ang_vel.y, ang_vel.z) # Convert Quat to Vector3
	
	# Optimize
	mat.set_shader_parameter("linear_velocity", velocity * linear_multiplier)
	mat.set_shader_parameter("angular_velocity", vec_ang_vel * angular_multiplier)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("iteration_count", iteration_count)
	mat.set_shader_parameter("falloff_radius", falloff_radius)
		
	cam_pos_prev = cam.global_transform.origin
	cam_rot_prev = Quaternion(cam.global_transform.basis)


# Calculate the conjugate of a quaternion.
func conjugate(quat) -> Quaternion:
	return Quaternion(-quat.x, -quat.y, -quat.z, quat.w)
