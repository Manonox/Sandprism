extends Node
class_name LuaEntities

const object_key := "__base"

var _entity_lookup : Dictionary = {}


func import(vm: LuauVM, node: Node) -> void:
	var lua_component_maybe := node.get_node_or_null(^"LuaComponent")
	assert(lua_component_maybe is LuaComponent, "Missing LuaComponent")
	var lua_component := lua_component_maybe as LuaComponent
	
	vm.lua_newtable()
	vm.lua_pushobject(node)
	vm.lua_setfield(-2, object_key)
	vm.luaL_getmetatable(lua_component.entity_type)
	vm.lua_setmetatable(-2)


func export_get_type(vm: LuauVM, index: int) -> StringName:
	vm.luaL_argcheck(vm.lua_istable(index), index, "invalid argument #%s (expected Entity, got %s)" % [index, LuaUtils.godot_typeof(vm, index)])
	vm.lua_getfield(-1, object_key)
	vm.luaL_argcheck(vm.lua_isobject(-1), index, "invalid argument #%s (expected Entity, got %s)" % [index, LuaUtils.godot_typeof(vm, index)])
	vm.luaL_argcheck(vm.lua_isvalidobject(-1), index, "null entity as argument #%s" % [index])
	var object : Object = vm.lua_toobject(-1)
	vm.lua_pop()
	vm.luaL_argcheck(object is Node, index, "invalid entity at argument #%s" % [index])
	var node := object as Node
	
	var lua_component := _export_get_lua_component(vm, node, -1)
	return lua_component.entity_type


func export_type(vm: LuauVM, entity_type: StringName, index: int) -> Node:
	vm.luaL_argcheck(vm.lua_istable(index), index, "invalid argument #%s (expected %s, got %s)" % [index, entity_type, LuaUtils.godot_typeof(vm, index)])
	vm.lua_getfield(-1, object_key)
	vm.luaL_argcheck(vm.lua_isobject(-1), index, "invalid argument #%s (expected %s, got %s)" % [index, entity_type, LuaUtils.godot_typeof(vm, index)])
	vm.luaL_argcheck(vm.lua_isvalidobject(-1), index, "null entity as argument #%s" % [index])
	var object : Object = vm.lua_toobject(-1)
	vm.lua_pop()
	vm.luaL_argcheck(object is Node, index, "invalid entity at argument #%s" % [index])
	var node := object as Node
	
	var lua_component := _export_get_lua_component(vm, node, -1)
	var node_entity_type := lua_component.entity_type
	vm.luaL_argcheck(node_entity_type == entity_type, index, "invalid argument #%s (expected %s, got %s)" % [index, entity_type, node_entity_type])
	return node


func _concat_mixins(mixins: Array[StringName]) -> String:
	var mixin_concat := ""
	for i in range(mixins.size()):
		mixin_concat += mixins[i]
		if i < mixins.size() - 1:
			mixin_concat += ", "
	return mixin_concat


func export_mixins(vm: LuauVM, entity_mixins: Array[StringName], index: int) -> Node:
	if !vm.lua_istable(index):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Entity<%s>, got %s)" % [index, _concat_mixins(entity_mixins), LuaUtils.godot_typeof(vm, index)])
	
	vm.lua_getfield(index, object_key)
	
	if !vm.lua_isobject(-1):
		vm.luaL_argcheck(false, index, "invalid argument #%s (expected Entity<%s>, got %s)" % [index, _concat_mixins(entity_mixins), LuaUtils.godot_typeof(vm, index)])
	if !vm.lua_isvalidobject(-1):
		vm.luaL_argcheck(false, index, "null entity as argument #%s" % index)
	
	var object : Object = vm.lua_toobject(-1)
	vm.lua_pop()
	if !(object is Node):
		vm.luaL_argcheck(false, index, "invalid entity at argument #%s" % index)
	var node := object as Node
	
	var lua_component := _export_get_lua_component(vm, node, -1)
	var entity_type := lua_component.entity_type
	var entity_maybe = _entity_lookup.get(entity_type)
	if entity_maybe == null:
		entity_maybe = get_node(NodePath(entity_type)) as LuaEntity
		assert(entity_maybe, "no entity type node..?")
		_entity_lookup[entity_type] = entity_maybe
	var entity := entity_maybe as LuaEntity
	
	for required_mixin in entity_mixins:
		if !entity.mixin_set.has(required_mixin):
			vm.luaL_argcheck(false, index, "invalid argument #%s (expected Entity<%s>, got %s)" % [index, _concat_mixins(entity_mixins), entity_type])
	return node


func export_mixin(vm: LuauVM, entity_mixin: StringName, index: int) -> Node:
	return export_mixins(vm, [entity_mixin], index)


func _export_get_lua_component(vm: LuauVM, node: Node,  index: int) -> LuaComponent:
	var lua_component_maybe := node.get_node_or_null(^"LuaComponent")
	if !(lua_component_maybe is LuaComponent):
		vm.luaL_argcheck(false, index, "invalid entity at argument #%s" % index)
	return lua_component_maybe


func load_entity_libraries(vm: LuauVM) -> void:
	var lua_instance := LuaEnvironment.vm_to_instance[vm] as LuaInstance
	var is_server := lua_instance.multiplayer.is_server() if lua_instance != null else false
	
	for entity: LuaEntity in get_children():
		var entity_class := entity.name
		
		# Create library
		vm.lua_newtable()
		vm.lua_newtable()
		if is_server:
			vm.lua_pushcallable(entity.construct)
		else:
			vm.lua_pushcallable(self._cant_construct)
		vm.lua_setfield(-2, "__call")
		vm.lua_setmetatable(-2)
		
		# Metatable
		vm.luaL_newmetatable(entity_class)
		vm.lua_newtable() # __index
		for mixin_name in entity.mixins:
			var mixin := LuaEnvironment.mixins.get_node(NodePath(mixin_name)) as LuaMixin
			assert(mixin != null, "Bad mixin %s" % mixin_name)
			mixin.include(vm)
		entity.include(vm)
		vm.lua_setfield(-2, "__index")
		vm.lua_pushcallable(self._default_tostring, "__tostring")
		vm.lua_setfield(-2, "__tostring")
		entity.metatable(vm)
		
		# Add metatable to library
		vm.lua_setfield(-2, "metatable")
		LuaEnvironment.require.add_package(vm, "entity/" + entity_class)


func _default_tostring(vm: LuauVM) -> int:
	var entity_type := export_get_type(vm, 1) as String
	vm.lua_pushstring(entity_type)
	return 1


func _cant_construct(vm: LuauVM) -> int:
	vm.luaL_error("attempt to spawn entity on clientside")
	return 0
