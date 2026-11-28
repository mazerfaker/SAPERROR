extends SceneTree
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Store=preload("res://scripts/save/session_store.gd")
const Consent=preload("res://scripts/save/analytics_consent.gd")
const ART := "res://assets/art/terminal_original.png"
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(int(ProjectSettings.get_setting("display/window/size/mode",0))==3,"fullscreen startup default")
	var texture: Texture2D = load(ART) as Texture2D
	check(texture != null and texture.get_size() == Geometry.LEGACY_CANVAS,"original texture import")
	check(Geometry.CANVAS==Vector2(1920,1080),"native live canvas")
	var poly: PackedVector2Array = Geometry.mask_points()
	check(poly.size() == 21,"mask contour")
	check(Geometry2D.is_point_in_polygon(Vector2(0.5,0.5),poly),"mask center")
	check(not Geometry2D.is_point_in_polygon(Vector2(0.0,0.0),poly),"mask corners excluded")
	for window in [Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1440),Vector2(3840,2160),Vector2(1024,768),Vector2(2560,1080)]:
		var rect: Rect2 = Geometry.fit(window)
		check(absf(rect.size.aspect()-Geometry.CANVAS.aspect())<0.00001,"aspect ratio")
		check(rect.position.x >= -0.001 and rect.position.y >= -0.001,"letterbox bounds")
		for local in [Vector2(100,100),Geometry.SCREEN.size*0.5,Vector2(600,380)]:
			var physical: Vector2 = rect.position+(Geometry.SCREEN.position+local)*rect.size/Geometry.CANVAS
			var recovered: Vector2 = (physical-rect.position)*Geometry.CANVAS/rect.size-Geometry.SCREEN.position
			check(Geometry.to_raster(recovered).distance_to(Geometry.to_raster(local))<0.01,"window to fixed CRT hit mapping")
	for y in range(11):
		for x in range(11):
			var uv := Vector2(x,y)/10.0
			check(Geometry.to_raster(uv*Geometry.SCREEN.size).distance_to(Geometry.warp(uv)*Vector2(Geometry.RASTER))<0.01,"fixed bulge raster mapping")
	var shader: Shader = load("res://assets/shaders/crt.gdshader") as Shader
	check(shader != null,"CRT shader resource")
	if shader != null:
		check(shader.code.contains("texture(TEXTURE,q)"),"primary sample uses fixed glass mapping")
		check(Geometry.FIXED_BULGE == 0.04,"approved 25 percent of old maximum")
		check(not shader.code.contains("uniform float curvature"),"no intensity-linked curvature")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	check(scene!=null,"CRT scene loads")
	if scene != null:
		var game = scene.instantiate()
		root.add_child(game)
		var cursor: Texture2D=game.MOUSE_CURSOR
		var pointer: Image=cursor.get_image()
		check(cursor.get_size()==Vector2(40,40),"custom mouse pointer native dimensions")
		check(game.MOUSE_HOTSPOT==Vector2(8,2) and pointer.get_pixel(8,2).a>0.5,"mouse hotspot on arrow tip")
		check(pointer.get_pixel(0,0).a<0.05 and pointer.get_pixel(39,0).a<0.05,"cursor transparent background")
		var interior: Color=pointer.get_pixel(12,20)
		check(interior.g<0.25,"dark cursor interior")
		check(game.CUSTOM_CURSOR_SHAPES.has(Input.CURSOR_ARROW) and game.CUSTOM_CURSOR_SHAPES.has(Input.CURSOR_POINTING_HAND) and game.CUSTOM_CURSOR_SHAPES.has(Input.CURSOR_IBEAM),"shared themed cursor for normal interface shapes")
		var privacy_path: String="user://analytics_qa_%d.txt" % OS.get_process_id()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(privacy_path))
		check(not Consent.allowed(privacy_path),"missing consent defaults off")
		check(Consent.write_choice(true,privacy_path) and Consent.allowed(privacy_path),"installer-compatible opt in")
		game.ui.analytics_consent_path=privacy_path
		game.ui.analytics_allowed=Consent.allowed(privacy_path)
		game.ui._show("privacy")
		var opt:=game.ui.page.find_child("AnalyticsConsent",true,false) as Button
		check(is_instance_valid(opt),"privacy control exists")
		if is_instance_valid(opt): opt.pressed.emit()
		check(not game.ui.analytics_allowed and not Consent.allowed(privacy_path),"revocation persisted")
		check(game.ui.back_shortcut() and game.ui.screen=="settings","privacy back navigation")
		check(Consent.write_choice(true,privacy_path) and Consent.allowed(privacy_path),"explicit opt in persisted again")
		var invalid:=FileAccess.open(privacy_path,FileAccess.WRITE)
		if invalid!=null:
			invalid.store_string("v1:allow")
			invalid.close()
		check(not Consent.allowed(privacy_path),"unknown consent version defaults off")
		for suffix in ["",".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(privacy_path+suffix))
		game.ui.analytics_consent_path=Consent.PATH
		game.ui.analytics_allowed=false
		game.ui._show("settings")
		var entry:=game.ui.page.find_child("ResolutionSetting",true,false) as Button
		check(is_instance_valid(entry),"resolution settings entry")
		if is_instance_valid(entry): entry.pressed.emit()
		check(game.ui.screen=="resolution","resolution submenu")
		for preset in UI.WINDOW_RESOLUTIONS:
			var b:=game.ui.page.find_child("Resolution_%dx%d" % [preset.x,preset.y],true,false) as Button
			check(is_instance_valid(b) and not b.disabled,"supported headless preset "+str(preset))
		var path: String="user://resolution_qa_%d.cfg" % OS.get_process_id()
		game.ui.session_path=path
		var hd:=game.ui.page.find_child("Resolution_1600x900",true,false) as Button
		if is_instance_valid(hd): hd.pressed.emit()
		check(game.ui.window_resolution==Vector2i(1600,900) and not game.ui.window_fullscreen,"select preset switches to windowed")
		var saved: ConfigFile=Store.load_config(path)
		check(saved.get_value("settings","window_resolution",Vector2i.ZERO)==Vector2i(1600,900) and not bool(saved.get_value("settings","window_fullscreen",true)),"resolution saved")
		var restored:=UI.new()
		restored.session_path=path
		restored.size=Vector2(Geometry.RASTER)
		root.add_child(restored)
		check(restored.window_resolution==Vector2i(1600,900) and not restored.window_fullscreen,"resolution restored on startup")
		restored.queue_free()
		var full:=game.ui.page.find_child("NativeFullscreen",true,false) as Button
		if is_instance_valid(full): full.pressed.emit()
		check(game.ui.window_fullscreen and game.ui.window_resolution==Vector2i(1600,900),"fullscreen preserves window choice")
		check(game.ui.back_shortcut() and game.ui.screen=="settings","resolution back navigation")
		check(UI.fit_window_resolution(Vector2i(3840,2160),Vector2i(1920,1080))==Vector2i(1920,1080),"oversized resolution safely fits")
		for suffix in ["",".bak",".tmp",".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
		game.ui.session_path=Store.PATH
		var original_position: Vector2 = game.display.position
		var original_size: Vector2 = game.display.size
		var original_page: Vector2 = game.ui.page.size
		var hit: Vector2 = Geometry.to_raster(Vector2(100,100))
		for strength in [0.0,0.15,0.6,0.9,1.0]:
			for glass in [false,true]:
				game._set_effects(strength,glass,false,false,0.0)
				check(is_equal_approx(float(game.crt_material.get_shader_parameter("strength")),strength),"shader strength")
				check(is_equal_approx(float(game.crt_material.get_shader_parameter("bulge")),Geometry.FIXED_BULGE),"same bulge for every CRT strength")
				check(is_equal_approx(float(game.crt_material.get_shader_parameter("glass")),1.0 if glass else 0.0),"glass post effect")
				check(game.display.position==original_position and game.display.size==original_size and game.ui.page.size==original_page,"CRT cannot move or resize UI")
				check(Geometry.to_raster(Vector2(100,100))==hit,"same hit target at every strength")
		game.queue_free()
	for n in [6,8,10,14,18]:
		var area := Geometry.GAME_GRID_AREA
		var cell: Vector2 = Geometry.grid_metrics(area,n,n,4.0)
		check(cell.x==cell.y and cell.x>0 and cell.x*n+4*(n-1)<=area.x and cell.y*n+4*(n-1)<=area.y,"square grid fit")
	var game_cell: Vector2 = Geometry.grid_metrics(Geometry.GAME_GRID_AREA,8,8,float(Geometry.GAME_CELL_GAP))
	var game_extent := game_cell*8.0+Vector2.ONE*7.0*float(Geometry.GAME_CELL_GAP)
	var game_rect := Rect2(Geometry.GAME_GRID_CENTER-game_extent*0.5,game_extent)
	check(game_cell.x>=72.0,"refined cell size")
	check(game_rect.position.x>=364.0 and game_rect.end.x<=1062.0,"grid clear of sidebars")
	check(game_rect.position.y>=180.0 and game_rect.end.y<=788.0,"grid clear of header and footer")
	for lang in ["uk","en"]:
		TranslationServer.set_locale(lang)
		check(TranslationServer.translate("VIS_SETTINGS") != "VIS_SETTINGS","visual locale loaded")
		for key in ["VIS_RESOLUTION","VIS_DESKTOP_NATIVE","VIS_NATIVE_FULLSCREEN","VIS_RESOLUTION_HELP","VIS_RESOLUTION_NOTE","VIS_RESOLUTION_UNAVAILABLE"]:
			check(TranslationServer.translate(key)!=key,"resolution translation "+lang+" "+key)
	print("VISUAL_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
