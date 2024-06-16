extends Node
class_name IPlayerMovement


@export var input_structure: Dictionary
@export var state_structure: Dictionary


func make_input_table() -> StructuredTable:
	var table := StructuredTable.new()
	table.structure = input_structure
	return table


func make_state_table() -> StructuredTable:
	var table := StructuredTable.new()
	table.structure = state_structure
	return table


func _write_state(table: StructuredTable) -> void:
	pass


func _read_state(table: StructuredTable) -> void:
	pass


func _write_local_input(table: StructuredTable) -> void:
	pass


func _simulate(input_table: StructuredTable, delta: float) -> void:
	pass



func write_state(table: StructuredTable) -> void:
	_write_state(table)


func read_state(table: StructuredTable) -> void:
	_read_state(table)


func write_local_input(table: StructuredTable) -> void:
	_write_local_input(table)


func simulate(input_table: StructuredTable, delta: float) -> void:
	_simulate(input_table, delta)
