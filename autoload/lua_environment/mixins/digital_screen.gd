extends LuaMixin


var _methods := {
	setPixel = self._set_pixel,
	getPixel = self._get_pixel,
	
	setPixelEffectEnabled = self._set_pixel_effect_enabled,
	getPixelEffectEnabled = self._get_pixel_effect_enabled
}


func _include(vm: LuauVM) -> void:
	LuaUtils.merge_dictionary(vm, _methods)


func _set_pixel(vm: LuauVM) -> int:
	var digital_screen := LuaEnvironment.entity.export_mixin(vm, &"DigitalScreen", 1) as DigitalScreenProp
	var v := LuaEnvironment.vector2.export(vm, 2) as Vector2
	var color := LuaEnvironment.color.export(vm, 3) as Color
	digital_screen.set_pixel(Vector2i(v.floor()), color)
	return 0


func _get_pixel(vm: LuauVM) -> int:
	if multiplayer.is_server():
		vm.luaL_error("Can't use getPixel on server")
		return 0
	
	var digital_screen := LuaEnvironment.entity.export_mixin(vm, &"DigitalScreen", 1) as DigitalScreenProp
	var v := LuaEnvironment.vector2.export(vm, 2) as Vector2
	var color := digital_screen.image.get_pixelv(v)
	LuaEnvironment.color.import(vm, color, true)
	return 1


func _set_pixel_effect_enabled(vm: LuauVM) -> int:
	var digital_screen := LuaEnvironment.entity.export_mixin(vm, &"DigitalScreen", 1) as DigitalScreenProp
	var enabled := vm.lua_toboolean(2)
	digital_screen.set_pixel_effect_enabled(enabled)
	return 0


func _get_pixel_effect_enabled(vm: LuauVM) -> int:
	if multiplayer.is_server():
		vm.luaL_error("Can't use getPixelEffectEnabled on server")
		return 0
	
	var digital_screen := LuaEnvironment.entity.export_mixin(vm, &"DigitalScreen", 1) as DigitalScreenProp
	vm.lua_pushboolean(digital_screen.pixel_effect_enabled)
	return 1
