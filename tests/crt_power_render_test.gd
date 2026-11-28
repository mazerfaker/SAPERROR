extends SceneTree
const Scene=preload("res://scenes/game/gameplay.tscn")
const Geometry=preload("res://scripts/ui/crt_geometry.gd")
const Life=preload("res://scripts/ui/crt_lifecycle.gd")
var failures: int=0
func check(ok: bool,msg: String) -> void:
	if not ok:
		failures+=1
		printerr("CRT_POWER FAIL: ",msg)
func _initialize() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	call_deferred("run")
func capture(v: SubViewport, name: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image=v.get_texture().get_image()
	img.save_png("res://build/logs/crt_"+name+".png")
	return img
func mean(img: Image, area: Rect2i) -> float:
	var total: float=0.0
	var n: int=0
	for y in range(area.position.y,area.end.y,3):
		for x in range(area.position.x,area.end.x,3):
			var c: Color=img.get_pixel(x,y)
			total+=(c.r+c.g+c.b)/3.0
			n+=1
	return total/float(maxi(n,1))
# Read the real native viewport while the ordinary process callback advances the cursor.
# No direct visibility toggling or fake rendered frames.
func check_cursor(game, mode: String) -> void:
	var ui=game.ui
	ui.reduced=mode=="reduced"
	ui.clear_display=mode=="clear"
	ui._show("menu")
	ui.set_process(true)
	var region:=Rect2i(ui.header_cursor.get_global_rect())
	var brightest: float=-1.0
	var darkest: float=2.0
	var bright: Image
	var dark: Image
	for i in range(16):
		await create_timer(0.08).timeout
		await RenderingServer.frame_post_draw
		var img: Image=game.raster.get_texture().get_image()
		var light: float=mean(img,region)
		if light>brightest:
			brightest=light
			bright=img
		if light<darkest:
			darkest=light
			dark=img
	check(brightest-darkest>0.018,"native cursor visible/hidden contrast "+mode)
	if bright!=null and dark!=null:
		bright.save_png("res://build/logs/cursor_"+mode+"_on.png")
		dark.save_png("res://build/logs/cursor_"+mode+"_off.png")
		var title_area:=Rect2i(88,52,mini(200,region.position.x-88),92)
		check(absf(mean(bright,title_area)-mean(dark,title_area))<0.008,"title stable "+mode)
	ui.reduced=false
	ui.clear_display=false
func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/logs"))
	var vp:=SubViewport.new()
	vp.size=Vector2i(1920,1080)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game=Scene.instantiate()
	game.skip_first_launch_warning=true
	vp.add_child(game)
	game.set_process(false)
	game.ui.reduced=false
	game.ui.clear_display=false
	game.ui.warning_pending=false
	game.ui.session_path="user://crt_power_test_%d.cfg" % OS.get_process_id()
	game._finish_boot()
	game._set_effects(0.0,true,false,false,0.0,false)
	for mode in ["normal","reduced","clear"]:
		await check_cursor(game,mode)
	game.ui._start_challenge("WATCHER")
	var emblem_slot: Control=game.ui.header_emblem_slot
	check(absf(emblem_slot.get_rect().get_center().x-713.0)<0.1 and emblem_slot.position.y==44.0,"boss emblem centered on CRT header")
	await capture(vp,"boss_header")
	game.ui._show("menu")
	# Use the real menu and actual top-level composition, not an isolated shader fixture.
	var ready: Image=await capture(vp,"ready")
	game._start_power_on()
	var dark: Image=await capture(vp,"boot_dark")
	check(game.lifecycle.phase==Life.Phase.BOOT and game.power_layer.visible,"real boot layer")
	var screen:=Rect2i(590,180,710,465)
	check(mean(dark,screen)<0.012 and mean(ready,screen)>mean(dark,screen)+0.012,"dark boot differs from visible menu")
	for i in range(12): game._process(0.05)
	var warm: Image=await capture(vp,"boot_warm")
	check(mean(warm,screen)>mean(dark,screen)+0.003,"visible warmup")
	game._finish_boot()
	game.ui._show("menu")
	var power:=game.ui.page.find_child("PowerOff",true,false) as Button
	check(is_instance_valid(power),"real power button")
	if is_instance_valid(power): power.pressed.emit()
	check(game.lifecycle.phase==Life.Phase.SHUTDOWN,"actual button starts shutdown")
	for i in range(17): game._process(0.05)
	var fading: Image=await capture(vp,"shutdown")
	check(mean(fading,screen)<mean(ready,screen)*0.6,"actual frame dims")
	for i in range(7): game._process(0.05)
	var off: Image=await capture(vp,"off")
	check(mean(off,screen)<0.012,"actual final black frame")
	var outside:=Rect2i(20,30,150,150)
	check(absf(mean(off,outside)-mean(ready,outside))<0.05,"room not darkened")
	print("CRT_POWER_QA failures=",failures)
	game.queue_free()
	quit(0 if failures==0 else 1)
