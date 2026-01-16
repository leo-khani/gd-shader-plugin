## GDShader Library Plugin
## Provides a tab in the Godot Editor to browse and download shaders from gdshader.com
@tool
extends EditorPlugin

const SHADER_LIB_SCENE = preload("res://addons/gdshader/shader_lib_view.tscn")

var shader_lib_instance

func _enter_tree() -> void:
	_register_project_settings()
	
	shader_lib_instance = SHADER_LIB_SCENE.instantiate()
	EditorInterface.get_editor_main_screen().add_child(shader_lib_instance)
	_make_visible(false)


## Register plugin project settings
func _register_project_settings() -> void:
	if not ProjectSettings.has_setting("addons/gdshader/save_path"):
		ProjectSettings.set_setting("addons/gdshader/save_path", "res://shaders/")
		ProjectSettings.set_initial_value("addons/gdshader/save_path", "res://shaders/")
		ProjectSettings.add_property_info({
			"name": "addons/gdshader/save_path",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"hint_string": ""
		})
		ProjectSettings.save()

func _exit_tree() -> void:
	if shader_lib_instance:
		shader_lib_instance.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if shader_lib_instance:
		shader_lib_instance.visible = visible


func _get_plugin_name() -> String:
	return "ShaderLib"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon("Shader", "EditorIcons")