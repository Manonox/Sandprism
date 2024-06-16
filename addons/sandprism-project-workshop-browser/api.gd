extends Node
class_name SandprismProjectWorkshopAPI


@export var endpoint: String = "http://127.0.0.1:8000/sandprism/" #"https://manonox.com/sandprism/"


func _ready() -> void:
	pass


func projects_search(query: String, searchby: String, sortby: String, order: String, page: int, official_only: bool = false) -> Array:
	var args := {
		query = query,
		by = searchby,
		order = order,
		sortby = sortby,
		page = page,
	}
	
	if official_only:
		args["official_only"] = true
	
	var search := HTTPRequest.new()
	search.timeout = 1.0
	add_child(search)
	var err := search.request(endpoint + "projects/search" + _make_args(args), [], HTTPClient.METHOD_GET, "")
	var arr = await search.request_completed
	remove_child(search)
	var result: int = arr[0]
	var response_code: int = arr[1]
	var headers: PackedStringArray = arr[2]
	var body: PackedByteArray = arr[3]
	
	if response_code == 204:
		return []
	if response_code != 200:
		push_warning("projects/search returned %s" % response_code)
		return []
	var str_body := body.get_string_from_utf8()
	var json_arr := JSON.parse_string(str_body) as Array
	var projects: Array[SandprismProjectWorkshopProject] = []
	for dict in json_arr:
		projects.append(SandprismProjectWorkshopProject.from_json_dict(dict))
	return projects


func projects_download(id: int) -> Dictionary:
	var args := {
		id = str(id)
	}
	
	var download := HTTPRequest.new()
	add_child(download)
	var err := download.request(endpoint + "projects/download" + _make_args(args), [], HTTPClient.METHOD_GET, "")
	var arr = await download.request_completed
	remove_child(download)
	var result: int = arr[0]
	var response_code: int = arr[1]
	var headers: PackedStringArray = arr[2]
	var body: PackedByteArray = arr[3]
	if response_code == 204:
		return {}
	if response_code != 200:
		push_warning("projects/download returned %s" % response_code)
		return {}
	var str_body := body.get_string_from_utf8()
	var json_dict := JSON.parse_string(str_body) as Dictionary
	return json_dict


func projects_upload(title: String, author: String, data: String) -> int:
	var args := {
		title = title,
		author = author,
	}
	
	var headers := [
		"Content-Type: application/json"
	]
	
	var upload := HTTPRequest.new()
	add_child(upload)
	var err := upload.request(endpoint + "projects/upload" + _make_args(args), headers, HTTPClient.METHOD_POST, data)
	var arr = await upload.request_completed
	remove_child(upload)
	
	var result: int = arr[0]
	var response_code: int = arr[1]
	var _headers: PackedStringArray = arr[2]
	var body: PackedByteArray = arr[3]
	if response_code == 429:
		return -1
	if response_code != 200:
		push_warning("projects/upload returned %s" % response_code)
		return -1
	var str_body := body.get_string_from_utf8()
	var json_dict := JSON.parse_string(str_body) as Dictionary
	return json_dict.get("id", -1) as int
	


func projects_star(username: String, id: int) -> bool:
	var args := {
		username = username,
		id = str(id),
	}
	
	var star := HTTPRequest.new()
	add_child(star)
	var err := star.request(endpoint + "projects/star" + _make_args(args), [], HTTPClient.METHOD_PATCH, "")
	var arr = await star.request_completed
	remove_child(star)
	
	var result: int = arr[0]
	var response_code: int = arr[1]
	var headers: PackedStringArray = arr[2]
	var body: PackedByteArray = arr[3]
	if response_code != 200:
		push_warning("projects/star returned %s" % response_code)
		return false
	return true


func _make_args(dict: Dictionary) -> String:
	var s := ""
	var first := true
	for k in dict:
		if first:
			s += "?"
			first = false
		else:
			s += "&"
		var v = dict[k]
		var v_str: String
		if typeof(v) == TYPE_STRING or typeof(v) == TYPE_STRING_NAME:
			v_str = v
		else:
			v_str = var_to_str(v)
		s += "%s=%s" % [k, v_str.uri_encode()]
	return s
