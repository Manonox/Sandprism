extends Resource
class_name EntityListSnapshot


var tick: int
var commands: Array[EntityListCommand] = []
var is_valid := true


func _init(tick_: int) -> void:
	tick = tick_


static func new_invalid() -> EntityListSnapshot:
	var snapshot := EntityListSnapshot.new(-1)
	snapshot.is_valid = false
	return snapshot


func push_command(command: EntityListCommand) -> void:
	commands.push_back(command)


func apply(entity_list: EntityList) -> void:
	for command in commands:
		#print("CL <- %s: %s" % [entity_list.multiplayer.get_unique_id(), command])
		command.apply(entity_list, tick)


func is_empty() -> bool:
	return commands.size() == 0


static func decode(byte_array: PackedByteArray) -> EntityListSnapshot:
	var array_maybe = bytes_to_var(byte_array)
	if not (array_maybe is Array):
		return new_invalid()
	var array: Array = array_maybe as Array
	
	if array.size() < 1:
		return new_invalid()
	
	var tick_maybe = array[0]
	if not (tick_maybe is int):
		return new_invalid()
	var tick_: int = tick_maybe as int
	
	var commands_: Array[EntityListCommand] = []
	
	if array.size() > 1:
		commands_.resize(array.size() - 1)
		for i in range(1, array.size()):
			var command_byte_array_maybe = array[i]
			if not (command_byte_array_maybe is PackedByteArray):
				return new_invalid()
			var command_byte_array: PackedByteArray = command_byte_array_maybe as PackedByteArray
			var command := EntityListCommand.decode(command_byte_array)
			commands_[i - 1] = command
		
	var snapshot := EntityListSnapshot.new(tick_)
	snapshot.commands = commands_
	return snapshot


func to_byte_array() -> PackedByteArray:
	var array := [tick]
	for command in commands:
		var command_byte_array := command.to_byte_array()
		array.append(command_byte_array)
	return var_to_bytes(array)
