@tool
extends RigidBody3D
class_name DigitalScreenProp


@export var size := Vector2(1, 1) :
	set(value):
		size = value
		_update()

@export var resolution := Vector2i(1024, 1024) :
	set(value):
		resolution = value
		_update()

@export var transparent := false :
	set(value):
		transparent = value
		if screen_material != null:
			screen_material.set_shader_parameter(&"transparent", value)


@export var material: Material
@export var screen_material: ShaderMaterial


var pixel_effect_enabled := true :
	set(value):
		pixel_effect_enabled = value
		screen_material.set_shader_parameter(&"pixelation_enabled", value)


var image: Image
var _image_texture := ImageTexture.new()
var _update_queued := false
var _screen_update_in := 0.0


@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var screen: MeshInstance3D = $Screen

func _ready() -> void:
	if !Engine.is_editor_hint():
		screen_material = screen_material.duplicate(true)


func _physics_process(delta: float) -> void:
	if _update_queued:
		_update()
		_update_queued = false
		
	if _screen_update_in > 0.0:
		_screen_update_in -= delta
		if _screen_update_in <= 0.0:
			_image_texture.update(image)


func update() -> void:
	_update_queued = true


func _update() -> void:
	if !is_node_ready(): return
	if !Engine.is_editor_hint() and multiplayer.is_server(): return
	
	var mesh := BoxMesh.new()
	var size_3d := Vector3(size.x, size.y, 0.04)
	mesh.size = size_3d
	mesh.material = material
	mesh_instance_3d.mesh = mesh
	
	var shape := BoxShape3D.new()
	shape.size = size_3d
	collision_shape_3d.shape = shape
	screen.position = Vector3(0.0, 0.0, 0.02)
	
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = size
	screen.mesh = quad_mesh
	screen.material_override = screen_material
	
	screen_material.set_shader_parameter(&"resolution", resolution)
	
	if !Engine.is_editor_hint():
		image = Image.create(resolution.x, resolution.y, false, Image.FORMAT_RGBAF)
		_image_texture = ImageTexture.create_from_image(image)
		screen_material.set_shader_parameter(&"content_texture", _image_texture)


@rpc("authority", "call_remote", "reliable")
func set_pixel(v: Vector2i, color: Color) -> void:
	if !multiplayer.is_server():
		image.set_pixelv(v, color)
		if _screen_update_in <= 0:
			_screen_update_in = 0.1
	else:
		await get_tree().create_timer(0.2).timeout
		set_pixel.rpc(v, color)


@rpc("authority", "call_remote", "reliable")
func set_pixel_effect_enabled(b: bool) -> void:
	if !multiplayer.is_server():
		pixel_effect_enabled = b
	else:
		await get_tree().create_timer(0.2).timeout
		set_pixel_effect_enabled.rpc(b)

