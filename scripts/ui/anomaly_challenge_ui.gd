extends Control
const Challenge = preload("res://scripts/board/anomaly_challenge.gd")
const Board = preload("res://scripts/board/state.gd")
signal back
signal clicked
var kind: String = "LOOP"
var model := Challenge.new()
var body: Control
var info: Label
var readout: Label
var layer_button: Button
var journal_button: Button
var sensor_buttons: Array[Button] = []
var tiles: Array[Button] = []
func _ready() -> void:
	restart()
func label(value: String, pos: Vector2, extent: Vector2, font: int = 26) -> Label:
	var l := Label.new()
	l.text=value
	l.position=pos
	l.size=extent
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font)
	body.add_child(l)
	return l
func button(value: String, pos: Vector2, extent: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.position=pos
	b.size=extent
	b.add_theme_font_size_override("font_size",24)
	b.pressed.connect(func(): clicked.emit(); cb.call())
	body.add_child(b)
	return b
func restart() -> void:
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	body=Control.new()
	body.size=size
	add_child(body)
	tiles.clear()
	model.start(kind)
	label(kind+" // "+tr("CH_AUTHORED"),Vector2(0,0),Vector2(1266,56),36)
	label(tr("CH_"+kind+"_INTRO"),Vector2(0,62),Vector2(1266,92),26)
	if model.valid:
		var grid := GridContainer.new()
		grid.columns=Challenge.SIZE
		grid.position=Vector2(18,164)
		grid.add_theme_constant_override("h_separation",5)
		grid.add_theme_constant_override("v_separation",5)
		body.add_child(grid)
		for i in range(Challenge.SIZE*Challenge.SIZE):
			var tile := Button.new()
			tile.custom_minimum_size=Vector2(84,84)
			tile.add_theme_font_size_override("font_size",34)
			tile.pressed.connect(_move.bind(i,false,false))
			tile.gui_input.connect(_tile_input.bind(i))
			grid.add_child(tile)
			tiles.append(tile)
		info=label("",Vector2(515,166),Vector2(720,116),29)
		readout=label("",Vector2(515,292),Vector2(720,222),26)
		layer_button=null
		journal_button=null
		sensor_buttons.clear()
		if kind=="LIAR":
			for index in range(3):
				sensor_buttons.append(button("S%d" % (index+1),Vector2(515+index*240,530),Vector2(225,56),_select_sensor.bind(index)))
		if kind=="DOUBLE": layer_button=button("PARALLEL: A",Vector2(515,530),Vector2(720,56),_switch_layer)
		if kind=="WATCHER": journal_button=button(tr("VIS_JOURNAL"),Vector2(515,530),Vector2(720,56),_journal)
	else:
		label(tr("CH_INVALID"),Vector2(25,180),Vector2(1100,120),30)
	button(tr("TUT_REPEAT"),Vector2(18,630),Vector2(300,60),restart)
	button(tr("VIS_BACK"),Vector2(936,630),Vector2(300,60),func(): back.emit())
	if model.valid: refresh()
func _tile_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			tiles[i].accept_event()
			_move(i,true,false)
		elif event.button_index==MOUSE_BUTTON_MIDDLE:
			tiles[i].accept_event()
			_move(i,false,true)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F:
			tiles[i].accept_event()
			_move(i,true,false)
		elif event.keycode==KEY_SPACE and model.board().cells[i]==Board.Cell.OPEN:
			tiles[i].accept_event()
			_move(i,false,true)
func _move(i: int, flag: bool, chord: bool) -> void:
	if model.act(i,flag,chord): clicked.emit()
	refresh()
func _select_sensor(index: int) -> void:
	model.submit_sensor(index)
	refresh()
func _journal() -> void:
	model.toggle_journal()
	refresh()
func _switch_layer() -> void:
	model.switch_layer()
	refresh()
func refresh() -> void:
	var b: Board = model.board()
	info.text="%s %d  |  %s %d/%d  |  %s %d" % [tr("CORE_HP"),b.hp,tr("CORE_OPEN"),b.opened,b.cells.size()-b.mine_total,tr("CH_ACTIONS"),model.actions]
	readout.text=model.details()
	if is_instance_valid(layer_button):
		layer_button.text="PARALLEL: "+("A → B" if model.active_layer==0 else "B → A")
		layer_button.disabled=model.done()
	if is_instance_valid(journal_button): journal_button.text=tr("VIS_JOURNAL")+": "+("OPEN" if model.journal_open else "CLOSED")
	if not model.notice.is_empty(): readout.text += "\n"+tr(model.notice)
	if model.done(): readout.text += "\n"+tr("CH_VICTORY" if model.won() else "CH_DEFEAT")
	for sensor in sensor_buttons: sensor.disabled=model.liar_solved or model.lost()
	for i in range(tiles.size()):
		var tile: Button=tiles[i]
		var state: int=b.cells[i]
		tile.text=str(b.clue(i,0)) if state==Board.Cell.OPEN else ("⚑" if state==Board.Cell.FLAG else ("×" if state==Board.Cell.NEUTRALIZED else "·"))
		if state==Board.Cell.OPEN and model.hidden(i): tile.text="?"
		tile.disabled=model.done() or b.finished()
		var style := StyleBoxFlat.new()
		style.bg_color=Color("081a11") if state==Board.Cell.OPEN else Color("183b27")
		if state==Board.Cell.NEUTRALIZED: style.bg_color=Color("491e19")
		style.border_color=Color("edc27b") if not model.marker(i).is_empty() else Color("53775d")
		style.set_border_width_all(3 if not model.marker(i).is_empty() else 2)
		tile.add_theme_stylebox_override("normal",style)
		tile.add_theme_stylebox_override("disabled",style)
		tile.tooltip_text="#%d %s" % [i+1,model.marker(i)]
