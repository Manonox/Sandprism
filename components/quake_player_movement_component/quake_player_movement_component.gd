extends IPlayerMovement
class_name QuakePlayerMovementComponent


@export var player: CharacterBody3D
@export var properties: PlayerMovementProperties
@export var horizontal_anchor: Node3D
@export var vertical_anchor: Node3D


var on_ground := false
var touching_ground := false


var _input: StructuredTable
var _dt := 0.0


func _write_state(table: StructuredTable) -> void:
	table.position = player.position
	table.velocity = player.velocity
	table.on_ground = on_ground
	table.touching_ground = touching_ground


func _read_state(table: StructuredTable) -> void:
	player.position = table.position
	player.velocity = table.velocity
	on_ground = table.on_ground
	touching_ground = table.touching_ground


func _write_local_input(table: StructuredTable) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var keydir_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var keydir_3d := Vector3(keydir_2d.x, 0, keydir_2d.y)
	var direction = (horizontal_anchor.global_transform.basis * keydir_3d).normalized()
	table.wish_direction = direction
	
	table.wish_fly_direction = (vertical_anchor.global_transform.basis * keydir_3d).normalized()
	table.wish_fly = Input.is_mouse_button_pressed(MOUSE_BUTTON_XBUTTON1)
	
	table.wish_jump = Input.is_action_pressed("move_jump")
	table.look_rotation = vertical_anchor.global_rotation


func _simulate(table: StructuredTable, delta: float) -> void:
	_input = table
	_dt = delta
	
	if table.wish_fly:
		player.velocity = table.wish_fly_direction * 15.0
		player.move_and_slide()
		return
	
	_apply_gravity(0.5)
	_friction()
	_accelerate()
	_accelerate_glider()
	on_ground = false
	touching_ground = false
	_float()
	_check_up_velocity()
	_try_jump()
	_apply_gravity(0.5)
	
	player.move_and_slide()
	for i in range(player.get_slide_collision_count()):
		_handle_collision(player.get_slide_collision(i))
	_check_up_velocity()
	if on_ground:
		player.velocity.y = 0.0


func _accelerate() -> void:
	var wish_direction : Vector3 = _input.wish_direction
	wish_direction = _sanitize_wish_direction(wish_direction)
	
	var wish_speed := properties.max_speed if on_ground else properties.air_limit
	var current_speed := player.velocity.dot(wish_direction)
	var add_speed := wish_speed - current_speed
	if add_speed < 0.0:
		return
	
	var acceleration := properties.ground_acceleration if on_ground else properties.air_acceleration
	var acceleration_speed := minf(acceleration * wish_speed * _dt, add_speed)
	player.velocity += wish_direction * acceleration_speed


func _accelerate_glider() -> void:
	if not _input.wish_jump:
		return
	var wish_direction : Vector3 = Basis.from_euler(_input.look_rotation).y
	
	var wish_speed := 0.5
	var current_speed := player.velocity.dot(wish_direction)
	var add_speed := wish_speed - current_speed
	if add_speed < 0.0:
		return
	
	var acceleration := 100000000.0
	var acceleration_speed := minf(acceleration * wish_speed * _dt, add_speed)
	player.velocity += wish_direction * acceleration_speed


func _friction() -> void:
	if not on_ground:
		return
	
	var speed_squared := player.velocity.length_squared()
	if speed_squared < 0.001:
		player.velocity = Vector3()
		return
	
	var speed := pow(speed_squared, 0.5)
	var control := maxf(properties.stopspeed, speed)
	var drop := control * properties.friction * _dt
	
	var newspeed := maxf(speed - drop, 0.0)
	player.velocity *= newspeed / speed


func _apply_gravity(multiplier: float) -> void:
	player.velocity.y -= properties.gravity * multiplier * _dt


func _check_up_velocity() -> void:
	if player.velocity.y > 3.0:
		on_ground = false


func _try_jump() -> void:
	if not _input.wish_jump:
		return
	if not touching_ground:
		return
	_jump()


func _jump() -> void:
	on_ground = false
	player.velocity.y = properties.jump_power


func _float() -> void:
	var float_height := properties.float_height
	var collision := player.move_and_collide(Vector3(0.0, -float_height, 0.0), true)
	if collision == null:
		return
	_handle_collision(collision)
	var updraft := collision.get_remainder().length()
	updraft = pow(updraft, 2.0)
	updraft = minf(updraft, 4.0 * float_height * _dt)
	if collision.get_travel().length() < 0.01:
		player.position.y += 0.004
	player.move_and_collide(Vector3(0.0, updraft, 0.0))


func _handle_collision(collision: KinematicCollision3D) -> void:
	if collision == null:
		return
	for i in range(collision.get_collision_count()):
		var normal := collision.get_normal(i)
		var is_ground := normal.dot(Vector3(0.0, 1.0, 0.0)) > 0.7
		if is_ground:
			touching_ground = true
		if normal.dot(player.velocity) <= 0.0:
			player.velocity = player.velocity.slide(normal)
			if is_ground:
				on_ground = true


func _sanitize_wish_direction(wish_direction: Vector3) -> Vector3:
	var up := horizontal_anchor.transform.basis.y
	var up_component := wish_direction.dot(up) * up
	wish_direction = wish_direction - up_component
	return wish_direction.normalized()
