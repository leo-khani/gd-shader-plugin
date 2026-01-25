## Individual shader card component
## Displays shader information and provides download/view actions
@tool
extends PanelContainer

signal download_requested(card: PanelContainer, shader_data: Dictionary)
signal view_requested(shader_data: Dictionary)

@onready var image_preview: TextureRect = %ImagePreview
@onready var title_label: LinkButton = $MarginContainer/VBoxContainer/HBoxContainerInfo/InfoVBox/TitleLabel
@onready var author_label: LinkButton = $MarginContainer/VBoxContainer/HBoxContainerInfo/InfoVBox/AuthorLabel
@onready var view_button: Button = $MarginContainer/VBoxContainer/HBoxContainerBtns/ViewButton
@onready var download_button: Button = $MarginContainer/VBoxContainer/HBoxContainerBtns/DownloadButton

var shader_data: Dictionary
var image_http: HTTPRequest
var is_downloading: bool = false

func _ready() -> void:
	view_button.pressed.connect(_on_view_button_pressed)
	download_button.pressed.connect(_on_download_button_pressed)


## Initialize card with shader data from API
func setup(data: Dictionary) -> void:
	shader_data = data
	
	title_label.text = data.get("name", "Unnamed Shader")
	title_label.uri = "https://gdshader.com/shaders/" + str(int(data.get("id")))
	
	var author_info = data.get("author", {})
	author_label.text = "by " + author_info.get("username", "Anonymous")
	
	var thumb_url = data.get("thumbnail_url", "")
	if thumb_url == "": 
		thumb_url = data.get("image_url", "")

	if thumb_url != "":
		_download_image(thumb_url)

## Download shader thumbnail image
func _download_image(url: String) -> void:
	image_http = HTTPRequest.new()
	add_child(image_http)
	image_http.request_completed.connect(_on_image_downloaded)
	
	var error = image_http.request(url)
	if error != OK:
		push_error("Failed to request thumbnail for: " + title_label.text)


func _on_image_downloaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var image = Image.new()
		var error = image.load_jpg_from_buffer(body)
		
		if error != OK:
			error = image.load_png_from_buffer(body)
		
		if error == OK:
			image_preview.texture = ImageTexture.create_from_image(image)
	
	image_http.queue_free()

func _on_view_button_pressed() -> void:
	var url = "https://gdshader.com/shaders/" + str(int(shader_data.get("id")))
	OS.shell_open(url)
	view_requested.emit(shader_data)


func _on_download_button_pressed() -> void:
	if is_downloading:
		return
	
	set_download_state(true)
	download_requested.emit(self, shader_data)


## Update download button state and text
func set_download_state(downloading: bool) -> void:
	is_downloading = downloading
	download_button.disabled = downloading
	download_button.text = "Downloading..." if downloading else "Download"