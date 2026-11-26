extends Control
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
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
	step = clampi(start_at,0,4)
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
	var mask := PackedByteArray()
	mask.resize(16)
	mask[0] = 1
	mask[3] = 1
	mask[15] = 1
	board = Board.new(4,4,mask,3)
	if step >= 1: board.reveal(1)
	if step == 3: board.reveal(2)
	if step == 4:
		board.reveal(4)
		board.flag(0)
	_label(tr("VIS_TUTORIAL")+" %d / 5" % (step+1),Vector2(0,0),Vector2(1266,60),40)
	_label(tr("TUT_TITLE_"+str(step)),Vector2(0,76),Vector2(1266,65),35)
	hint = _label("",Vector2(550,158),Vector2(700,360),33)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(45,158)
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	body.add_child(grid)
	tiles.clear()
	for i in range(16):
		var b := Button.new()
		b.custom_minimum_size = Vector2(104,104)
		b.add_theme_font_size_override("font_size",46)
		b.pressed.connect(_action.bind(i,"reveal"))
		b.gui_input.connect(_cell_input.bind(i))
		grid.add_child(b)
		tiles.append(b)
	_button(tr("TUT_REPEAT"),Vector2(0,620),Vector2(270,64),_build)
	_button(tr("TUT_SKIP"),Vector2(285,620),Vector2(270,64),_next)
	next_button = _button(tr("TUT_NEXT"),Vector2(570,620),Vector2(320,64),_next)
	_button(tr("VIS_BACK"),Vector2(905,620),Vector2(350,64),func(): back.emit())
	_refresh()
func _cell_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			tiles[i].accept_event()
			_action(i,"flag")
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			tiles[i].accept_event()
			_action(i,"chord")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
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
	if solved: completed.emit(step)
	_refresh()
func _next() -> void:
	if step >= 4:
		back.emit()
		return
	step += 1
	_build()
func _refresh() -> void:
	var key: String = "TUT_HINT_"+str(step)+"_"+str(phase)
	hint.text = tr("TUT_COMPLETE") if solved else tr(key)
	next_button.disabled = not solved
	for i in range(tiles.size()):
		var state: int = board.cells[i]
		var b: Button = tiles[i]
		b.text = str(board.clue(i,Rules.Rule.CLASSIC)) if state == Board.Cell.OPEN else ("⚑" if state == Board.Cell.FLAG else "·")
		var marked: bool = (step==0 and i==1) or (step==1 and (i==1 or Rules.neighbors(4,4,1).has(i))) or (step==2 and i==0) or (step==3 and i in [0,1,2]) or (step==4 and i==(4 if phase==0 else 8))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("081a11") if state == Board.Cell.OPEN else Color("183b27")
		style.border_color = Color("f0c37b") if marked else Color("53775d")
		style.set_border_width_all(4 if marked else 2)
		b.add_theme_stylebox_override("normal",style)
		b.tooltip_text = "%s %d" % [tr("CORE_CELL"),i+1]
