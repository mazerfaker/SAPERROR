extends SceneTree
# Non-headless QA: render the approved composition at native resolution and compare pixels.
const Env = preload("res://scripts/environment/live_environment.gd")
var failures: int = 0
func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): printerr("LIVE_RENDER timeout"); quit(1))
	call_deferred("run")
func check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("LIVE_RENDER FAIL: ",msg)
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("LIVE_RENDER needs graphics")
		quit(1)
		return
	var env := Env.new()
	if not env.setup(12345):
		printerr("LIVE_RENDER missing approved assets")
		env.free()
		quit(1)
		return
	env.automatic = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	viewport.add_child(env)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/logs"))
	var original: Image = env.textures[env.layers["base"]["file"]].get_image()
	var retouch: Image=Env.PAPER_PATCH.get_image()
	retouch.convert(Image.FORMAT_RGBA8)
	var retouch_bounds:=Rect2i(Vector2i(Env.PAPER_POSITION),retouch.get_size())
	var changed: int=0
	for y in range(retouch.get_height()):
		for x in range(retouch.get_width()):
			if retouch.get_pixel(x,y).a>0.5: changed+=1
	check(changed>4000 and changed<retouch.get_width()*retouch.get_height(),"localized transparent paper retouch")
	for level in range(7):
		for lamp in [true,false]:
			env._set_visual(level,lamp)
			await process_frame
			await RenderingServer.frame_post_draw
			var actual: Image = viewport.get_texture().get_image()
			var expected: Image = original.duplicate()
			expected.blend_rect(retouch,Rect2i(Vector2i.ZERO,retouch.get_size()),retouch_bounds.position)
			if not lamp: blend_layer(expected,env,"lamp_off")
			for i in range(1,7): blend_layer(expected,env,str(i)+("_on" if i<=level else "_off"))
			var high: Image = env.high_frames[level].get_image()
			expected.blend_rect(high,Rect2i(Vector2i.ZERO,high.get_size()),Vector2i(env.post_position))
			var error: float = 0.0
			var count: int = 0
			for y in range(0,1080,8):
				for x in range(0,1920,8):
					var a: Color = actual.get_pixel(x,y)
					var b: Color = expected.get_pixel(x,y)
					error += (absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
					count+=1
			check(error/float(count)<0.012,"native composition mean error")
			var patch_error: float=0.0
			var patch_count: int=0
			for y in range(retouch_bounds.position.y,retouch_bounds.end.y,2):
				for x in range(retouch_bounds.position.x,retouch_bounds.end.x,2):
					var a: Color=actual.get_pixel(x,y)
					var b: Color=expected.get_pixel(x,y)
					patch_error+=(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
					patch_count+=1
			check(patch_error/float(maxi(1,patch_count))<0.015,"retouch present in every lamp/device frame")
			for y in range(855,1040,12):
				for x in range(475,1450,12):
					var a: Color = actual.get_pixel(x,y)
					var b: Color = original.get_pixel(x,y)
					check(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)<0.035,"untouched keyboard")
			if level in [0,3,6]:
				actual.save_png("res://build/logs/live_%d_%s.png" % [level,"on" if lamp else "off"])
	# Real audio player smoke (not a hardware latency measurement).
	env.set_audio_settings(1.0,true)
	env.player.play()
	await create_timer(0.15).timeout
	check(env.player.playing and env.player.get_playback_position()>0.0,"audio playback advances")
	await create_timer(0.55).timeout
	check(not env.player.playing,"single 500ms sound ends")
	print("LIVE_RENDER failures=",failures)
	quit(0 if failures==0 else 1)
func blend_layer(image: Image, env: Env, key: String) -> void:
	var layer: Dictionary = env.layers[key]
	var source: Image = env.textures[layer["file"]].get_image()
	image.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),Vector2i(layer["x"],layer["y"]))
