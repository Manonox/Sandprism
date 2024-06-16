extends Resource
class_name Project


var metadata := {}
var content := {}
var map := {}


func _init() -> void:
	pass


static func _flatten_content(content_: Dictionary, path: String = "") -> Dictionary:
	var result := {}
	for k in content_.dirs:
		var flat := _flatten_content(content_.dirs[k], path + k + "/")
		for flat_k in flat:
			result[flat_k] = flat[flat_k]
	for k in content_.files:
		result[path + k] = content_.files[k]
	return result


func flatten_content() -> void:
	map = Project._flatten_content(content)


func pack() -> PackedByteArray:
	return var_to_bytes([metadata, content])


static func unpack(byte_array: PackedByteArray) -> Project:
	var arr = bytes_to_var(byte_array)
	if !(arr is Array): return null
	var metadata_dict_maybe = arr[0]
	if !(metadata_dict_maybe is Dictionary): return null
	var content_dict_maybe = arr[1]
	if !(content_dict_maybe is Dictionary): return null
	
	var metadata_dict := metadata_dict_maybe as Dictionary
	var content_dict := content_dict_maybe as Dictionary
	
	var project := Project.new()
	project.metadata = metadata_dict
	project.content = content_dict
	project.flatten_content()
	
	if project.map.is_empty(): return null
	for k in project.map:
		if !(k is String): return null
		var v = project.map[k]
		if !(v is PackedByteArray): return null
		
	return project
