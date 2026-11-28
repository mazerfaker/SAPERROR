extends Control
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const TerminalUI = preload("res://scripts/ui/terminal_ui.gd")
const CRT = preload("res://assets/shaders/crt.gdshader")
const Grade = preload("res://assets/shaders/scene_grade.gdshader")
const Lifecycle = preload("res://scripts/ui/crt_lifecycle.gd")
const Immersion = preload("res://scripts/ui/immersion.gd")
const PowerMask = preload("res://assets/shaders/crt_power.gdshader")
const ART_PATH := "res://assets/art/terminal_original.png"
const LiveEnvironment = preload("res://scripts/environment/live_environment.gd")
var live: LiveEnvironment
var skip_first_launch_warning: bool=false
var frame: TextureRect
var display: TextureRect
var raster: SubViewport
var crt_material: ShaderMaterial
var grade_material: ShaderMaterial
var grade_layer: ColorRect
var power_layer: ColorRect
var power_material: ShaderMaterial
var power_first_frame: bool=false
var power_dark_frames: int=0
var crt_values: Dictionary={}
var crt_parameter_writes: int=0
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
var immersion_pulse: float=0.0
var immersion_id: String=""
func _ready() -> void:
	# Missing original is a hard error, not permission to substitute artwork.
	if not ResourceLoader.exists(ART_PATH):
		push_error("SAPERROR: approved terminal_original.png is missing")
		get_tree().quit(2)
		return
	var art: Texture2D = load(ART_PATH) as Texture2D
	if art == null or art.get_size() != Geometry.LEGACY_CANVAS:
		push_error("SAPERROR: unexpected approved artwork dimensions")
		get_tree().quit(2)
		return
	var candidate := LiveEnvironment.new()
	if candidate.setup():
		live = candidate
		live.name = "LiveEnvironment"
		add_child(live)
	else:
		candidate.free()
		# A source checkout without the live assets remains recoverable. CI prohibits release packaging in this state.
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
	ui.require_content_warning=DisplayServer.get_name()!="headless" and not skip_first_launch_warning
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
	grade_layer=post
	post.name = "GlobalPostProcessing"
	post.size = Geometry.CANVAS if live==null else Geometry.SCREEN.size
	post.position = Vector2.ZERO if live==null else Geometry.SCREEN.position
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_material = ShaderMaterial.new()
	grade_material.shader = Grade
	grade_material.set_shader_parameter("clip_to_crt",live!=null)
	grade_material.set_shader_parameter("contour",Geometry.mask_points())
	post.material = grade_material
	add_child(post)
	# Last canvas layer, above all monitor post-processing; never affects the room.
	power_layer=ColorRect.new()
	power_layer.name="CRTPowerMask"
	power_layer.position=Geometry.SCREEN.position
	power_layer.size=Geometry.SCREEN.size
	power_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	power_material=ShaderMaterial.new()
	power_material.shader=PowerMask
	power_material.set_shader_parameter("contour",Geometry.mask_points())
	power_layer.material=power_material
	power_layer.z_index=50
	power_layer.hide()
	add_child(power_layer)
	ui.connect("effects_changed", _set_effects)
	ui.connect("fault_triggered", _on_fault)
	ui.connect("fullscreen_requested", _toggle_fullscreen)
	ui.connect("shutdown_requested", _shutdown)
	ui.connect("warning_accepted", _after_warning)
	ui.connect("outcome_triggered", _on_outcome)
	ui.connect("protocol_triggered", _on_protocol)
	ui.connect("immersion_triggered", _on_immersion)
	visual_rng.randomize()
	var quiet: bool=ui.clear_display or ui.warning_pending
	_set_effects(0.0 if quiet else ui.amount, ui.glass and not ui.warning_pending, ui.reduced or ui.warning_pending, ui.flicker and not quiet, 0.0 if quiet else ui.global_amount, ui.glitches and not quiet)
	if is_instance_valid(live): live.set_lamp_enabled(ui.lamp_animation and not ui.warning_pending)
	_start_power_on()
	if DisplayServer.get_name() != "headless": display.grab_focus()
	_apply_lifecycle()
func _power_animation_allowed() -> bool:
	return DisplayServer.get_name()!="headless"
func _start_power_on() -> void:
	# Keep the first-launch safety notice ahead of the animation.
	if ui.warning_pending or not _power_animation_allowed():
		lifecycle.skip_boot()
	else:
		lifecycle.begin_boot()
		power_first_frame=true
		power_dark_frames=0
		# Keep BIOS only in normal motion; gentle fade reveals menu in reduced motion.
		if not ui.reduced and not ui.clear_display: ui.begin_boot()
	_apply_lifecycle()
func _after_warning() -> void:
	if not _power_animation_allowed(): return
	ui.audio.play_event("boot")
	_start_power_on()
func _set_effects(amount: float, glass: bool, reduced: bool, flicker: bool, global_amount: float, glitches: bool = true) -> void:
	effects = amount
	glass_enabled = glass
	reduced_motion = reduced
	flicker_enabled = flicker
	glitches_enabled = glitches
	if reduced_motion or not glitches_enabled or effects<=0.0:
		immersion_pulse=0.0
		_set_crt("immersion_pulse",0.0)
	crt_material.set_shader_parameter("bulge",Geometry.FIXED_BULGE)
	scene_effects = global_amount
	# At zero strength, grade returns the original screen unchanged.
	# Hide the pass to avoid an unnecessary screen-texture copy.
	if is_instance_valid(grade_layer): grade_layer.visible=scene_effects>0.0
	crt_material.set_shader_parameter("glass",1.0 if glass_enabled else 0.0)
	crt_material.set_shader_parameter("strength",effects)
	crt_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	crt_material.set_shader_parameter("flicker",1.0 if flicker_enabled and not reduced_motion else 0.0)
	grade_material.set_shader_parameter("strength",scene_effects)
	grade_material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
func _on_immersion(id: String) -> void:
	if not lifecycle.accepts_input() or reduced_motion or not glitches_enabled or effects<=0.0 or ui.warning_pending or ui.high_contrast: return
	if not Immersion.IDS.has(id): return
	immersion_id=id
	immersion_pulse=0.72
	crt_material.set_shader_parameter("immersion_tint",Immersion.tint(id))
	_set_crt("immersion_mode",Immersion.mode(id))
	_set_crt("immersion_pulse",immersion_pulse)
func _on_protocol() -> void:
	if glitches_enabled and not reduced_motion and effects > 0.0: signal_fault = 1.0
func _on_fault() -> void:
	fault = 1.0
func _on_outcome(won: bool) -> void:
	outcome = 1.0
	outcome_sign = 1.0 if won else -1.0
func _apply_lifecycle() -> void:
	# The original CRT shader stays neutral; a dedicated top layer owns power transitions.
	_set_crt("power",1.0)
	_set_crt("beam",1.0)
	if not is_instance_valid(power_layer): return
	var gentle: bool=ui.reduced or ui.clear_display
	var active: bool=lifecycle.phase!=Lifecycle.Phase.READY
	power_layer.visible=active
	if not active: return
	var level: float=lifecycle.power()
	var aperture: float=lifecycle.beam()
	if gentle:
		aperture=1.0
		if lifecycle.phase==Lifecycle.Phase.BOOT: level=smoothstep(0.0,1.0,lifecycle.progress())
		elif lifecycle.phase==Lifecycle.Phase.SHUTDOWN: level=1.0-smoothstep(0.0,1.0,lifecycle.progress())
	power_material.set_shader_parameter("screen_power",level)
	power_material.set_shader_parameter("screen_beam",aperture)
	power_material.set_shader_parameter("line_strength",0.0 if gentle else (1.0-aperture)*level)
func _finish_boot() -> void:
	lifecycle.skip_boot()
	power_first_frame=false
	ui.end_boot()
	_apply_lifecycle()
func _shutdown() -> void:
	if not lifecycle.accepts_input(): return
	pointer_captured = false
	if not _power_animation_allowed():
		get_tree().quit()
		return
	lifecycle.begin_shutdown()
	power_first_frame=true
	power_dark_frames=0
	_apply_lifecycle()
	ui.audio.play_event("shutdown")
func _process(delta: float) -> void:
	if crt_material == null: return
	if is_instance_valid(live):
		live.set_lamp_enabled(ui.lamp_animation and not ui.warning_pending)
		live.set_audio_settings(ui.audio.effective_sfx(),ui.audio.enabled)
	var previous: int = lifecycle.phase
	# Do not let a long loading/render stall skip the entire visible transition.
	if power_first_frame:
		power_first_frame=false
	elif lifecycle.phase in [Lifecycle.Phase.BOOT,Lifecycle.Phase.SHUTDOWN]:
		lifecycle.advance(minf(delta,0.05))
	else:
		lifecycle.advance(delta)
	if lifecycle.phase == Lifecycle.Phase.BOOT:
		ui.update_boot(lifecycle.progress())
	elif previous == Lifecycle.Phase.BOOT:
		ui.end_boot()
	if lifecycle.phase == Lifecycle.Phase.SHUTDOWN:
		ui.audio.fade_hum(1.0-lifecycle.progress())
		ui.audio.fade_music(1.0-lifecycle.progress())
	elif lifecycle.phase == Lifecycle.Phase.OFF:
		# Present at least two black frames before destroying the window.
		power_dark_frames+=1
		if power_dark_frames>=3: get_tree().quit()
	_apply_lifecycle()
	fault = move_toward(fault,0.0,delta*1.7)
	if glitches_enabled and not reduced_motion and effects > 0.0 and lifecycle.accepts_input():
		next_glitch -= delta
		if next_glitch <= 0.0:
			signal_fault = maxf(signal_fault,visual_rng.randf_range(0.30,0.65))
			next_glitch = visual_rng.randf_range(12.0,28.0)
	else: signal_fault = 0.0
	signal_fault = move_toward(signal_fault,0.0,delta*5.0)
	_set_crt("signal_fault",signal_fault)
	immersion_pulse=move_toward(immersion_pulse,0.0,delta*1.4) if lifecycle.accepts_input() and not reduced_motion and glitches_enabled and effects>0.0 and not ui.high_contrast else 0.0
	_set_crt("immersion_pulse",immersion_pulse)
	_set_crt("scan_wave",ui.protocol_scan if not reduced_motion else -1.0)
	outcome = move_toward(outcome,0.0,delta*0.85)
	_set_crt("fault",fault if not reduced_motion else 0.0)
	_set_crt("outcome",outcome*outcome_sign if not reduced_motion else 0.0)
func _toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	var mode: int = DisplayServer.window_get_mode()
	var fullscreen: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
# Capture secret physical keys at the root input stage, before GUI focus
# or the manually forwarded SubViewport can consume them. Feed exactly once.
func _input(event: InputEvent) -> void:
	if not is_instance_valid(ui) or not event is InputEventKey: return
	if not lifecycle.accepts_input():
		ui.protocol.reset_input()
		if lifecycle.phase==Lifecycle.Phase.BOOT and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_SPACE]: _finish_boot()
		get_viewport().set_input_as_handled()
		return
	if ui.protocol_input(event):
		get_viewport().set_input_as_handled()
		return
	if not is_instance_valid(display) or not display.has_focus(): return
	if event.pressed and not event.echo:
		if event.keycode==KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_ESCAPE and not (raster.gui_get_focus_owner() is LineEdit) and ui.back_shortcut():
			get_viewport().set_input_as_handled()
			return
	raster.push_input(event.duplicate(),true)
	get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(ui):
		ui.protocol.reset_input()
func _crt_input(event: InputEvent) -> void:
	if not lifecycle.accepts_input():
		if lifecycle.phase == Lifecycle.Phase.BOOT and event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_SPACE]: _finish_boot()
		display.accept_event()
		return
	if ui.protocol_active:
		display.accept_event()
		return
	if event is InputEventMouse:
		var m: InputEventMouse = event.duplicate() as InputEventMouse
		var captured_before: bool = pointer_captured
		var inside: bool = Geometry2D.is_point_in_polygon(m.position / Geometry.SCREEN.size, Geometry.mask_points())
		if event is InputEventMouseButton and event.button_index <= MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				if not inside: return
				display.grab_focus()
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

func _set_crt(key: String,value: float) -> void:
	if crt_values.has(key) and crt_values[key]==value: return
	crt_values[key]=value
	crt_material.set_shader_parameter(key,value)
	crt_parameter_writes+=1
