extends Control
const Access=preload("res://scripts/ui/accessibility.gd")
var high_contrast: bool=false
var large_symbols: bool=false
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Economy = preload("res://scripts/run/economy.gd")
const Phantom = preload("res://scripts/board/phantom.gd")
var phantom := Phantom.new()
var practice := Economy.new()
var practice_label: Label
var prior: Dictionary = {}
var tool_button: Button
signal completed(step: int)
signal back
var start_at: int = 0
var step: int = 0
var phase: int = 0
var solved: bool = false
var board: Board
var body: Control
var tiles: Array[Button] = []
var hint: Label
var next_button: Button
func _ready() -> void:
	step = clampi(start_at,0,8)
	_build()
func _label(value: String, p: Vector2, extent: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.text = value
	l.position = p
	l.size = extent
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font_size)
	body.add_child(l)
	return l
func _button(value: String, p: Vector2, extent: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.position = p
	b.size = extent
	b.pressed.connect(action)
	body.add_child(b)
	return b
func _build() -> void:
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	body = Control.new()
	body.size = size
	add_child(body)
	phase = 0
	solved = false
	phantom = Phantom.new()
	var mask := PackedByteArray()
	mask.resize(16)
	mask[0] = 1
	mask[3] = 1
	mask[15] = 1
	board = Board.new(4,4,mask,3)
	if step>=1 and step<=4: board.reveal(1)
	prior.clear()
	if step==5:
		board.reveal(1)
		prior = Tools.capture(board)
	if step==6:
		mask.fill(0)
		mask[0]=1
		mask[1]=1
		mask[4]=1
		board = Board.new(4,4,mask,3)
		board.reveal(5)
	if step==8:
		board.reveal(1)
		phantom.trigger(board,1)
	if step == 3: board.reveal(2)
	if step == 4:
		board.reveal(4)
		board.flag(0)
	_label(tr("VIS_TUTORIAL")+" %d / 9" % (step+1),Vector2(0,0),Vector2(1266,60),40)
	_label(tr("TUT_TITLE_"+str(step)),Vector2(0,76),Vector2(1266,65),35)
	hint = _label("",Vector2(550,158),Vector2(700,360),33)
	tool_button = null
	if step>=5:
		tool_button = _button(tr("VIS_REWIND") if step==5 else ("CLASSIC" if step==6 else (tr("MOD_CAPACITOR")+" / 28 CR" if step==7 else tr("VIS_JOURNAL"))),Vector2(550,530),Vector2(700,64),_lesson_tool)
	if step==7:
		practice.reset(1)
		practice.reward(1,54,0)
		practice.begin_sector(2)
		practice_label = _label("",Vector2(45,185),Vector2(470,300),32)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(45,158)
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	body.add_child(grid)
	tiles.clear()
	var focus: StyleBoxFlat=Access.focus_style(high_contrast)
	for i in range(0 if step==7 else 16):
		var b := Button.new()
		b.custom_minimum_size = Vector2(104,104)
		b.add_theme_font_size_override("font_size",56 if large_symbols else 46)
		b.add_theme_stylebox_override("focus",focus)
		b.pressed.connect(_action.bind(i,"reveal"))
		b.gui_input.connect(_cell_input.bind(i))
		grid.add_child(b)
		tiles.append(b)
	_button(tr("TUT_REPEAT"),Vector2(0,620),Vector2(270,64),_build)
	_button(tr("TUT_SKIP"),Vector2(285,620),Vector2(270,64),_next)
	next_button = _button(tr("TUT_NEXT"),Vector2(570,620),Vector2(320,64),_next)
	_button(tr("VIS_BACK"),Vector2(905,620),Vector2(350,64),func(): back.emit())
	_refresh()
	if not Access.focus_tiles(tiles): Access.focus_first(body)
func _cell_input(event: InputEvent, i: int) -> void:
	if Access.grid_key(event,tiles,i,4): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			tiles[i].accept_event()
			_action(i,"flag")
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			tiles[i].accept_event()
			_action(i,"chord")
	elif event is InputEventKey and event.pressed and not event.echo:
		if Access.physical(event)==KEY_F:
			tiles[i].accept_event()
			_action(i,"flag")
		elif event.keycode == KEY_SPACE and board.cells[i] == Board.Cell.OPEN:
			tiles[i].accept_event()
			_action(i,"chord")
func _action(i: int, kind: String) -> void:
	if solved: return
	match step:
		0:
			if i == 1 and kind == "reveal":
				board.reveal(i)
				solved = board.cells[i] == Board.Cell.OPEN
		1:
			if i == 1 and kind == "reveal": solved = board.clue(i,Rules.Rule.CLASSIC) == 1
		2:
			if i == 0 and kind == "flag":
				board.flag(i)
				if phase == 0 and board.cells[i] == Board.Cell.FLAG: phase = 1
				elif phase == 1 and board.cells[i] == Board.Cell.CLOSED: solved = true
		3:
			if i == 0 and kind == "flag":
				board.flag(i)
				solved = board.cells[i] == Board.Cell.FLAG
		4:
			if phase == 0 and i == 4 and kind == "chord":
				var before: int = board.opened
				board.chord(i)
				if board.opened > before: phase = 1
			elif phase == 1 and i == 8 and kind == "reveal":
				var before: int = board.opened
				board.reveal(i)
				solved = board.opened > before or board.cells[i] == Board.Cell.OPEN
		5:
			if phase==0 and i==0 and kind=="reveal":
				board.reveal(i)
				if board.hp==2: phase=1
	if solved: completed.emit(step)
	_refresh()
func _next() -> void:
	if step >= 8:
		back.emit()
		return
	step += 1
	_build()
func _refresh() -> void:
	var key: String = "TUT_HINT_"+str(step)+"_"+str(phase)
	hint.text = tr("TUT_COMPLETE") if solved else tr(key)
	next_button.disabled = not solved
	if is_instance_valid(tool_button):
		tool_button.disabled = solved or (step==5 and phase==0)
		if step==6: tool_button.text = Tools.NAMES[board.rule]
		if step==8: tool_button.text = tr("VIS_JOURNAL") if phase==0 else tr("VIS_CLEANSE")
		if step==7:
			practice_label.text = "CR %d\n%s %d/%d\n%s %d/4" % [practice.credits,tr("VIS_STOCK"),practice.stock,practice.capacity(),tr("VIS_MODULES"),practice.owned.size()]
	for i in range(tiles.size()):
		var state: int = board.cells[i]
		var b: Button = tiles[i]
		b.text = str(board.clue(i,board.rule)) if state == Board.Cell.OPEN else ("⚑" if state == Board.Cell.FLAG else ("×" if state==Board.Cell.NEUTRALIZED else "·"))
		if step==8 and phantom.hidden(i,board.rule): b.text = "?"
		var marked: bool = (step==8 and i==1) or (step==0 and i==1) or (step==1 and (i==1 or Rules.neighbors(4,4,1).has(i))) or (step==2 and i==0) or (step==3 and i in [0,1,2]) or (step==4 and i==(4 if phase==0 else 8))
		marked = marked or (step==5 and i==0) or (step==6 and (i==5 or Rules.neighbors(4,4,5,board.rule).has(i)))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("081a11") if state == Board.Cell.OPEN else Color("183b27")
		style.border_color = Access.readable(Color("f0c37b") if marked else Color("53775d"),high_contrast)
		if high_contrast: style.bg_color=style.bg_color.darkened(0.32)
		style.set_border_width_all(4 if marked else 2)
		b.add_theme_stylebox_override("normal",style)
		b.tooltip_text = "%s %d" % [tr("CORE_CELL"),i+1]

func _lesson_tool() -> void:
	if solved: return
	if step==5 and phase==1:
		solved = Tools.restore_action(board,prior) and board.hp==3 and board.cells[0]==Board.Cell.CLOSED
	elif step==6:
		board.rule = (board.rule+1)%3
		phase += 1
		if phase>=2: solved = board.clue(5,Rules.Rule.DIAGONAL)==1
	elif step==7:
		solved = practice.buy("CAPACITOR") and practice.capacity()==6 and practice.credits==47
	elif step==8:
		if phase==0 and phantom.active() and phantom.value==board.clue(1,board.rule): phase=1
		elif phase==1: solved = phantom.clear_zone() and not phantom.active()
	if solved: completed.emit(step)
	_refresh()
