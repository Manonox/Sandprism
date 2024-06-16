extends LuaEntity


func _construct(vm: LuauVM) -> void:
	var position: Vector3 = LuaEnvironment.vector3.export(vm, 1)
	var rotation: Vector3 = LuaEnvironment.angle.export_or(vm, 2, Vector3())
	var size: Vector2 = LuaEnvironment.vector2.export_or(vm, 3, Vector2(1, 1))
	var resolution: Vector2 = LuaEnvironment.vector2.export_or(vm, 4, Vector2(512.0, 512.0))
	
	var lua_instance := LuaEnvironment.get_lua_instance(vm) as LuaInstance
	var entity_component := lua_instance.entity_component
	var entity_manager := entity_component.entity_list.entity_manager
	var node := entity_manager.spawn_entity(entity_component.subspace, &"DigitalScreenProp") as DigitalScreenProp
	
	node.position = position
	node.rotation_degrees = rotation
	node.size = size
	node.resolution = Vector2i(resolution.floor())
	LuaEnvironment.entity.import(vm, node)


func _include(vm: LuauVM) -> void:
	pass

func _metatable(vm: LuauVM) -> void:
	pass

func _extend_library(vm: LuauVM) -> void:
	pass
#
