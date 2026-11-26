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
		for curve in [0.0,0.024,0.096,0.16]:
			for local in [Vector2(100,100),Geometry.SCREEN.size*0.5,Vector2(600,380)]:
				var physical: Vector2 = rect.position+(Geometry.SCREEN.position+local)*rect.size/Geometry.CANVAS
				var recovered: Vector2 = (physical-rect.position)*Geometry.CANVAS/rect.size-Geometry.SCREEN.position
				check(Geometry.to_raster(recovered,curve).distance_to(Geometry.to_raster(local,curve))<0.01,"window to CRT hit mapping")
	check(Geometry.curvature_for(0.0,true)==0.0,"CRT off identity")
	check(Geometry.curvature_for(1.0,false)==0.0,"curvature disabled")
	check(Geometry.curvature_for(0.9,true)>Geometry.curvature_for(0.15,true),"intensity scales curvature")
	for amount in [0.0,0.15,0.6,0.9,1.0]:
		var c: float = Geometry.curvature_for(amount,true)
		check(Geometry.warp(Vector2(0.5,0.5),c).is_equal_approx(Vector2(0.5,0.5)),"center invariant")
		for y in range(11):
			for x in range(11):
				var uv := Vector2(x,y)/10.0
				var warped: Vector2 = Geometry.warp(uv,c)
				check(warped.x>=-0.00001 and warped.x<=1.00001 and warped.y>=-0.00001 and warped.y<=1.00001,"warp no black border")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	check(scene!=null,"CRT scene loads")
	if scene != null:
		var game = scene.instantiate()
		root.add_child(game)
		for strength in [0.0,0.15,0.6,0.9,1.0]:
			game._set_effects(strength,true,false,false,0.0)
			check(is_equal_approx(game.curvature,Geometry.curvature_for(strength,true)),"CPU curvature intensity")
			check(is_equal_approx(float(game.crt_material.get_shader_parameter("curvature")),game.curvature),"shader/input agreement")
			check(is_equal_approx(float(game.crt_material.get_shader_parameter("strength")),strength),"shader strength")
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
	print("VISUAL_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
