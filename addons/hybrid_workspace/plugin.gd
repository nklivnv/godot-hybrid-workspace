#@tool
#extends EditorPlugin
#
#var _canvas_editor_camera_3d: Camera3D
#
#
#func _enter_tree() -> void:
#	_add_button("Show 3D", preload("icons/Node3D.svg"), EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _on_canvas_editor_button_toggled)
#	_add_button("Show 2D", preload("icons/Node2D.svg"), EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _on_spatial_editor_button_toggled)
#
#
#func _add_button(button_text: String, icon: Texture2D, container: EditorPlugin.CustomControlContainer, button_callback: Callable) -> void:
#	var button := Button.new()
#	button.toggle_mode = true
#	button.text = button_text
#	button.icon = icon
#	
#	button.toggled.connect(button_callback)
#	button.tree_exiting.connect(button_callback.bind(false))
#	
#	add_control_to_container(container, button)
#	
#	tree_exiting.connect(func() -> void:
#		remove_control_from_container(container, button)
#		button.queue_free()
#	)
#
#
#func _on_canvas_editor_button_toggled(toggled_on: bool) -> void:
#	var viewport_2d := EditorInterface.get_editor_viewport_2d()
#	var viewport_3d := EditorInterface.get_editor_viewport_3d()
#	
#	viewport_2d.disable_3d = not toggled_on
#	
#	var tree: SceneTree = get_tree()
#	
#	if toggled_on:
#		
#		if not _canvas_editor_camera_3d:
#			_canvas_editor_camera_3d = Camera3D.new()
#			viewport_2d.add_child(_canvas_editor_camera_3d)
#			_canvas_editor_camera_3d.make_current()
#		
#		if not tree.process_frame.is_connected(_canvas_editor_camera_update_transform):
#			tree.process_frame.connect(_canvas_editor_camera_update_transform)
#	else:
#		
#		if _canvas_editor_camera_3d:
#			_canvas_editor_camera_3d.queue_free()
#			_canvas_editor_camera_3d = null
#		
#		if tree.process_frame.is_connected(_canvas_editor_camera_update_transform):
#			tree.process_frame.disconnect(_canvas_editor_camera_update_transform)
#
#
#func _canvas_editor_camera_update_transform() -> void:
#	_canvas_editor_camera_3d.global_transform = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_transform
#
#
#func _on_spatial_editor_button_toggled(toggled_on: bool) -> void:
#	var viewport_2d := EditorInterface.get_editor_viewport_2d()
#	var viewport_3d := EditorInterface.get_editor_viewport_3d()
#	
#	viewport_3d.world_2d = viewport_2d.world_2d if toggled_on else null


@tool
extends EditorPlugin


var canvas_editor_sub_viewport_container: SubViewportContainer


func _enter_tree() -> void:
	_add_button("Show 3D", preload("icons/Node3D.svg"), EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _on_canvas_editor_button_toggled)
	_add_button("Show 2D", preload("icons/Node2D.svg"), EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _on_spatial_editor_button_toggled)


func _add_button(button_text: String, icon: Texture2D, container: EditorPlugin.CustomControlContainer, toggled_callback: Callable) -> void:
	var button := Button.new()
	button.toggle_mode = true
	button.text = button_text
	button.icon = icon
	
	button.toggled.connect(toggled_callback)
	button.tree_exiting.connect(toggled_callback.bind(false))
	
	add_control_to_container(container, button)
	
	tree_exiting.connect(func() -> void:
		remove_control_from_container(container, button)
		button.queue_free())


func _on_canvas_editor_button_toggled(toggled_on: bool) -> void:
	if toggled_on: scene_changed.connect(_update_canvas_editor)
	elif scene_changed.is_connected(_update_canvas_editor): scene_changed.disconnect(_update_canvas_editor)
	_update_canvas_editor(EditorInterface.get_edited_scene_root() if toggled_on else null)


func _update_canvas_editor(scene_root: Node) -> void:
	
	if canvas_editor_sub_viewport_container:
		canvas_editor_sub_viewport_container.queue_free()
		canvas_editor_sub_viewport_container = null
	
	if not scene_root: return
	
	canvas_editor_sub_viewport_container = SubViewportContainer.new()
	
	tree_exiting.connect(canvas_editor_sub_viewport_container.queue_free)
	scene_changed.connect(canvas_editor_sub_viewport_container.queue_free.unbind(1))
	
	EditorInterface.get_dock_by_name("2D").hidden.connect(canvas_editor_sub_viewport_container.hide)
	EditorInterface.get_dock_by_name("2D").draw.connect(canvas_editor_sub_viewport_container.show)
	
	scene_root.add_child(canvas_editor_sub_viewport_container)
	scene_root.move_child(canvas_editor_sub_viewport_container, 0)
	
	var sub_viewport := SubViewport.new()
	sub_viewport.size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	sub_viewport.size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	canvas_editor_sub_viewport_container.add_child(sub_viewport)
	canvas_editor_sub_viewport_container.size = sub_viewport.size
	
	var canvas_editor_camera := Camera3D.new()
	sub_viewport.add_child(canvas_editor_camera)
	canvas_editor_camera.make_current()
	
	var tree: SceneTree = get_tree()
	tree.process_frame.connect(_canvas_editor_camera_update_transform.bind(canvas_editor_camera))
	canvas_editor_camera.tree_exiting.connect(tree.process_frame.disconnect.bind(_canvas_editor_camera_update_transform))


static func _canvas_editor_camera_update_transform(canvas_editor_camera_3d: Camera3D) -> void:
	var spatial_editor_camera_3d: Camera3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	if spatial_editor_camera_3d: canvas_editor_camera_3d.global_transform = spatial_editor_camera_3d.global_transform


func _on_spatial_editor_button_toggled(toggled_on: bool) -> void:
	var viewport_2d := EditorInterface.get_editor_viewport_2d()
	var viewport_3d := EditorInterface.get_editor_viewport_3d()
	
	viewport_3d.world_2d = viewport_2d.world_2d if toggled_on else null
