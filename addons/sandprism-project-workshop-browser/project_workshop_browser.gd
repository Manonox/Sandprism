extends Panel
class_name SandprismProjectBrowser



var _project_card_scene := preload("res://addons/sandprism-project-workshop-browser/project_card.tscn")

var page_index := 0 :
	set(value):
		page_index_node.text = "Page " + str(value + 1)
		page_index = value
	get:
		return page_index

var max_page_index := -1


var _busy := false


@onready var api: SandprismProjectWorkshopAPI = $SandprismProjectWorkshopAPI
@onready var result_grid: GridContainer = %ResultGrid

@onready var query: LineEdit = %Query
@onready var search_by: OptionButton = %SearchBy
@onready var sort_by: OptionButton = %SortBy
@onready var sort_direction: OptionButton = %SortDirection
@onready var your_projects: CheckBox = %YourProjects
@onready var official_only: CheckBox = %OfficialOnly

@onready var no_results_label: Label = %NoResultsLabel
@onready var cant_connect_label: Label = %CantConnectLabel

@onready var back_button: Button = %BackButton
@onready var page_index_node: Label = %PageIndex
@onready var forward_button: Button = %ForwardButton


func _ready() -> void:
	sort_direction.disabled = true
	sort_direction.select(1)
	update_search()


func update_search() -> void:
	if _busy:
		return
	_busy = true
	
	var search_by_str := "title" if search_by.selected <= 0 else "author"
	var sort_by_str := "stars" if sort_by.selected <= 0 else "title"
	var sort_direction_str := "asc" if sort_direction.selected <= 0 else "desc"
	var arr := await api.projects_search(query.text, search_by_str, sort_by_str, sort_direction_str, page_index, official_only.button_pressed)
	set_search_results(arr)
	
	var next_arr := await api.projects_search(query.text, search_by_str, sort_by_str, sort_direction_str, page_index + 1, official_only.button_pressed)
	print(next_arr)
	if next_arr.is_empty():
		max_page_index = page_index
	
	_busy = false


func set_search_results(arr: Array[SandprismProjectWorkshopProject]) -> void:
	for child in result_grid.get_children():
		result_grid.remove_child(child)
	var i := 0
	for project in arr:
		var project_card := _project_card_scene.instantiate()
		result_grid.add_child(project_card)
		project_card.project = project
		i += 1
		if i > 7:
			break
	if i < 8:
		for j in range(i, 8):
			var control := Control.new()
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			result_grid.add_child(control)


func _on_query_text_submitted(new_text: String) -> void:
	update_search()

func _on_search_by_item_selected(index: int) -> void:
	update_search()

func _on_sort_by_item_selected(index: int) -> void:
	if _busy: return
	if index == 0:
		sort_direction.disabled = true
		sort_direction.select(1)
	else:
		sort_direction.disabled = false
		sort_direction.select(0)
	update_search()

func _on_sort_direction_item_selected(index: int) -> void:
	update_search()


func _on_official_only_toggled(toggled_on: bool) -> void:
	update_search()


func _on_back_button_pressed() -> void:
	if _busy: return
	if page_index <= 0:
		return
	page_index -= 1
	update_search()

func _on_forward_button_pressed() -> void:
	if _busy: return
	if max_page_index != -1 and page_index >= max_page_index:
		return
	page_index += 1
	update_search()
