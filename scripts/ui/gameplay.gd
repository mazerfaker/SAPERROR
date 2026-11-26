extends Control
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const TerminalUI = preload("res://scripts/ui/terminal_ui.gd")
const CRT = preload("res://assets/shaders/crt.gdshader")
const Grade = preload("res://assets/shaders/scene_grade.gdshader")
const ART_PATH := "res://assets/art/terminal_original.png"
var frame: TextureRect
var display: TextureRect
var raster: SubViewport
var crt_material: ShaderMaterial
var grade_material: ShaderMaterial
var ui: Control
var curvature: float = 0.025
var effects: float = 0.6
var reduced_motion: bool = false
var flicker_enabled: bool = false
var curve_enabled: bool = true
var scene_effects: float = 0.0
var pointer_captured: bool = false
var fault: float = 0.0
func _ready() -> void:
	# Missing original is a hard error, not permission to substitute artwork.
	if not ResourceLoader.exists(ART_PATH):
		push_error("SAPERROR: approved terminal_original.png is missing")
		get_tree().quit(2)
		return
	var art: Texture2D = load(ART_PATH) as Texture2D
	if art == null or art.get_size() != Geometry.CANVAS:
		push_error("SAPERROR: unexpected approved artwork dimensions")
		get_tree().quit(2)
		return
	frame = TextureRect.new()
	frame.name = "BackgroundImage"
	frame.texture = art
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.size = Geometry.CANVAS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	raster = SubViewport.new()
	raster.name = "CRTViewport"
	raster.size = Geometry.RASTER
	raster.transparent_bg = false
	raster.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(raster)
	ui = TerminalUI.new()
	ui.size = Vector2(Geometry.RASTER)
	raster.add_child(ui)
	display = TextureRect.new()
	display.name = "CRTDisplay"
	display.texture = raster.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.position = Geometry.SCREEN.position
	display.size = Geometry.SCREEN.size
	display.mouse_filter = Control.MOUSE_FILTER_STOP
	display.focus_mode = Control.FOCUS_ALL
	add_child(display)
	crt_material = ShaderMaterial.new()
	crt_material.shader = CRT
	crt_material.set_shader_parameter("contour", Geometry.mask_points())
	display.material = crt_material
	display.gui_input.connect(_crt_input)
	display.mouse_exited.connect(_mouse_exit)
	var post := ColorRect.new()
	post.name = "GlobalPostProcessing"
	post.size = Geometry.CANVAS
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_material = ShaderMaterial.new()
	grade_material.shader = Grade
	post.material = grade_material
	add_child(post)
	ui.connect("effects_changed", _set_effects)
	ui.connect("fault_triggered", _on_fault)
	ui.connect("fullscreen_requested", _toggle_fullscreen)
	_set_effects(effects, curve_enabled, reduced_motion, flicker_enabled, scene_effects)
	if DisplayServer.get_name() != "headless": display.grab_focus()
func _set_effects(amount: float, curve: bool, reduced: bool, flicker: bool, global_amount: float) -> void:
	effects = amount
	curve_enabled = curve
	reduced_motion = reduced
	flicker_enabled = flicker
	scene_effects = global_amount
	curvature = 0.025 if curve and amount > 0.0 else 0.0
	crt_material.set_shader_parameter("curvature",curvature)
	crt_material.set_shader_parameter("strength",effects)
	crt_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	crt_material.set_shader_parameter("flicker",1.0 if flicker_enabled and not reduced_motion else 0.0)
	grade_material.set_shader_parameter("strength",scene_effects)
	grade_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
func _on_fault() -> void:
	fault = 1.0
func _process(delta: float) -> void:
	if crt_material == null: return
	fault = move_toward(fault,0.0,delta*1.7)
	crt_material.set_shader_parameter("fault",fault if not reduced_motion else 0.0)
func _toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	var mode: int = DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
func _crt_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var m: InputEventMouse = event.duplicate() as InputEventMouse
		var captured_before: bool = pointer_captured
		var inside: bool = Geometry2D.is_point_in_polygon(m.position / Geometry.SCREEN.size, Geometry.mask_points())
		if event is InputEventMouseButton and event.button_index <= MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				if not inside: return
				pointer_captured = true
			else:
				if not inside and not pointer_captured: return
				pointer_captured = false
		if not inside and not pointer_captured and not captured_before:
			_mouse_exit()
			return
		var previous: Vector2 = m.position
		if m is InputEventMouseMotion: previous -= m.relative
		m.position = Geometry.to_raster(m.position,curvature)
		m.global_position = m.position
		if m is InputEventMouseMotion:
			m.relative = m.position - Geometry.to_raster(previous,curvature)
		raster.push_input(m,true)
		display.accept_event()
	elif event is InputEventKey:
		raster.push_input(event.duplicate(),true)
		display.accept_event()
func _mouse_exit() -> void:
	if raster == null: return
	var m := InputEventMouseMotion.new()
	m.position = Vector2(-100,-100)
	m.global_position = m.position
	raster.push_input(m,true)
