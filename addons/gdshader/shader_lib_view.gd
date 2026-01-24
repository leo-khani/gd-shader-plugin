## GDShader Library Main View
## Displays a browsable grid of shaders fetched from the GDShader API
@tool
extends Control

@onready var httprequest: HTTPRequest = $HTTPRequest
@onready var grid_container: GridContainer = %GridContainer
@onready var toast_label: Label = %ToastLabel
@onready var search: TextEdit = %Search
@onready var post_new_btn: Button = %PostNewBtn
@onready var hbox_pages: HBoxContainer = $MarginContainer/VBoxContainer/HBoxPages

const SHADER_CARD = preload("res://addons/gdshader/shader_card.tscn")
const API_URL = "https://api.gdshader.com/shaders/"

var is_fetching: bool = false
var toast_timer: Timer
var search_timer: Timer
var current_page: int = 1
var total_pages: int = 1

func _ready():
	visibility_changed.connect(_on_visibility_changed)
	httprequest.request_completed.connect(_on_request_completed)
	post_new_btn.pressed.connect(_on_post_new_btn_pressed)
	
	_setup_toast_timer()
	_setup_search_timer()
	
	if is_visible_in_tree():
		fetch_shaders(1)


func _setup_toast_timer() -> void:
	toast_timer = Timer.new()
	add_child(toast_timer)
	toast_timer.one_shot = true
	toast_timer.timeout.connect(_on_toast_timeout)


func _setup_search_timer() -> void:
	search_timer = Timer.new()
	add_child(search_timer)
	search_timer.one_shot = true
	search_timer.wait_time = 0.5
	search_timer.timeout.connect(_on_search_timer_timeout)
	
	if search:
		search.text_changed.connect(_on_search_text_changed)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		fetch_shaders(1)


func _on_search_text_changed() -> void:
	search_timer.start()


func _on_search_timer_timeout() -> void:
	fetch_shaders(1)

## Fetch shaders from the API with optional search query
func fetch_shaders(page: int = 1) -> void:
	if is_fetching:
		return
	
	var search_query = ""
	if search:
		search_query = search.text.strip_edges()
	
	var url = API_URL + "?page=" + str(page) + "&per_page=20"
	if search_query != "":
		url += "&search=" + search_query.uri_encode()
	
	is_fetching = true
	var status_msg = "Searching (Page %d)..." % page if search_query else "Fetching (Page %d)..." % page
	show_toast(status_msg, false)
	
	var error = httprequest.request(url)
	if error != OK:
		show_toast("Error: Failed to start HTTP request", true)
		is_fetching = false

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_fetching = false
	
	if response_code != 200:
		show_toast("Error: API returned code %d" % response_code, true)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		show_toast("Error: Failed to parse response", true)
		return

	var shaders_data = []
	if typeof(json) == TYPE_DICTIONARY and json.has("data"):
		shaders_data = json["data"]
		current_page = int(json.get("page", 1))
		total_pages = int(json.get("total_pages", 1))
		_update_pagination_controls()
	elif typeof(json) == TYPE_ARRAY:
		shaders_data = json
		current_page = 1
		total_pages = 1
		_update_pagination_controls()
	else:
		show_toast("Error: Unexpected response format", true)
		return

	var shader_count = shaders_data.size()
	show_toast("Loaded %d shader%s" % [shader_count, "s" if shader_count != 1 else ""], false)
	populate_grid(shaders_data)

func _update_pagination_controls() -> void:
	if not hbox_pages:
		return
		
	for child in hbox_pages.get_children():
		child.queue_free()
	
	# Previous Button
	var prev_btn = Button.new()
	prev_btn.text = "<"
	prev_btn.disabled = current_page <= 1
	prev_btn.pressed.connect(func(): fetch_shaders(current_page - 1))
	hbox_pages.add_child(prev_btn)
	
	# Page Label
	var label = Label.new()
	label.text = "Page %d / %d" % [current_page, max(1, total_pages)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox_pages.add_child(label)
	
	# Next Button
	var next_btn = Button.new()
	next_btn.text = ">"
	next_btn.disabled = current_page >= total_pages
	next_btn.pressed.connect(func(): fetch_shaders(current_page + 1))
	hbox_pages.add_child(next_btn)

## Populate the grid with shader cards from API data
func populate_grid(json_data: Array) -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	for shader_data in json_data:
		var card = SHADER_CARD.instantiate()
		grid_container.add_child(card)
		card.download_requested.connect(_on_shader_download_requested)
		
		if card.has_method("setup"):
			card.setup(shader_data)

## Handle shader download request from a card
func _on_shader_download_requested(card: PanelContainer, shader_data: Dictionary) -> void:
	var shader_id = int(shader_data.get("id", 0))
	if shader_id == 0:
		show_toast("Error: Invalid shader ID", true)
		card.set_download_state(false)
		return
	
	var shader_url = "https://api.gdshader.com/shaders/" + str(shader_id)
	var download_http = HTTPRequest.new()
	add_child(download_http)
	
	download_http.request_completed.connect(
		func(result, response_code, headers, body):
			_on_shader_downloaded(card, shader_data, result, response_code, body)
			download_http.queue_free()
	)
	
	var error = download_http.request(shader_url)
	if error != OK:
		show_toast("Error: Failed to start download", true)
		card.set_download_state(false)
		download_http.queue_free()

## Process downloaded shader data and save to file
func _on_shader_downloaded(card: PanelContainer, shader_data: Dictionary, result: int, response_code: int, body: PackedByteArray) -> void:
	card.set_download_state(false)
	
	if response_code != 200:
		show_toast("Error: Download failed (code %d)" % response_code, true)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		show_toast("Error: Failed to parse shader data", true)
		return
	
	var shader_code = json.get("shader_code", "")
	if shader_code == "":
		show_toast("Error: No shader code found", true)
		return
	
	var save_path = _get_shader_save_path(json.get("name", "shader"))
	if _save_shader_file(save_path, shader_code):
		EditorInterface.get_resource_filesystem().scan()
		show_toast("Downloaded to: %s" % save_path, false)
	else:
		var error = FileAccess.get_open_error()
		show_toast("Error: Failed to save file (error %d)" % error, true)


## Get the full save path for a shader
func _get_shader_save_path(shader_name: String) -> String:
	var save_dir = ProjectSettings.get_setting("addons/gdshader/save_path", "res://shaders/")
	if not save_dir.ends_with("/"):
		save_dir += "/"
	
	var dir = DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive(save_dir)
	
	var safe_name = shader_name.replace(" ", "_").replace("/", "_").replace("\\", "_").to_lower()
	return save_dir + safe_name + ".gdshader"


## Save shader code to file
func _save_shader_file(relative_path: String, shader_code: String) -> bool:
	var absolute_path = ProjectSettings.globalize_path(relative_path)
	var file = FileAccess.open(absolute_path, FileAccess.WRITE)
	
	if file:
		file.store_string(shader_code)
		file.close()
		return true
	
	return false

## Display a toast notification message
func show_toast(message: String, is_error: bool = false) -> void:
	if not toast_label:
		return
	
	toast_label.text = message
	toast_label.modulate = Color.RED if is_error else Color.WHITE
	toast_label.visible = true
	toast_timer.start(3.0)


func _on_toast_timeout() -> void:
	if toast_label:
		toast_label.visible = false


func _on_post_new_btn_pressed() -> void:
	OS.shell_open("https://gdshader.com/shaders/new")
