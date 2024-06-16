extends Node
class_name LuaConsoleReceiver


@export var client_color := Color(1, 1, 1)
@export var server_color := Color(1, 1, 1)
@export var error_color := Color(0.25, 0, 0, 0.4)
@export var empty_color := Color(0.2, 0.2, 0.2, 0.4)


func _get_color(on_server: bool) -> Color:
	return server_color if on_server else client_color


func stdout(content: String, on_server: bool, console: Console) -> void:
	var entry := console.add()
	entry.push_color(_get_color(on_server))
	if content.is_empty():
		content = "<empty>"
		entry.push_italics()
		entry.push_fgcolor(empty_color)
	entry.add_text(content)
	entry.pop()
	if content.is_empty():
		entry.pop()
		entry.pop()

func stderr(content: String, on_server: bool, console: Console) -> void:
	var entry := console.add()
	entry.push_color(_get_color(on_server))
	entry.push_bgcolor(error_color)
	entry.add_text(content)
	entry.pop()
	entry.pop()
