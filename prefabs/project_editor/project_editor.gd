extends Control
class_name ProjectEditor


@onready var luau_edit: LuauEdit = %LuauEdit


func _ready() -> void:
	var local_project := LocalProject.new("test")
	var array = local_project.read_file_as_text("main.lua")
	if array[0] == OK:
		luau_edit.text = array[1]
	else:
		push_warning(error_string(array[0]))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"lua_run"):
		run()
	
	if !visible: return
	if event.is_action_pressed(&"lua_editor_save"):
		save()


func run() -> void:
	save()
	
	var local_project := LocalProject.new("test")
	local_project.set_project_meta({})
	local_project.save_file("main.lua", luau_edit.text)
	
	var project := local_project.export()
	var byte_array := project.pack()
	
	if Network.client_tcp_peer == null:
		push_warning("Client TCP peer not ready!")
		return
	var compressed_byte_array := byte_array.compress()
	Network.client_tcp_send("project_run", compressed_byte_array)


func save() -> void:
	var local_project := LocalProject.new("test")
	local_project.save_file("main.lua", luau_edit.text)


func _on_run_button_pressed() -> void:
	run()
