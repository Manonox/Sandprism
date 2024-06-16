extends Panel


var project: SandprismProjectWorkshopProject :
	set(value):
		title.text = value.title
		title.tooltip_text = value.title
		author.text = "by " + value.author
		star_count.text = str(value.star_count)
		fork_count.text = str(value.download_count)
		official_check.visible = value.official
	get:
		return project


@onready var title: Label = %Title
@onready var author: Label = %Author
@onready var star_count: Label = %StarCount
@onready var fork_count: Label = %ForkCount
@onready var official_check: TextureRect = %OfficialCheck

@onready var star: Button = %Star
@onready var fork: Button = %Fork
