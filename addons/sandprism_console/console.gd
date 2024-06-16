extends Control
class_name Console


const CONSOLE_ENTRY := preload("res://addons/sandprism_console/console_entry.tscn")


signal run(text: String)


var entry_limit := 2000
var loopback_input := true
var input_prefix := "> "


var _darken_next_entry := false
var _snap_queued := false


@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var scroll_bar := scroll_container.get_v_scroll_bar()
@onready var line_edit: LineEdit = %LineEdit
@onready var scroll_down_button: Button = %ScrollDownButton
@onready var entries: VBoxContainer = %Entries


func _ready() -> void:
	_update_scroll_down_button_visibility()
	scroll_container.resized.connect(self._update_scroll_down_button_visibility)
	scroll_container.get_v_scroll_bar().value_changed.connect(self._scroll_bar_value_changed)
	scroll_container.visibility_changed.connect(self._check_if_snap_queued)


func add() -> RichTextLabel:
	var entry := CONSOLE_ENTRY.instantiate()
	entry.gui_input.connect(self._inner_gui_input)
	entries.add_child(entry)
	entry.color_rect.visible = _darken_next_entry
	_darken_next_entry = !_darken_next_entry
	
	var should_snap := !_should_enable_scroll_down_button() or scroll_bar.max_value < scroll_bar.size.y
	if entries.get_child_count() > entry_limit:
		var child := entries.get_child(0) as Control
		var separation := entries.get_theme_constant(&"separation")
		var scroll_change := child.size.y + separation
		entries.remove_child(child)
		scroll_bar.value = maxf(scroll_bar.min_value, scroll_bar.value - scroll_change)
	
	if should_snap:
		snap_down.call_deferred()
	
	_update_scroll_down_button_visibility.call_deferred()
	return entry


func snap_down() -> void:
	if !scroll_bar.is_visible_in_tree():
		_snap_queued = true
	scroll_bar.max_value += 1000000
	scroll_bar.value = scroll_bar.max_value


func _check_if_snap_queued() -> void:
	if _snap_queued:
		snap_down()
		_snap_queued = false


func focus_input() -> void:
	line_edit.grab_focus()


func clear() -> void:
	for child in entries.get_children():
		entries.remove_child(child)


func _should_enable_scroll_down_button() -> bool:
	if scroll_bar.max_value <= scroll_bar.size.y: return false
	return scroll_bar.value < scroll_bar.max_value - scroll_bar.size.y - 1


func _update_scroll_down_button_visibility() -> void:
	scroll_down_button.visible = _should_enable_scroll_down_button()


func _scroll_bar_value_changed(x: float) -> void:
	_update_scroll_down_button_visibility()


func _on_line_edit_text_submitted(new_text: String) -> void:
	line_edit.clear()
	if loopback_input:
		add().add_text(input_prefix + new_text)
	run.emit(new_text)


func _on_scroll_down_button_pressed() -> void:
	snap_down()
	_update_scroll_down_button_visibility()


func _inner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 3 and event.is_pressed():
			_on_scroll_down_button_pressed()
