extends RefCounted
class_name SandprismProjectWorkshopProject


@export var id: int
@export var title: String
@export var author: String
@export var star_count: int
@export var download_count: int
@export var official: bool


static func from_json_dict(json: Dictionary) -> SandprismProjectWorkshopProject:
	var project := SandprismProjectWorkshopProject.new()
	project.id = int(json["id"])
	project.title = json["title"]
	project.author = json["author"]
	project.official = bool(json["official"])
	project.star_count = int(json["star_count"])
	project.download_count = int(json["download_count"])
	return project
