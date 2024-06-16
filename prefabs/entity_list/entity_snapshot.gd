extends RefCounted
class_name EntitySnapshot


var data := []
var config: SceneReplicationConfig

var _is_empty := true

func _init(x) -> void:
	if x is SceneReplicationConfig:
		config = x
	if x is EntitySnapshot:
		data = x.data.duplicate(true)
		config = x.config
		_is_empty = x._is_empty

func read(node: Node) -> EntitySnapshot:
	var properties := config.get_properties()
	data = []
	data.resize(properties.size())
	for i in range(0, properties.size()): 
		var nodepath := properties[i]
		var target_node := node.get_node(NodePath(nodepath.get_concatenated_names()))
		data[i] = target_node.get_indexed(NodePath(nodepath.get_concatenated_subnames()))
	if properties.size() == 0:
		_is_empty = true
	return self


func read_delta(node: Node, previous_snapshot: EntitySnapshot, is_sync: bool = true) -> EntitySnapshot:
	var properties := config.get_properties()
	var count := data.size()
	for i in range(0, data.size()):
		if previous_snapshot.data[i] == data[i] or !config.property_get_sync(properties[i]):
			data[i] = null
			count -= 1
	_is_empty = count == 0
	return self


func write(node: Node) -> void:
	var properties := config.get_properties()
	for i in range(0, data.size()):
		var value = data[i]
		if value != null:
			var nodepath := properties[i]
			var target_node := node.get_node(NodePath(nodepath.get_concatenated_names()))
			target_node.set_indexed(NodePath(nodepath.get_concatenated_subnames()), value)


func is_empty() -> bool:
	return _is_empty

func decode(byte_array: PackedByteArray) -> bool:
	var array_maybe = bytes_to_var(byte_array)
	if not (array_maybe is Array):
		return false
	data = array_maybe
	_is_empty = false
	return true


func to_byte_array() -> PackedByteArray:
	return var_to_bytes(data)
