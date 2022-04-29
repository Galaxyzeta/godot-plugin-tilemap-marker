tool
extends EditorPlugin

var _selection: EditorSelection
var _active_tilemap: TileMap
var _color: Color = Color.red
var _button_scene: PackedScene = preload("./button.tscn")
var _button_instance: Button		# Lazy instanced

var _enable_drawing: bool = true

func _enter_tree():
	# Load button preset
	if _button_scene == null:
		disable_plugin()
		return
	_selection = get_editor_interface().get_selection()
	_selection.connect("selection_changed", self, "_on_selection_changed")

func _exit_tree():
	if _button_instance != null:
		_button_instance.queue_free()

func _on_button_pressed():
	_enable_drawing = not _enable_drawing
	update_overlays()

func _on_selection_changed():
	# Returns an array of selected nodes
	var selected = _selection.get_selected_nodes()
	var switch = false
	if not selected.empty():
		for n in selected:
			if n is TileMap:
				_active_tilemap = n
				switch = true
				break
	if not switch:
		_active_tilemap = null

func handles(obj: Object)->bool:
	return obj is TileMap

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	# Handle button lazy instantiation
	if _button_instance == null:
		_button_instance = _button_scene.instance()
		_button_instance.connect("button_down", self, "_on_button_pressed")
	if _button_instance != null && _button_instance.get_parent() != null:
		_button_instance.get_parent().remove_child(_button_instance)
	if _active_tilemap == null or not _active_tilemap.is_inside_tree():
		return
	var mat: Transform2D = _active_tilemap.get_viewport_transform() * overlay.get_canvas_transform()
	var sc: Vector2 = mat.get_scale()
	# Draw boundary
	var r2 = _active_tilemap.get_used_rect()
	var pos = mat * (_active_tilemap.global_position + r2.position * _active_tilemap.cell_size)
	var wh = sc * r2.size * _active_tilemap.cell_size
	var ending = pos + wh
	if _enable_drawing:
		_color.a = 1
		overlay.draw_rect(Rect2(pos, wh), _color, false, 2.0)
		# Draw grids
		_color.a = 0.3
		for vec2 in _active_tilemap.get_used_cells():
			var p = mat * (_active_tilemap.global_position + vec2 * _active_tilemap.cell_size)
			overlay.draw_rect(Rect2(p, sc * _active_tilemap.cell_size), _color, true)
		# Draw size info
		overlay.draw_string(overlay.get_font(""), ending, str(r2.size))
	# Add a button to the vp
	overlay.add_child(_button_instance)
	_button_instance.set_position(ending + Vector2(0, 8))