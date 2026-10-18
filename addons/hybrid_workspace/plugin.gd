@tool
extends EditorPlugin

var _canvas_editor_camera_3d: Camera3D


func _enter_tree() -> void:
	_add_button("Show 3D", preload("icons/Node3D.svg"), EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _on_canvas_editor_button_toggled)
	_add_button("Show 2D", preload("icons/Node2D.svg"), EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _on_spatial_editor_button_toggled)


func _add_button(button_text: String, icon: Texture2D, container: EditorPlugin.CustomControlContainer, button_callback: Callable) -> void:
	var button := Button.new()
	button.toggle_mode = true
	button.text = button_text
	button.icon = icon
	
	button.toggled.connect(button_callback)
	button.tree_exiting.connect(button_callback.bind(false))
	
	add_control_to_container(container, button)
	
	tree_exiting.connect(func() -> void:
		remove_control_from_container(container, button)
		button.queue_free()
	)


func _on_canvas_editor_button_toggled(toggled_on: bool) -> void:
	var viewport_2d := EditorInterface.get_editor_viewport_2d()
	var viewport_3d := EditorInterface.get_editor_viewport_3d()
	
	viewport_2d.disable_3d = not toggled_on
	
	if toggled_on:
		if not _canvas_editor_camera_3d:
			_canvas_editor_camera_3d = Camera3D.new()
			viewport_2d.add_child(_canvas_editor_camera_3d)
			_canvas_editor_camera_3d.make_current()
		get_tree().process_frame.connect(_canvas_editor_camera_update_transform)
	else:
		if _canvas_editor_camera_3d:
			_canvas_editor_camera_3d.queue_free()
			_canvas_editor_camera_3d = null
		get_tree().process_frame.disconnect(_canvas_editor_camera_update_transform)


func _canvas_editor_camera_update_transform() -> void:
	_canvas_editor_camera_3d.global_transform = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_transform


func _on_spatial_editor_button_toggled(toggled_on: bool) -> void:
	var viewport_2d := EditorInterface.get_editor_viewport_2d()
	var viewport_3d := EditorInterface.get_editor_viewport_3d()
	
	viewport_3d.world_2d = viewport_2d.world_2d if toggled_on else null
