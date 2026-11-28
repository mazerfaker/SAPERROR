extends Control
const Access=preload("res://scripts/ui/accessibility.gd")
var high_contrast: bool=false
var large_symbols: bool=false
var text_scale: float=1.0
const Challenge = preload("res://scripts/board/anomaly_challenge.gd")
const Board = preload("res://scripts/board/state.gd")
const BossEmblem = preload("res://scripts/ui/boss_emblem.gd")
var boss_identity: String = ""
var reduced_motion: bool = false
var emblem: BossEmblem
# Embedded terminal views provide a dedicated slot outside the challenge body.
var emblem_host: Control
signal back
signal clicked
signal ui_clicked
signal encounter_won
signal trial_completed(id: String)
signal immersion_event(id: String)
const Immersion=preload("res://scripts/ui/immersion.gd")
var completion_reported: bool=false
var campaign_encounter: bool = false
var guided_encounter: bool=false
var reworked_encounter: bool=false
var encounter_profile: int=1
var encounter_seed: int=1701
var reward_id: String=""
var signal_button: Button
var reward_hint_button: Button
var coach: Label
var encounter_hp: int=3
var encounter_title: String = ""
var proceed_button: Button
var kind: String = "LOOP"
const StyleBank=preload("res://scripts/ui/style_bank.gd")
var style_bank:=StyleBank.new()
var model := Challenge.new()
var body: Control
var info: Label
var readout: Label
var layer_button: Button
var journal_button: Button
var scan_button: Button
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
	l.add_theme_font_size_override("font_size",Access.fit_font(get_theme_default_font(),value,font,text_scale,extent,true))
	body.add_child(l)
	return l
func button(value: String, pos: Vector2, extent: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.position=pos
	b.size=extent
	b.add_theme_font_size_override("font_size",Access.fit_font(get_theme_default_font(),value,24,text_scale,extent-Vector2(12,8),false))
	b.pressed.connect(func(): ui_clicked.emit(); cb.call())
	body.add_child(b)
	return b
func restart() -> void:
	if is_instance_valid(emblem) and is_instance_valid(emblem_host) and emblem.get_parent()==emblem_host:
		emblem_host.remove_child(emblem)
		emblem.queue_free()
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	body=Control.new()
	body.size=size
	add_child(body)
	tiles.clear()
	completion_reported=false
	if reworked_encounter: model.start_reworked(kind,encounter_hp,encounter_profile,encounter_seed,reward_id)
	else: model.start(kind,encounter_hp if campaign_encounter else 3)
	var identity: String=boss_identity if not boss_identity.is_empty() else BossEmblem.resolve(kind)
	emblem=null
	var text_width: float=1060.0 if not identity.is_empty() and not is_instance_valid(emblem_host) else 1266.0
	var title_label:=label((encounter_title if not encounter_title.is_empty() else kind)+" // "+tr("RC7_BOSS_TITLE" if reworked_encounter else "CH_AUTHORED"),Vector2(0,0),Vector2(text_width,56),36)
	label(tr("RC7_BOSS_"+kind if reworked_encounter else "CH_"+kind+"_INTRO"),Vector2(0,62),Vector2(text_width,92),24 if not identity.is_empty() else 26)
	if BossEmblem.ART.has(identity):
		title_label.add_theme_color_override("font_color",BossEmblem.TINTS[identity])
		emblem=BossEmblem.new()
		emblem.boss_id=identity
		emblem.reduced_motion=reduced_motion
		if is_instance_valid(emblem_host):
			emblem.position=Vector2.ZERO
			emblem.size=emblem_host.size
			emblem_host.add_child(emblem)
		else:
			emblem.position=Vector2(1070,0)
			emblem.size=Vector2(196,154)
			body.add_child(emblem)
	if model.valid:
		var grid := GridContainer.new()
		grid.columns=model.board().width
		grid.position=Vector2(18,164)
		var gap: int=4 if reworked_encounter else 5
		grid.add_theme_constant_override("h_separation",gap)
		grid.add_theme_constant_override("v_separation",gap)
		var cell: int=floori((478.0-(grid.columns-1)*gap)/grid.columns) if reworked_encounter else 84
		body.add_child(grid)
		var focus: StyleBoxFlat=Access.focus_style(high_contrast)
		for i in range(model.board().cells.size()):
			var tile := Button.new()
			tile.custom_minimum_size=Vector2(cell,cell)
			tile.add_theme_font_size_override("font_size",maxi(12,floori(cell*(0.72 if large_symbols else 0.58))) if reworked_encounter else (42 if large_symbols else 34))
			tile.add_theme_stylebox_override("focus",focus)
			tile.pressed.connect(_move.bind(i,false,false))
			tile.gui_input.connect(_tile_input.bind(i))
			grid.add_child(tile)
			tiles.append(tile)
			var tag:=Label.new()
			tag.name="MechanicBadge"
			tag.position=Vector2(4,1)
			tag.add_theme_font_size_override("font_size",11 if reworked_encounter else 16)
			tag.mouse_filter=Control.MOUSE_FILTER_IGNORE
			tile.add_child(tag)
		info=label("",Vector2(515,166),Vector2(720,70 if guided_encounter else 116),26 if guided_encounter else 29)
		coach=null
		if guided_encounter:
			coach=label("",Vector2(515,239),Vector2(720,66),23)
			coach.add_theme_color_override("font_color",Access.readable(Color("edc27b"),high_contrast))
		readout=label("",Vector2(515,310 if guided_encounter else 292),Vector2(720,204 if guided_encounter else 222),22 if guided_encounter else 26)
		layer_button=null
		journal_button=null
		scan_button=null
		sensor_buttons.clear()
		signal_button=null
		reward_hint_button=null
		if reworked_encounter:
			signal_button=button(tr("RC7_RESTORE_SIGNAL"),Vector2(515,530),Vector2(350,56),func(): model.restore_signal(); refresh())
			if reward_id=="ASSISTANT": reward_hint_button=button(tr("VIS_HINT"),Vector2(875,530),Vector2(360,56),func(): model.reward_hint(); refresh())
		if not reworked_encounter and kind=="LIAR":
			for index in range(3):
				sensor_buttons.append(button(tr("CH_SENSOR_NAME") % "ABC".substr(index,1),Vector2(515+index*240,530),Vector2(225,56),_select_sensor.bind(index)))
		if kind in ["DOUBLE","ADMIN_LINK","INSTABILITY","MAGNET"]: layer_button=button("PARALLEL: A",Vector2(515,530),Vector2(720,56),_switch_layer)
		if not reworked_encounter and kind=="WATCHER": journal_button=button(tr("VIS_JOURNAL"),Vector2(515,530),Vector2(720,56),_journal)
		if kind=="NULL": scan_button=button(tr("VIS_HINT"),Vector2(515,530),Vector2(720,56),_scan)
	else:
		label(tr("CH_INVALID"),Vector2(25,180),Vector2(1100,120),30)
	button(tr("TUT_REPEAT"),Vector2(18,630),Vector2(300,60),restart)
	button(tr("VIS_BACK"),Vector2(936,630),Vector2(300,60),func(): back.emit())
	proceed_button=null
	if campaign_encounter and model.valid:
		proceed_button=button(tr("CAM_ENTER"),Vector2(350,630),Vector2(550,60),_proceed)
	if model.valid: refresh()
	if not Access.focus_tiles(tiles): Access.focus_first(body)
func _tile_input(event: InputEvent, i: int) -> void:
	if Access.grid_key(event,tiles,i,model.board().width): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			tiles[i].accept_event()
			_move(i,true,false)
		elif event.button_index==MOUSE_BUTTON_MIDDLE:
			tiles[i].accept_event()
			_move(i,false,true)
	elif event is InputEventKey and event.pressed and not event.echo:
		if Access.physical(event)==KEY_F:
			tiles[i].accept_event()
			_move(i,true,false)
		elif event.keycode==KEY_SPACE and model.board().cells[i]==Board.Cell.OPEN:
			tiles[i].accept_event()
			_move(i,false,true)
func _move(i: int, flag: bool, chord: bool) -> void:
	var old_notice: String=model.notice
	var old_hits: int=model.board().hits if model.valid else 0
	if model.act(i,flag,chord):
		clicked.emit()
		if model.notice!=old_notice and model.notice in ["CH_INST_SWITCH","CH_LOOP_RESET","CH_WATCHER_CLOSED","RC7_WATCHER_EVENT","RC7_LIAR_EVENT","RC7_LOOP_EVENT","RC7_PHASE_CHANGED"]:
			immersion_event.emit(Immersion.identity(kind))
		elif model.board().hits>old_hits:
			immersion_event.emit(Immersion.identity(kind))
	refresh()
func can_protocol_complete() -> bool:
	return model.valid and not model.lost() and (not model.won() or campaign_encounter)
func complete_with_protocol() -> bool:
	if not can_protocol_complete(): return false
	if not model.protocol_complete(): return false
	refresh()
	if campaign_encounter: _proceed()
	return true
func _proceed() -> void:
	if campaign_encounter and model.won(): encounter_won.emit()
func _select_sensor(index: int) -> void:
	var old_notice: String=model.notice
	model.submit_sensor(index)
	if model.notice!=old_notice: immersion_event.emit("LIAR")
	refresh()
func _scan() -> void:
	var old_notice: String=model.notice
	model.optional_scan()
	if model.notice!=old_notice and model.notice=="CH_NULL_BLOCKED": immersion_event.emit("NULL")
	refresh()
func _journal() -> void:
	model.toggle_journal()
	refresh()
func _switch_layer() -> void:
	var layer: int=model.active_layer
	var portal: bool=model.board().portal_enabled if model.valid else false
	var rule: int=model.board().rule if model.valid else 0
	var committed: bool=model.magnet_committed
	model.switch_layer()
	if model.valid and (layer!=model.active_layer or portal!=model.board().portal_enabled or rule!=model.board().rule or committed!=model.magnet_committed): immersion_event.emit(Immersion.identity(kind))
	refresh()
func refresh() -> void:
	var b: Board = model.board()
	info.text="%s %d  |  %s %d/%d  |  %s %d" % [tr("CORE_HP"),b.hp,tr("CORE_OPEN"),b.opened,b.cells.size()-b.mine_total,tr("CH_ACTIONS"),model.actions]
	readout.text=model.details()
	if guided_encounter and is_instance_valid(coach):
		var key: String="RC7_SIGNAL_HELP" if reworked_encounter else "BOSS_COACH_"+kind
		if model.won(): key="BOSS_COACH_WIN"
		elif model.lost(): key="BOSS_COACH_LOSS"
		elif not reworked_encounter and kind=="WATCHER" and model.journal_open: key="BOSS_COACH_WATCHER_OPEN"
		elif not reworked_encounter and kind=="LIAR" and model.liar_solved: key="BOSS_COACH_LIAR_DONE"
		elif kind=="DOUBLE" and b.won(): key="BOSS_COACH_DOUBLE_SWITCH"
		coach.text=tr(key)
		coach.tooltip_text=coach.text
		coach.add_theme_font_size_override("font_size",Access.fit_font(get_theme_default_font(),coach.text,23,text_scale,Vector2(720,66),true))
	if is_instance_valid(layer_button):
		layer_button.text=tr("PORTAL_DISABLE" if b.portal_enabled else "PORTAL_ENABLE") if kind=="ADMIN_LINK" else tr("CH_SWITCH_FIELD") % (2-model.active_layer)
		layer_button.disabled=model.done()
		if kind=="MAGNET":
			layer_button.text=tr("CH_MAGNET_COMMITTED" if model.magnet_committed else "CH_MAGNET_APPLY")
			layer_button.disabled=model.magnet_committed or model.done()
		elif kind=="INSTABILITY":
			layer_button.text=tr("CH_SWITCH_CROSS" if b.rule==0 else "CH_SWITCH_CLASSIC")
			layer_button.disabled=not model.instability_triggered or model.done()
	if is_instance_valid(signal_button): signal_button.disabled=model.corruption.is_empty() or model.done()
	if is_instance_valid(reward_hint_button):
		reward_hint_button.text=tr("VIS_HINT")+" [%d]" % model.hints_remaining
		reward_hint_button.disabled=model.hints_remaining<=0 or model.done()
	if is_instance_valid(scan_button): scan_button.disabled=model.scan_used or model.done()
	if is_instance_valid(journal_button): journal_button.text=tr("CH_CLOSE_JOURNAL" if model.journal_open else "CH_OPEN_JOURNAL")
	if not model.notice.is_empty(): readout.text += "\n"+tr(model.notice)
	if model.done(): readout.text += "\n"+tr("CH_VICTORY" if model.won() else "CH_DEFEAT")
	readout.add_theme_font_size_override("font_size",Access.fit_font(get_theme_default_font(),readout.text,22 if guided_encounter else 26,text_scale,Vector2(720,204 if guided_encounter else 222),true))
	readout.tooltip_text=readout.text
	if is_instance_valid(layer_button): layer_button.add_theme_font_size_override("font_size",Access.fit_font(get_theme_default_font(),layer_button.text,24,text_scale,Vector2(708,48),false))
	if is_instance_valid(proceed_button): proceed_button.disabled=not model.won()
	for sensor in sensor_buttons: sensor.disabled=model.liar_solved or model.lost()
	for i in range(tiles.size()):
		var tile: Button=tiles[i]
		var state: int=b.cells[i]
		tile.text=model.display_clue(i) if state==Board.Cell.OPEN else ("⚑" if state==Board.Cell.FLAG else ("×" if state==Board.Cell.NEUTRALIZED else "·"))
		if state==Board.Cell.OPEN and model.hidden(i): tile.text="?"
		if state==Board.Cell.CLOSED and model.marker(i)=="MIMIC": tile.text="~"
		tile.disabled=model.done() or b.finished() or (kind=="MAGNET" and not model.magnet_committed)
		var fill: Color=Color("081a11") if state==Board.Cell.OPEN else Color("183b27")
		if state==Board.Cell.NEUTRALIZED: fill=Color("491e19")
		var marker: String=model.badge(i)
		var marked: bool=not marker.is_empty()
		var tag:=tile.get_node_or_null("MechanicBadge") as Label
		var edge: Color=Color("edc27b") if marked else Color("53775d")
		if kind=="ADMIN_LINK" and marked: edge=Color("7ac5d0") if b.portal_enabled else Color("53775d")
		if reworked_encounter:
			var ink: Color=Access.readable(Color("edc27b") if model.corruption.has(i) else Color("b6edb1"),high_contrast)
			for key in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]: tile.add_theme_color_override(key,ink)
		if kind=="DOUBLE" and marked: edge=Color("7ac5d0") if marker=="A" else Color("edc27b")
		if is_instance_valid(tag):
			tag.text=marker
			tag.visible=marked
			tag.add_theme_color_override("font_color",Access.readable(edge,high_contrast))
		var style: StyleBoxFlat=style_bank.get_style(fill.darkened(0.32) if high_contrast else fill,Access.readable(edge,high_contrast),3 if marked else 2,false)
		if tile.get_theme_stylebox("normal")!=style: tile.add_theme_stylebox_override("normal",style)
		if tile.get_theme_stylebox("disabled")!=style: tile.add_theme_stylebox_override("disabled",style)
		var desc: String=model.cell_description(i)
		tile.tooltip_text=desc if not desc.is_empty() else tr("CORE_CELL")+" "+str(i+1)
	if model.won() and not completion_reported and not campaign_encounter:
		completion_reported=true
		trial_completed.emit(kind)
