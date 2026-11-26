extends Control
const Board = preload("res://scripts/board/state.gd")
const Generator = preload("res://scripts/board/generator.gd")
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
signal effects_changed(amount: float, curve: bool, reduced: bool, flicker: bool, global_amount: float)
signal fault_triggered
signal fullscreen_requested
const GREEN := Color("a1d8a0")
const DIM := Color("53775d")
const AMBER := Color("e5b86c")
const RED := Color("d36c60")
var board: Board
var certificate: Dictionary = {}
var buttons: Array[Button] = []
var title_label: Label
var status: Label
var integrity: Label
var recovered: Label
var flag_count: Label
var seed_input: LineEdit
var page: Control
var grid: GridContainer
var message_key: String = "CORE_READY"
var last_hits: int = 0
var is_uk: bool = true
var screen: String = "menu"
var amount: float = 0.45
var curve: bool = true
var reduced: bool = false
var flicker: bool = false
var global_amount: float = 0.0
func _ready() -> void:
	TranslationServer.set_locale("uk")
	theme = _terminal_theme()
	var bg := ColorRect.new()
	bg.color = Color("06110c")
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_show("menu")
func _style(fill: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s
func _terminal_theme() -> Theme:
	var t := Theme.new()
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas","Cascadia Mono","DejaVu Sans Mono","Courier New"])
	t.default_font = mono
	t.default_font_size = 29
	t.set_color("font_color","Label",GREEN)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var fill := Color("0c2117")
		var border := DIM
		if state == "hover": fill = Color("244a30"); border = GREEN
		elif state == "pressed": fill = Color("396a43"); border = GREEN
		elif state == "disabled": fill = Color("09170f"); border = Color("284436")
		elif state == "focus": fill = Color(0,0,0,0); border = AMBER
		t.set_stylebox(state,"Button",_style(fill,border))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		t.set_color(state,"Button",GREEN)
	t.set_color("font_disabled_color","Button",DIM)
	t.set_stylebox("normal","LineEdit",_style(Color("07170e"),DIM))
	t.set_stylebox("focus","LineEdit",_style(Color("0a1a12"),AMBER))
	t.set_color("font_color","LineEdit",GREEN)
	t.set_color("caret_color","LineEdit",GREEN)
	return t
func _place(n: Control, rect: Rect2, parent: Control) -> void:
	n.position = rect.position
	n.size = rect.size
	parent.add_child(n)
func _label(value: String, rect: Rect2, parent: Control, font_size: int = 28, color: Color = GREEN) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(l,rect,parent)
	return l
func _button(value: String, rect: Rect2, parent: Control, action: Callable, font_size: int = 27) -> Button:
	var b := Button.new()
	b.text = value
	b.add_theme_font_size_override("font_size",font_size)
	b.pressed.connect(action)
	_place(b,rect,parent)
	return b
func _panel(rect: Rect2) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel",_style(Color("081a10"),DIM))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(p,rect,page)
	return p
func _show(next: String) -> void:
	screen = next
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.size = size
	add_child(page)
	buttons.clear()
	_label("SAPERROR ▌",Rect2(94,66,800,86),page,67)
	_label("MINE // 0.2.0-alpha",Rect2(1010,95,330,50),page,24,DIM)
	var line := ColorRect.new()
	line.color = DIM
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(line,Rect2(88,163,1250,2),page)
	if screen == "game": _game()
	elif screen == "settings": _settings()
	elif screen == "help": _help()
	else: _menu()
func _menu() -> void:
	_label(tr("VIS_BOOT"),Rect2(124,217,1170,100),page,39)
	_label(tr("VIS_TAGLINE"),Rect2(124,309,1170,75),page,28,DIM)
	_button(tr("VIS_CONTINUE") if board != null and not board.finished() else tr("VIS_START"),Rect2(124,407,640,74),page,func(): _show("game"))
	_button(tr("VIS_HELP"),Rect2(124,500,640,74),page,func(): _show("help"))
	_button(tr("VIS_SETTINGS"),Rect2(124,593,640,74),page,func(): _show("settings"))
	_button(tr("VIS_EXIT"),Rect2(124,686,640,74),page,func(): get_tree().quit())
	_label(tr("VIS_CORE_ONLY"),Rect2(840,415,470,170),page,29,AMBER)
	_button("EN" if is_uk else "UA",Rect2(1100,744,210,60),page,_language)
func _language() -> void:
	is_uk = not is_uk
	TranslationServer.set_locale("uk" if is_uk else "en")
	_show(screen)
func _help() -> void:
	_label(tr("VIS_HELP_TEXT"),Rect2(124,215,1170,500),page,34)
	_button(tr("VIS_BACK"),Rect2(124,790,350,62),page,func(): _show("menu"))
func _settings() -> void:
	_label(tr("VIS_SETTINGS"),Rect2(124,212,1150,60),page,41)
	_button("EN" if is_uk else "UA",Rect2(124,305,300,62),page,_language)
	_button(tr("VIS_FULLSCREEN"),Rect2(444,305,720,62),page,func(): fullscreen_requested.emit())
	_button(tr("VIS_CRT")+": "+str(roundi(amount*100))+"%",Rect2(124,389,1040,62),page,func(): amount = 0.0 if amount >= 0.9 else amount+0.15; _apply(); _show("settings"))
	_button(tr("VIS_CURVE")+": "+_on_off(curve),Rect2(124,471,1040,62),page,func(): curve = not curve; _apply(); _show("settings"))
	_button(tr("VIS_MOTION")+": "+_on_off(reduced),Rect2(124,553,1040,62),page,func(): reduced = not reduced; _apply(); _show("settings"))
	_button(tr("VIS_FLICKER")+": "+_on_off(flicker),Rect2(124,635,1040,62),page,func(): flicker = not flicker; _apply(); _show("settings"))
	_button(tr("VIS_GRADE")+": "+_on_off(global_amount>0.0),Rect2(124,717,1040,62),page,func(): global_amount = 0.25 if global_amount == 0.0 else 0.0; _apply(); _show("settings"))
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("menu"))
func _on_off(value: bool) -> String:
	return tr("VIS_ON" if value else "VIS_OFF")
func _apply() -> void:
	effects_changed.emit(amount,curve,reduced,flicker,global_amount)
func _game() -> void:
	var left := _panel(Rect2(87,202,302,552))
	var right := _panel(Rect2(1045,202,294,552))
	_label(tr("VIS_SECTOR")+" 01",Rect2(17,20,270,52),left,31)
	_label(tr("VIS_DIFFICULTY")+"\n"+tr("VIS_STANDARD"),Rect2(17,91,270,86),left,25)
	integrity = _label("",Rect2(17,196,270,96),left,29)
	recovered = _label("",Rect2(17,300,270,95),left,27)
	flag_count = _label("",Rect2(17,405,270,94),left,26)
	_label(tr("VIS_RULE"),Rect2(17,20,260,46),right,27)
	_label("CLASSIC",Rect2(17,68,260,49),right,35)
	_label(tr("VIS_MODULES")+"\n—",Rect2(17,168,260,96),right,26,DIM)
	_label(tr("VIS_ANOMALY")+"\n"+tr("VIS_NONE"),Rect2(17,291,260,94),right,26)
	_label(tr("VIS_RESOURCES")+"\n—",Rect2(17,412,260,94),right,26,DIM)
	grid = GridContainer.new()
	var w: int = 8 if board == null else board.width
	var h: int = 8 if board == null else board.height
	grid.columns = w
	grid.add_theme_constant_override("h_separation",4)
	grid.add_theme_constant_override("v_separation",4)
	var cell: Vector2 = Geometry.grid_metrics(Vector2(610,552),w,h,4.0)
	var extent := Vector2(w,h)*cell+Vector2(w-1,h-1)*4.0
	_place(grid,Rect2(Vector2(717,478)-extent*0.5,extent),page)
	for i in range(w*h):
		var b := Button.new()
		b.custom_minimum_size = cell
		b.add_theme_font_size_override("font_size",maxi(14,int(cell.x*0.56)))
		b.pressed.connect(_reveal.bind(i))
		b.gui_input.connect(_cell_input.bind(i))
		grid.add_child(b)
		buttons.append(b)
	status = _label("",Rect2(94,768,1240,45),page,26)
	_label(tr("CORE_SEED"),Rect2(94,821,95,50),page,24)
	seed_input = LineEdit.new()
	seed_input.text = "1701"
	_place(seed_input,Rect2(193,816,210,55),page)
	_button(tr("CORE_NEW"),Rect2(420,816,320,55),page,_reset,24)
	_button("EN" if is_uk else "UA",Rect2(755,816,130,55),page,_language,24)
	_button(tr("VIS_BACK"),Rect2(900,816,435,55),page,func(): _show("menu"),24)
	_refresh()
func _reset() -> void:
	board = null
	certificate.clear()
	last_hits = 0
	message_key = "CORE_READY"
	_refresh()
func _reveal(i: int) -> void:
	if board == null:
		if not seed_input.text.is_valid_int():
			message_key = "CORE_SEED_BAD"
			_refresh()
			return
		var generated: Dictionary = Generator.generate(seed_input.text.to_int(),i)
		if generated.is_empty():
			message_key = "CORE_FAIL"
			_refresh()
			return
		certificate = generated["certificate"]
		board = Board.new(8,8,generated["mask"],3)
	board.reveal(i)
	_after_action()
func _cell_input(event: InputEvent, i: int) -> void:
	if board == null or board.finished(): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			board.flag(i)
			buttons[i].accept_event()
			_after_action()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			board.chord(i)
			buttons[i].accept_event()
			_after_action()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and board.cells[i] == Board.Cell.OPEN:
			board.chord(i)
			buttons[i].accept_event()
			_after_action()
		elif event.keycode == KEY_F:
			board.flag(i)
			buttons[i].accept_event()
			_after_action()
func _after_action() -> void:
	message_key = "CORE_ACTIVE"
	if board.hits > last_hits:
		message_key = "CORE_HIT"
		fault_triggered.emit()
	last_hits = board.hits
	if board.won(): message_key = "CORE_WIN"
	elif board.hp <= 0: message_key = "CORE_LOSS"
	_refresh()
func _refresh() -> void:
	var hp: int = 3 if board == null else board.hp
	integrity.text = tr("CORE_HP")+"\n"+"■ ".repeat(hp)+"□ ".repeat(3-hp)
	integrity.modulate = RED if hp < 2 else Color.WHITE
	recovered.text = tr("CORE_OPEN")+"\n%d / %d" % [0 if board == null else board.opened,54]
	var flags: int = 0
	status.text = "> " + tr(message_key)
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var state: int = Board.Cell.CLOSED if board == null else board.cells[i]
		var color: Color = DIM
		var fill: Color = Color("122b1c")
		b.text = "·"
		b.disabled = board != null and board.finished()
		var desc: String = tr("CORE_CLOSED")
		if state == Board.Cell.OPEN:
			b.text = str(board.clue(i,board.rule))
			color = GREEN
			fill = Color("07140d")
			desc = b.text
		elif state == Board.Cell.FLAG:
			b.text = "⚑"
			color = AMBER
			flags += 1
			desc = tr("CORE_FLAG")
		elif state == Board.Cell.NEUTRALIZED:
			b.text = "×"
			color = RED
			fill = Color("351610")
			desc = tr("CORE_NEUTRAL")
		b.add_theme_stylebox_override("normal",_style(fill,DIM,2))
		b.add_theme_stylebox_override("disabled",_style(fill,DIM,2))
		for key in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]:
			b.add_theme_color_override(key,color)
		b.tooltip_text = "%s %d: %s" % [tr("CORE_CELL"),i+1,desc]
	flag_count.text = tr("VIS_FLAGS")+"\n%d / 10" % flags
