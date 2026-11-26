extends SceneTree
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
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
	var texture: Texture2D = load(ART) as Texture2D
	check(texture != null and texture.get_size() == Geometry.CANVAS,"original texture import")
	var poly: PackedVector2Array = Geometry.mask_points()
	check(poly.size() == 21,"mask contour")
	check(Geometry2D.is_point_in_polygon(Vector2(0.5,0.5),poly),"mask center")
	check(not Geometry2D.is_point_in_polygon(Vector2(0.0,0.0),poly),"mask corners excluded")
	for window in [Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1440),Vector2(3840,2160),Vector2(1024,768),Vector2(2560,1080)]:
		var rect: Rect2 = Geometry.fit(window)
		check(absf(rect.size.aspect()-Geometry.CANVAS.aspect())<0.00001,"aspect ratio")
		check(rect.position.x >= -0.001 and rect.position.y >= -0.001,"letterbox bounds")
		for curve in [0.0,0.025]:
			for local in [Vector2(100,100),Geometry.SCREEN.size*0.5,Vector2(600,380)]:
				var physical: Vector2 = rect.position+(Geometry.SCREEN.position+local)*rect.size/Geometry.CANVAS
				var recovered: Vector2 = (physical-rect.position)*Geometry.CANVAS/rect.size-Geometry.SCREEN.position
				check(Geometry.to_raster(recovered,curve).distance_to(Geometry.to_raster(local,curve))<0.01,"window to CRT hit mapping")
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
	print("VISUAL_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
