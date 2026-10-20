@tool
extends EditorPlugin


var _preview_2d_enabled: bool

var _preview_3d_viewport_container: SubViewportContainer


func _enter_tree() -> void:
	_add_button("Show 2D", preload("icons/Node2D.svg"), CONTAINER_SPATIAL_EDITOR_MENU, _set_preview_2d_enabled)
	_add_button("Show 3D", preload("icons/Node3D.svg"), CONTAINER_CANVAS_EDITOR_MENU, _set_preview_3d_enabled)


func _add_button(button_text: String, icon: Texture2D, container: EditorPlugin.CustomControlContainer, toggled_callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.icon = icon
	
	button.toggle_mode = true
	button.toggled.connect(toggled_callback)
	button.tree_exiting.connect(toggled_callback.bind(false))
	
	add_control_to_container(container, button)
	
	tree_exiting.connect(func() -> void:
		remove_control_from_container(container, button)
		button.queue_free())


func _set_preview_2d_enabled(new: bool) -> void:
	_preview_2d_enabled = new
	
	#var viewport_2d := EditorInterface.get_editor_viewport_2d()
	#EditorInterface.inspect_object(viewport_2d)
	
	var spatial_editor: EditorDock = EditorInterface.get_dock_by_name("3D")
	
	if new: spatial_editor.visibility_changed.connect(_update_preview_2d)
	else: spatial_editor.visibility_changed.disconnect(_update_preview_2d)
	
	_update_preview_2d()


func _update_preview_2d() -> void:
	var enabled: bool = is_preview_2d_enabled()
	
	var viewport_2d := EditorInterface.get_editor_viewport_2d()
	var viewport_3d := EditorInterface.get_editor_viewport_3d()
	
	viewport_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED 
	viewport_2d.oversampling = not enabled
	
	viewport_3d.world_2d = viewport_2d.world_2d if enabled else null
	
	# TODO: Исправить растягивание
	viewport_3d.size_2d_override.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	viewport_3d.size_2d_override.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	viewport_3d.size_2d_override_stretch = enabled


func _set_preview_3d_enabled(new: bool) -> void:
	#var viewport_3d := EditorInterface.get_editor_viewport_3d()
	#EditorInterface.inspect_object(viewport_3d)
	
	if new: scene_changed.connect(_update_preview_3d)
	elif scene_changed.is_connected(_update_preview_3d): scene_changed.disconnect(_update_preview_3d)
	_update_preview_3d(EditorInterface.get_edited_scene_root() if new else null)


func _update_preview_3d(scene_root: Node) -> void:
	
	if _preview_3d_viewport_container:
		_preview_3d_viewport_container.queue_free()
		_preview_3d_viewport_container = null
	
	if not scene_root: return
	var canvas_editor: EditorDock = EditorInterface.get_dock_by_name("2D")
	
	_preview_3d_viewport_container = SubViewportContainer.new()
	_preview_3d_viewport_container.visible = canvas_editor.visible
	
	tree_exiting.connect(_preview_3d_viewport_container.queue_free)
	scene_changed.connect(_preview_3d_viewport_container.queue_free.unbind(1))
	
	canvas_editor.hidden.connect(_preview_3d_viewport_container.hide)
	canvas_editor.draw.connect(_preview_3d_viewport_container.show)
	
	scene_root.add_child(_preview_3d_viewport_container)
	scene_root.move_child(_preview_3d_viewport_container, 0)
	
	var sub_viewport := SubViewport.new()
	sub_viewport.size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	sub_viewport.size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	_preview_3d_viewport_container.add_child(sub_viewport)
	_preview_3d_viewport_container.size = sub_viewport.size
	
	var canvas_editor_camera := Camera3D.new()
	sub_viewport.add_child(canvas_editor_camera)
	canvas_editor_camera.make_current()
	
	var tree: SceneTree = get_tree()
	tree.process_frame.connect(_canvas_editor_camera_update_transform.bind(canvas_editor_camera))
	canvas_editor_camera.tree_exiting.connect(tree.process_frame.disconnect.bind(_canvas_editor_camera_update_transform))


static func _canvas_editor_camera_update_transform(canvas_editor_camera_3d: Camera3D) -> void:
	var target_camera: Camera3D = EditorInterface.get_edited_scene_root().get_viewport().get_camera_3d()
	if not target_camera: target_camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	if target_camera: canvas_editor_camera_3d.global_transform = target_camera.global_transform


func is_preview_2d_enabled() -> bool: return _preview_2d_enabled and EditorInterface.get_dock_by_name("3D").visible
