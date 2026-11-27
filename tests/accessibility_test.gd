extends SceneTree
const Scene=preload("res://scenes/game/gameplay.tscn")
const Access=preload("res://scripts/ui/accessibility.gd")
const Board=preload("res://scripts/board/state.gd")
const Geometry=preload("res://scripts/ui/crt_geometry.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func key(physical: int,logical: int) -> InputEventKey:
	var event:=InputEventKey.new()
	event.physical_keycode=physical
	event.keycode=logical
	event.pressed=true
	return event
func run() -> void:
	check(Access.physical(key(KEY_F,0x410))==KEY_F,"layout-independent F")
	check(Access.physical(key(0,KEY_F))==KEY_F,"logical fallback")
	var outline:=Access.focus_style(true)
	check(outline.bg_color.a==0.0 and outline.border_color==Color.WHITE and outline.border_width_left==4,"visible non-obscuring focus")
	var game=Scene.instantiate()
	root.add_child(game)
	var ui=game.ui
	ui._show("accessibility")
	for name in ["ContrastSetting","SymbolsSetting","ClearDisplaySetting"]:
		var button:=ui.page.find_child(name,true,false) as Button
		check(is_instance_valid(button),"actual toggle "+name)
		if is_instance_valid(button): button.pressed.emit()
	check(ui.high_contrast and ui.large_symbols and ui.clear_display,"all three settings active")
	check(game.effects==0.0 and not game.grade_layer.visible,"clear mode bypasses CRT grade")
	check(game.display.position==Geometry.SCREEN.position and game.raster.size==Geometry.RASTER,"unchanged approved CRT geometry")
	ui._start_profile(1)
	check(ui.buttons[0].get_theme_font_size("font_size")>=int(ui.buttons[0].custom_minimum_size.x*0.78),"larger field symbols")
	ui.buttons[0].grab_focus()
	ui._cell_input(key(KEY_RIGHT,KEY_RIGHT),0)
	check(ui.buttons[1].has_focus(),"arrow navigation before first reveal")
	ui._cell_input(key(KEY_DOWN,KEY_DOWN),1)
	check(ui.buttons[9].has_focus(),"next row focus")
	ui._cell_input(key(KEY_LEFT,KEY_LEFT),9)
	ui._cell_input(key(KEY_LEFT,KEY_LEFT),8)
	check(ui.buttons[8].has_focus(),"no wrapping at row edge")
	ui._reveal(0)
	if ui.board!=null and not ui.board.finished():
		var index: int=ui.board.cells.find(Board.Cell.CLOSED)
		check(index>=0,"closed tile for keyboard test")
		if index>=0:
			ui.buttons[index].grab_focus()
			ui._cell_input(key(KEY_F,0x410),index)
			check(ui.board.cells[index]==Board.Cell.FLAG,"physical F sets flag")
			ui._cell_input(key(KEY_F,0x410),index)
			check(ui.board.cells[index]==Board.Cell.CLOSED,"physical F removes flag")
	else: check(false,"active generated field")
	var before: int=ui.sector_number
	check(ui.back_shortcut() and ui.screen=="menu" and ui.sector_number==before,"safe back preserves run")
	ui._show("accessibility")
	var clear:=ui.page.find_child("ClearDisplaySetting",true,false) as Button
	clear.pressed.emit()
	check(not ui.clear_display and is_equal_approx(game.effects,ui.amount),"CRT preference restored")
	check(ui.back_shortcut() and ui.screen=="settings","accessibility back")
	for lang in ["en","uk"]:
		TranslationServer.set_locale(lang)
		for id in ["ACC_TITLE","ACC_CONTRAST","ACC_SYMBOLS","ACC_CLEAR","ACC_KEYS","ACC_WARNING"]:
			check(TranslationServer.translate(id)!=id,"localized accessibility "+lang+" "+id)
	for window in [Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1440),Vector2(3840,2160),Vector2(2560,1080),Vector2(1024,768)]:
		var rect: Rect2=Geometry.fit(window)
		check(rect.position.x>=-0.001 and rect.position.y>=-0.001 and rect.end.x<=window.x+0.001 and rect.end.y<=window.y+0.001,"canvas fits display")
		var physical: Vector2=rect.position+(Geometry.SCREEN.position+Geometry.SCREEN.size*0.5)*rect.size/Geometry.CANVAS
		var local: Vector2=(physical-rect.position)*Geometry.CANVAS/rect.size-Geometry.SCREEN.position
		check(Geometry.to_raster(local).distance_to(Vector2(Geometry.RASTER)*0.5)<0.01,"unchanged click mapping")
	game.queue_free()
	print("ACCESSIBILITY_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
