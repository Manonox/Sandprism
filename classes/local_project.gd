extends RefCounted
class_name LocalProject


const project_folder_root := "user://projects/"
const content_folder := "content"
const meta_json_filename := "meta.json"


var folder := ""


var _project_folder: String :
	get:
		return project_folder_root + folder


var _content_folder: String :
	get:
		return project_folder_root + folder + "/" + content_folder


func _init(folder_: String = "") -> void:
	folder = folder_
	var root_dir := DirAccess.open("user://")
	root_dir.make_dir_recursive(_content_folder)
	set_project_meta({})


func get_tree() -> Dictionary:
	return LocalProject._get_tree_recursive(folder + "/" + content_folder)


func get_project_meta() -> Dictionary:
	var file_path := _project_folder + "/" + meta_json_filename
	if !DirAccess.open(_project_folder).file_exists(meta_json_filename): return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	var raw := file.get_as_text(true)
	var v = JSON.parse_string(raw)
	if !(v is Dictionary): return {}
	return v


func set_project_meta(data: Dictionary) -> Error:
	var file_path := project_folder_root + folder + "/" + meta_json_filename
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	var s := JSON.stringify(data, "\t")
	file.store_string(s)
	return OK


static func _get_tree_recursive(folder_: String) -> Dictionary:
	var tree := {dirs = {}, files = {}}
	var root_dir := DirAccess.open(project_folder_root + "/" + folder_)
	root_dir.include_hidden = true
	for dir in root_dir.get_directories():
		tree.dirs[dir] = _get_tree_recursive(folder_ + "/" + dir)
	for file in root_dir.get_files():
		tree.files[file] = true #FileAccess.open(project_folder_root + folder_ + file, FileAccess.READ).get_length()
	return tree


func _open_file_at(path: String, mode: int, ignore_existing: bool = false) -> Array:
	if path.ends_with("/"):
		return [ERR_CANT_CREATE, null]
	var root_dir := DirAccess.open(_content_folder)
	var slash_pos := path.rfind("/")
	if slash_pos > -1:
		var dir_path := path.substr(0, slash_pos)
		root_dir.make_dir_recursive(dir_path)
	
	var file_path := _content_folder + "/" + path
	if FileAccess.file_exists(file_path) and !ignore_existing:
		return [ERR_ALREADY_EXISTS, null]
	var file := FileAccess.open(file_path, mode)
	if file == null:
		return [FileAccess.get_open_error(), null]
	return [OK, file]


func make_dir(path: String) -> void:
	var root_dir := DirAccess.open(_content_folder)
	root_dir.make_dir_recursive(path)


func new_file(path: String) -> Error:
	var array := _open_file_at(path, FileAccess.WRITE)
	if array[0] != OK: return array[0]
	var file: FileAccess = array[1]
	file.store_buffer([])
	return OK


func save_file(path: String, text: String) -> Error:
	var array := _open_file_at(path, FileAccess.WRITE, true)
	if array[0] != OK: return array[0]
	var file: FileAccess = array[1]
	file.store_string(text)
	return OK


func add_file(path: String, data: PackedByteArray, ignore_existing: bool = false) -> Error:
	var array := _open_file_at(path, FileAccess.WRITE, ignore_existing)
	if array[0] != OK: return array[0]
	var file: FileAccess = array[1]
	file.store_buffer(data)
	return OK


func read_file_as_text(path: String) -> Array:
	var array := _open_file_at(path, FileAccess.READ, true)
	if array[0] != OK: return array
	var file := array[1] as FileAccess
	return [OK, file.get_as_text(true)]

func read_file(path: String) -> Array:
	var array := _open_file_at(path, FileAccess.READ, true)
	if array[0] != OK: return array
	var file := array[1] as FileAccess
	return [OK, file.get_buffer(file.get_length())]


func remove_file(path: String) -> Error:
	var root_dir := DirAccess.open(_content_folder)
	return root_dir.remove(path)


func clear() -> Error:
	var err := delete()
	if err != OK: return err
	var root_dir := DirAccess.open("user://")
	root_dir.make_dir_recursive(_content_folder)
	set_project_meta({})
	return OK


func delete() -> Error:
	return OS.move_to_trash(ProjectSettings.globalize_path(_project_folder))


static func _export_tree(tree: Dictionary, path: String = "") -> Dictionary:
	var result := {dirs = {}, files = {}}
	for k in tree.dirs:
		result.dirs[k] = _export_tree(tree.dirs[k], path + k + "/")
	for k in tree.files:
		var file := FileAccess.open(path + k, FileAccess.READ)
		result.files[k] = file.get_buffer(file.get_length())
	return result

func export() -> Project:
	var project := Project.new()
	project.metadata = get_project_meta()
	project.content = LocalProject._export_tree(get_tree(), _content_folder + "/")
	return project


static func import(path: String, project: Project) -> Error:
	return ERR_HELP
