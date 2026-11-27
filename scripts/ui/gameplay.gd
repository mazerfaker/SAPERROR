extends Control
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const TerminalUI = preload("res://scripts/ui/terminal_ui.gd")
const CRT = preload("res://assets/shaders/crt.gdshader")
const Grade = preload("res://assets/shaders/scene_grade.gdshader")
const Lifecycle = preload("res://scripts/ui/crt_lifecycle.gd")
const ART_PATH := "res://assets/art/terminal_original.png"
var frame: TextureRect
var display: TextureRect
var raster: SubViewport
var crt_material: ShaderMaterial
var grade_material: ShaderMaterial
var ui: TerminalUI
var effects: float = 0.45
var glitches_enabled: bool = true
var signal_fault: float = 0.0
var next_glitch: float = 14.0
var visual_rng := RandomNumberGenerator.new()
var reduced_motion: bool = false
var flicker_enabled: bool = false
var glass_enabled: bool = true
var scene_effects: float = 0.0
var pointer_captured: bool = false
var fault: float = 0.0
var lifecycle := Lifecycle.new()
var outcome: float = 0.0
var outcome_sign: float = 0.0
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
	raster.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
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
	ui.connect("shutdown_requested", _shutdown)
	ui.connect("outcome_triggered", _on_outcome)
	ui.connect("protocol_triggered", _on_protocol)
	visual_rng.randomize()
	_set_effects(ui.amount, ui.glass, ui.reduced, ui.flicker, ui.global_amount, ui.glitches)
	if DisplayServer.get_name() == "headless" or reduced_motion or effects <= 0.0:
		lifecycle.skip_boot()
	else:
		ui.begin_boot()
	if DisplayServer.get_name() != "headless": display.grab_focus()
	_apply_lifecycle()
func _set_effects(amount: float, glass: bool, reduced: bool, flicker: bool, global_amount: float, glitches: bool = true) -> void:
	effects = amount
	glass_enabled = glass
	reduced_motion = reduced
	flicker_enabled = flicker
	glitches_enabled = glitches
	crt_material.set_shader_parameter("bulge",Geometry.FIXED_BULGE)
	scene_effects = global_amount
	crt_material.set_shader_parameter("glass",1.0 if glass_enabled else 0.0)
	crt_material.set_shader_parameter("strength",effects)
	crt_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	crt_material.set_shader_parameter("flicker",1.0 if flicker_enabled and not reduced_motion else 0.0)
	grade_material.set_shader_parameter("strength",scene_effects)
	grade_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
func _on_protocol() -> void:
	if glitches_enabled and not reduced_motion and effects > 0.0: signal_fault = 1.0
func _on_fault() -> void:
	fault = 1.0
func _on_outcome(won: bool) -> void:
	outcome = 1.0
	outcome_sign = 1.0 if won else -1.0
func _apply_lifecycle() -> void:
	crt_material.set_shader_parameter("power",lifecycle.power())
	crt_material.set_shader_parameter("beam",lifecycle.beam())
func _finish_boot() -> void:
	lifecycle.skip_boot()
	ui.end_boot()
	_apply_lifecycle()
func _shutdown() -> void:
	if not lifecycle.accepts_input(): return
	pointer_captured = false
	if reduced_motion or effects <= 0.0 or DisplayServer.get_name() == "headless":
		get_tree().quit()
		return
	lifecycle.begin_shutdown()
	ui.audio.play_event("shutdown")
func _process(delta: float) -> void:
	if crt_material == null: return
	var previous: int = lifecycle.phase
	lifecycle.advance(delta)
	if lifecycle.phase == Lifecycle.Phase.BOOT:
		ui.update_boot(lifecycle.progress())
	elif previous == Lifecycle.Phase.BOOT:
		ui.end_boot()
	if lifecycle.phase == Lifecycle.Phase.SHUTDOWN:
		ui.audio.fade_hum(1.0-lifecycle.progress())
	elif lifecycle.phase == Lifecycle.Phase.OFF:
		get_tree().quit()
	_apply_lifecycle()
	fault = move_toward(fault,0.0,delta*1.7)
	if glitches_enabled and not reduced_motion and effects > 0.0 and lifecycle.accepts_input():
		next_glitch -= delta
		if next_glitch <= 0.0:
			signal_fault = maxf(signal_fault,visual_rng.randf_range(0.30,0.65))
			next_glitch = visual_rng.randf_range(12.0,28.0)
	else: signal_fault = 0.0
	signal_fault = move_toward(signal_fault,0.0,delta*5.0)
	crt_material.set_shader_parameter("signal_fault",signal_fault)
	crt_material.set_shader_parameter("scan_wave",ui.protocol_scan if not reduced_motion else -1.0)
	outcome = move_toward(outcome,0.0,delta*0.85)
	crt_material.set_shader_parameter("fault",fault if not reduced_motion else 0.0)
	crt_material.set_shader_parameter("outcome",outcome*outcome_sign if not reduced_motion else 0.0)
func _toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	var mode: int = DisplayServer.window_get_mode()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
func _crt_input(event: InputEvent) -> void:
	if not lifecycle.accepts_input():
		if lifecycle.phase == Lifecycle.Phase.BOOT and event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_SPACE]: _finish_boot()
		display.accept_event()
		return
	if ui.protocol_active:
		display.accept_event()
		return
	if event is InputEventKey and ui.protocol_input(event):
		display.accept_event()
		return
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
		m.position = Geometry.to_raster(m.position)
		m.global_position = m.position
		if m is InputEventMouseMotion:
			m.relative = m.position - Geometry.to_raster(previous)
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
