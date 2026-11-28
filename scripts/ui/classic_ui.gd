extends Control
const Access=preload("res://scripts/ui/accessibility.gd")
var high_contrast: bool=false
var large_symbols: bool=false
const Classic = preload("res://scripts/board/classic_game.gd")
const Board = preload("res://scripts/board/state.gd")
signal back
signal clicked
signal ui_clicked
const StyleBank=preload("res://scripts/ui/style_bank.gd")
var style_bank:=StyleBank.new()
var shown_second: int=-1
var readout_updates: int=0
var model: Classic
var tiles: Array[Button]=[]
var body: Control
var readout: Label
var timer_button: Button
var seed_edit: LineEdit
func _ready() -> void:
	rebuild()
func label(value: String, pos: Vector2, extent: Vector2, font: int=26) -> Label:
	var l := Label.new()
	l.text=value
	l.position=pos
	l.size=extent
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font)
	body.add_child(l)
	return l
func button(value: String,pos: Vector2,extent: Vector2,cb: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.position=pos
	b.size=extent
	b.add_theme_font_size_override("font_size",24)
	b.pressed.connect(func(): ui_clicked.emit(); cb.call())
	body.add_child(b)
	return b
func rebuild() -> void:
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	body=Control.new()
	body.size=size
	add_child(body)
	tiles.clear()
	label("CLASSIC // "+tr("CLASSIC_TITLE"),Vector2(0,0),Vector2(1266,60),36)
	for i in range(3):
		var n: int=[6,8,10][i]
		var b:=button("%d × %d" % [n,n],Vector2(i*200,65),Vector2(185,54),_size.bind(i))
		b.disabled=model.profile==i
	var grid:=GridContainer.new()
	grid.columns=model.width()
	grid.position=Vector2(16,140)
	grid.add_theme_constant_override("h_separation",4)
	grid.add_theme_constant_override("v_separation",4)
	body.add_child(grid)
	var extent: float=floor((470.0-(model.width()-1)*4)/model.width())
	var focus: StyleBoxFlat=Access.focus_style(high_contrast)
	for i in range(model.width()*model.width()):
		var tile:=Button.new()
		tile.custom_minimum_size=Vector2(extent,extent)
		tile.add_theme_font_size_override("font_size",int(extent*(0.76 if large_symbols else 0.62)))
		tile.add_theme_stylebox_override("focus",focus)
		tile.pressed.connect(_move.bind(i,"reveal"))
		tile.gui_input.connect(_input_tile.bind(i))
		grid.add_child(tile)
		tiles.append(tile)
	label(tr("CORE_SEED"),Vector2(520,145),Vector2(710,40))
	seed_edit=LineEdit.new()
	seed_edit.position=Vector2(520,190)
	seed_edit.size=Vector2(710,52)
	seed_edit.text=str(model.seed_value)
	body.add_child(seed_edit)
	timer_button=button("",Vector2(520,263),Vector2(710,56),_toggle_timer)
	readout=label("",Vector2(520,340),Vector2(710,200),28)
	button(tr("TUT_REPEAT"),Vector2(520,565),Vector2(340,58),_retry)
	button(tr("VIS_BACK"),Vector2(880,565),Vector2(350,58),func(): back.emit())
	refresh()
	Access.focus_tiles(tiles)
func _size(i: int) -> void:
	model.start(i,model.seed_value)
	rebuild()
func _retry() -> void:
	var seed_value: int=seed_edit.text.to_int() if seed_edit.text.is_valid_int() else model.seed_value
	model.start(model.profile,seed_value)
	rebuild()
func _toggle_timer() -> void:
	model.timer_enabled=not model.timer_enabled
	refresh()
func _input_tile(event: InputEvent,index: int) -> void:
	if Access.grid_key(event,tiles,index,model.width()): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			tiles[index].accept_event()
			_move(index,"flag")
		elif event.button_index==MOUSE_BUTTON_MIDDLE:
			tiles[index].accept_event()
			_move(index,"chord")
	elif event is InputEventKey and event.pressed and not event.echo:
		if Access.physical(event)==KEY_F:
			tiles[index].accept_event()
			_move(index,"flag")
		elif event.keycode==KEY_SPACE and model.board!=null and model.board.cells[index]==Board.Cell.OPEN:
			tiles[index].accept_event()
			_move(index,"chord")
func _move(index: int,mode: String) -> void:
	if model.board==null and seed_edit.text.is_valid_int(): model.seed_value=seed_edit.text.to_int()
	if model.act(index,mode): clicked.emit()
	refresh()
func _process(delta: float) -> void:
	if not is_instance_valid(readout): return
	model.tick(delta)
	if model.timer_enabled and int(model.elapsed)!=shown_second: _update_readout()
func _update_readout() -> void:
	shown_second=int(model.elapsed)
	readout_updates+=1
	var b: Board=model.board
	var flags: int=0
	if b!=null:
		for cell in b.cells:
			if cell==Board.Cell.FLAG: flags+=1
	var state: String="CLASSIC_READY"
	if model.generation_failed: state="CH_INVALID"
	elif b!=null: state="CH_VICTORY" if b.won() else ("CH_DEFEAT" if b.finished() else "CORE_ACTIVE")
	readout.text=tr(state)+"\n"+tr("CLASSIC_MINES")+" %d / %d" % [flags,model.mines()]
	if model.timer_enabled: readout.text+="\n"+tr("CLASSIC_TIMER")+" %02d:%02d" % [int(model.elapsed)/60,int(model.elapsed)%60]
func refresh() -> void:
	var b: Board=model.board
	seed_edit.editable=b==null
	timer_button.text=tr("CLASSIC_TIMER")+" / "+tr("CLASSIC_ON" if model.timer_enabled else "CLASSIC_OFF")
	_update_readout()
	for i in range(tiles.size()):
		var tile: Button=tiles[i]
		var state: int=Board.Cell.CLOSED if b==null else b.cells[i]
		tile.text="·"
		if state==Board.Cell.OPEN: tile.text=str(b.clue(i,0))
		elif state==Board.Cell.FLAG: tile.text="⚑"
		elif state==Board.Cell.NEUTRALIZED: tile.text="×"
		elif b!=null and b.finished() and not b.won() and b._mask[i]==1: tile.text="×"
		tile.disabled=b!=null and b.finished()
		var fill: Color=Color("081a11") if state==Board.Cell.OPEN else Color("183b27")
		if tile.text=="×": fill=Color("491e19")
		var style: StyleBoxFlat=style_bank.get_style(fill.darkened(0.32) if high_contrast else fill,Access.readable(Color("53775d"),high_contrast),2,false)
		if tile.get_theme_stylebox("normal")!=style: tile.add_theme_stylebox_override("normal",style)
		if tile.get_theme_stylebox("disabled")!=style: tile.add_theme_stylebox_override("disabled",style)
