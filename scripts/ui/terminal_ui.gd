extends Control
const Board = preload("res://scripts/board/state.gd")
const Generator = preload("res://scripts/board/generator.gd")
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const TerminalAudio = preload("res://scripts/audio/terminal_audio.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Tutorial = preload("res://scripts/ui/tutorial.gd")
const Protocol = preload("res://scripts/ui/protocol_k30.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Rules = preload("res://scripts/board/rules.gd")
signal effects_changed(amount: float, glass: bool, reduced: bool, flicker: bool, global_amount: float, glitches: bool)
signal protocol_triggered
signal fault_triggered
signal fullscreen_requested
signal shutdown_requested
signal outcome_triggered(won: bool)
const GREEN := Color("b6edb1")
const DIM := Color("729b79")
const AMBER := Color("f0c37b")
const RED := Color("f18b7d")
var boot_overlay: Control
var boot_log: Label
var boot_meter: ColorRect
var boot_percent: Label
var outcome_banner: Control
var audio: TerminalAudio
var board: Board
var hints_left: int = 1
var rewinds_left: int = 1
var rewind_data: Dictionary = {}
var hint_cell: int = -1
var hint_sources: Array[int] = []
var rule_button: Button
var hint_button: Button
var rewind_button: Button
var marks: Array[Panel] = []
var hover_cell: int = -1
var sector_number: int = 1
var pending_sector: bool = false
var sector_ready: bool = false
var next_button: Button
var protocol := Protocol.new()
var protocol_active: bool = false
var protocol_log: Label
var protocol_panel: Panel
var protocol_elapsed: float = 0.0
var protocol_finished: bool = false
var protocol_finish_elapsed: float = 0.0
var protocol_scan: float = -1.0
var profile: int = 1
var active_seed: int = 1701
var first_cell: int = -1
var sessions: int = 0
var wins: int = 0
var losses: int = 0
var save_failed: bool = false
var cfg := ConfigFile.new()
var tutorial: Tutorial
var tutorial_done: int = 0
var certificate: Dictionary = {}
var buttons: Array[Button] = []
var title_label: Label
var status: Label
var integrity: Label
var recovered: Label
var flag_count: Label
var seed_input: LineEdit
var seed_value: String = "1701"
var progress_fill: ColorRect
var last_states := PackedInt32Array()
var page: Control
var grid: GridContainer
var message_key: String = "CORE_READY"
var last_hits: int = 0
var is_uk: bool = true
var screen: String = "menu"
var amount: float = 0.45
var glass: bool = true
var reduced: bool = false
var flicker: bool = true
var glitches: bool = true
var global_amount: float = 0.0
func _ready() -> void:
	_load_session()
	TranslationServer.set_locale("uk" if is_uk else "en")
	theme = _terminal_theme()
	audio = TerminalAudio.new()
	audio.set_levels(float(cfg.get_value("settings","sfx",0.55)),float(cfg.get_value("settings","hum",0.28)),bool(cfg.get_value("settings","sound",true)))
	add_child(audio)
	var bg := ColorRect.new()
	bg.color = Color("081710")
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_show("menu")
func _style(fill: Color, border: Color, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 2
	s.content_margin_bottom = 2
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
	b.pressed.connect(func():
		if protocol_active: return
		audio.play_event("key")
		action.call())
	_place(b,rect,parent)
	return b
func _panel(rect: Rect2) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel",_style(Color("081a10"),DIM))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(p,rect,page)
	return p
func _show(next: String) -> void:
	if protocol_active: return
	protocol.reset_input()
	if is_instance_valid(seed_input):
		seed_value = seed_input.text
		seed_input = null
	screen = next
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.size = size
	add_child(page)
	buttons.clear()
	marks.clear()
	hover_cell = -1
	_label("SAPERROR ▌",Rect2(88,52,800,92),page,72)
	var version := _label("MINE // 0.3.0-a3",Rect2(850,82,486,48),page,24,DIM)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var line := ColorRect.new()
	line.color = DIM
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(line,Rect2(80,153,1266,2),page)
	if screen == "game": _game()
	elif screen == "settings": _settings()
	elif screen == "help": _help()
	elif screen == "audio": _audio_settings()
	elif screen == "profiles": _profiles()
	elif screen == "tutorial": _tutorial()
	else: _menu()
func _menu() -> void:
	_label(tr("VIS_BOOT"),Rect2(124,190,1170,80),page,36)
	_label(tr("VIS_TAGLINE"),Rect2(124,266,1170,62),page,28,DIM)
	var resume := _button(tr("VIS_CONTINUE"),Rect2(124,345,640,65),page,_continue_run)
	resume.disabled = not pending_sector and not sector_ready and (board == null or board.finished())
	_button(tr("VIS_NEW_GAME"),Rect2(124,423,640,65),page,func(): _show("profiles"))
	_button(tr("VIS_TUTORIAL"),Rect2(124,501,640,65),page,func(): _show("tutorial"))
	_button(tr("VIS_HELP"),Rect2(124,579,640,65),page,func(): _show("help"))
	_button(tr("VIS_SETTINGS"),Rect2(124,657,640,65),page,func(): _show("settings"))
	_button(tr("VIS_EXIT"),Rect2(124,735,640,65),page,func(): _save_session(); shutdown_requested.emit())
	_label(tr("VIS_STATS")+"\n"+tr("VIS_RUNS")+" "+str(sessions)+"\n"+tr("VIS_WINS")+" "+str(wins)+"\n"+tr("VIS_LOSSES")+" "+str(losses),Rect2(820,345,500,285),page,32)
	_label(tr("VIS_LESSONS")+" %d / 7" % tutorial_done,Rect2(820,650,500,62),page,29,AMBER)
	if save_failed: _label(tr("VIS_SAVE_ERROR"),Rect2(820,714,500,80),page,27,RED)
	_button("EN" if is_uk else "UA",Rect2(1100,810,210,60),page,_language)
func _profiles() -> void:
	_label(tr("VIS_DIFFICULTY"),Rect2(124,190,1170,70),page,42)
	if board != null and not board.finished():
		_label(tr("VIS_REPLACE_RUN"),Rect2(124,265,1170,80),page,29,AMBER)
	for i in range(4):
		var label: String = tr("VIS_PROFILE_"+Profiles.IDS[i].to_upper())+"  //  %d×%d  ·  %d  ·  HP %d" % [Profiles.SIZES[i],Profiles.SIZES[i],Profiles.MINES[i],Profiles.HP[i]]
		_button(label,Rect2(124,350+i*100,1170,74),page,_start_profile.bind(i),32)
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("menu"))
func _start_profile(next_profile: int) -> void:
	if protocol_active: return
	sector_number = 1
	pending_sector = false
	sector_ready = true
	profile = next_profile
	_reset_tools()
	board = null
	certificate.clear()
	first_cell = -1
	last_hits = 0
	message_key = "CORE_READY"
	_save_session()
	_show("game")
func _continue_run() -> void:
	if pending_sector: _advance_sector()
	else: _show("game")
func _advance_sector() -> void:
	if protocol_active or not pending_sector: return
	# Shared completion route for normal wins and the hidden protocol.
	pending_sector = false
	sector_ready = true
	sector_number += 1
	_reset_tools()
	active_seed = 0 if active_seed == 9223372036854775807 else active_seed+1
	if is_instance_valid(seed_input):
		seed_input.text = str(active_seed)
	seed_value = str(active_seed)
	board = null
	certificate.clear()
	first_cell = -1
	last_hits = 0
	message_key = "CORE_READY"
	_save_session()
	_show("game")
func _tutorial() -> void:
	tutorial = Tutorial.new()
	tutorial.size = Vector2(1266,710)
	tutorial.position = Vector2(80,180)
	tutorial.theme = theme
	tutorial.start_at = mini(tutorial_done,6)
	tutorial.completed.connect(func(step: int):
		tutorial_done = maxi(tutorial_done,step+1)
		_save_session())
	tutorial.back.connect(func(): _show("menu"))
	page.add_child(tutorial)
func _load_session() -> void:
	if DisplayServer.get_name() != "headless": cfg = Store.load_config()
	is_uk = bool(cfg.get_value("settings","uk",true))
	amount = clampf(float(cfg.get_value("settings","crt",0.45)),0.0,1.0)
	glass = bool(cfg.get_value("settings","glass",true))
	reduced = bool(cfg.get_value("settings","reduced",false))
	flicker = bool(cfg.get_value("settings","flicker_v2",true))
	glitches = bool(cfg.get_value("settings","glitches",true))
	global_amount = clampf(float(cfg.get_value("settings","grade",0.0)),0.0,1.0)
	tutorial_done = clampi(int(cfg.get_value("stats","tutorial",0)),0,7)
	sessions = maxi(0,int(cfg.get_value("stats","sessions",0)))
	wins = maxi(0,int(cfg.get_value("stats","wins",0)))
	losses = maxi(0,int(cfg.get_value("stats","losses",0)))
	sector_number = maxi(1,int(cfg.get_value("run","sector",1)))
	pending_sector = bool(cfg.get_value("run","pending_sector",false))
	sector_ready = bool(cfg.get_value("run","sector_ready",false)) and not pending_sector
	profile = clampi(int(cfg.get_value("run","profile",1)),0,3)
	active_seed = int(cfg.get_value("run","seed",1701))
	seed_value = str(active_seed)
	_reset_tools()
	var raw: Variant = cfg.get_value("run","data",{})
	if raw is Dictionary and not raw.is_empty():
		var resumed: Dictionary = Store.restore(raw)
		if resumed.is_empty():
			save_failed = true
		else:
			board = resumed["board"]
			pending_sector = false
			sector_ready = false
			profile = resumed["profile"]
			active_seed = resumed["seed"]
			seed_value = str(active_seed)
			first_cell = resumed["first"]
			certificate = resumed["certificate"]
			last_hits = board.hits
			message_key = "CORE_ACTIVE"
			hints_left = clampi(int(cfg.get_value("run","hints",Tools.HINT_LIMITS[profile])),0,Tools.HINT_LIMITS[profile])
			rewinds_left = clampi(int(cfg.get_value("run","rewinds",Tools.REWIND_LIMITS[profile])),0,Tools.REWIND_LIMITS[profile])
			var previous: Variant = cfg.get_value("run","rewind_data",{})
			if previous is Dictionary and rewinds_left>0 and not previous.is_empty():
				var checked: Dictionary = Store.restore(previous)
				if not checked.is_empty() and checked["profile"]==profile and checked["seed"]==active_seed and checked["first"]==first_cell:
					var prior: Board = checked["board"]
					if prior._mask==board._mask: rewind_data = previous.duplicate(true)
func _save_session() -> void:
	if DisplayServer.get_name() == "headless": return
	cfg.set_value("settings","uk",is_uk)
	cfg.set_value("settings","crt",amount)
	cfg.set_value("settings","glass",glass)
	if cfg.has_section_key("settings","curve"): cfg.erase_section_key("settings","curve")
	cfg.set_value("settings","reduced",reduced)
	cfg.set_value("settings","flicker_v2",flicker)
	cfg.set_value("settings","glitches",glitches)
	cfg.set_value("settings","grade",global_amount)
	cfg.set_value("settings","sfx",audio.sfx_level)
	cfg.set_value("settings","hum",audio.hum_level)
	cfg.set_value("settings","sound",audio.enabled)
	cfg.set_value("stats","tutorial",tutorial_done)
	cfg.set_value("stats","sessions",sessions)
	cfg.set_value("stats","wins",wins)
	cfg.set_value("stats","losses",losses)
	cfg.set_value("run","sector",sector_number)
	cfg.set_value("run","pending_sector",pending_sector)
	cfg.set_value("run","sector_ready",sector_ready)
	cfg.set_value("run","profile",profile)
	cfg.set_value("run","seed",active_seed)
	cfg.set_value("run","data",Store.snapshot(board,profile,active_seed,first_cell))
	cfg.set_value("run","hints",hints_left)
	cfg.set_value("run","rewinds",rewinds_left)
	cfg.set_value("run","rewind_data",rewind_data if board!=null and not board.finished() else {})
	save_failed = Store.write_config(cfg) != OK
func begin_boot() -> void:
	boot_overlay = ColorRect.new()
	(boot_overlay as ColorRect).color = Color("081710")
	boot_overlay.size = size
	add_child(boot_overlay)
	_label("SAPERROR // BIOS",Rect2(110,110,1206,100),boot_overlay,64)
	boot_log = _label("",Rect2(110,270,1206,350),boot_overlay,36)
	var track := ColorRect.new()
	track.color = Color("193b24")
	_place(track,Rect2(110,680,1206,18),boot_overlay)
	boot_meter = ColorRect.new()
	boot_meter.color = GREEN
	_place(boot_meter,Rect2(0,0,0,18),track)
	boot_percent = _label("00%",Rect2(110,715,1206,64),boot_overlay,38)
	_label(tr("VIS_SKIP_BOOT"),Rect2(110,805,1206,60),boot_overlay,28,DIM)
	update_boot(0.0)
func update_boot(progress: float) -> void:
	if not is_instance_valid(boot_overlay): return
	var lines: String = "> "+tr("VIS_BOOT_CRT")
	if progress >= 0.25: lines += "\n> "+tr("VIS_BOOT_CORE")
	if progress >= 0.55: lines += "\n> "+tr("VIS_BOOT_AUDIO")
	if progress >= 0.80: lines += "\n> "+tr("VIS_BOOT_READY")
	boot_log.text = lines
	boot_meter.size.x = 1206.0*progress
	boot_percent.text = "%02d%%" % roundi(progress*100.0)
func end_boot() -> void:
	if is_instance_valid(boot_overlay):
		remove_child(boot_overlay)
		boot_overlay.queue_free()
		boot_overlay = null
func _show_outcome(won: bool) -> void:
	if is_instance_valid(outcome_banner):
		outcome_banner.queue_free()
	var banner := Panel.new()
	outcome_banner = banner
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint: Color = GREEN if won else RED
	banner.add_theme_stylebox_override("panel",_style(Color("0b2115") if won else Color("341b17"),tint,3))
	_place(banner,Rect2(376,399,674,170),page)
	var headline := _label(tr("VIS_WIN_BANNER" if won else "VIS_LOSS_BANNER"),Rect2(12,16,650,76),banner,40,tint)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint := _label(tr("CORE_WIN" if won else "CORE_LOSS"),Rect2(12,94,650,60),banner,30,tint)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := banner.create_tween()
	tween.tween_interval(1.1)
	if not reduced: tween.tween_property(banner,"modulate:a",0.0,0.35)
	tween.tween_callback(banner.queue_free)
func _language() -> void:
	is_uk = not is_uk
	TranslationServer.set_locale("uk" if is_uk else "en")
	_save_session()
	_show(screen)
func _help() -> void:
	_label(tr("VIS_HELP_TEXT"),Rect2(124,215,1170,500),page,34)
	_button(tr("VIS_BACK"),Rect2(124,790,350,62),page,func(): _show("menu"))
func _settings() -> void:
	_label(tr("VIS_SETTINGS"),Rect2(124,212,1150,60),page,41)
	_button("EN" if is_uk else "UA",Rect2(124,305,300,62),page,_language)
	_button(tr("VIS_FULLSCREEN")+": "+_on_off(_fullscreen_active()),Rect2(444,305,720,62),page,func(): fullscreen_requested.emit(); _show("settings"))
	var crt_readout := _label(tr("VIS_CRT")+": "+str(roundi(amount*100))+"%",Rect2(124,382,1040,35),page,28)
	var crt_slider := HSlider.new()
	crt_slider.min_value = 0.0
	crt_slider.max_value = 1.0
	crt_slider.step = 0.05
	crt_slider.value = amount
	_place(crt_slider,Rect2(124,421,1040,28),page)
	crt_slider.value_changed.connect(func(v: float):
		amount = v
		crt_readout.text = tr("VIS_CRT")+": "+str(roundi(v*100))+"%"
		_apply())
	_button(tr("VIS_GLASS")+": "+_on_off(glass),Rect2(124,471,510,62),page,func(): glass = not glass; _apply(); _show("settings"))
	_button(tr("VIS_GLITCHES")+": "+_on_off(glitches),Rect2(654,471,510,62),page,func(): glitches = not glitches; _apply(); _show("settings"))
	_button(tr("VIS_MOTION")+": "+_on_off(reduced),Rect2(124,553,1040,62),page,func(): reduced = not reduced; _apply(); _show("settings"))
	_button(tr("VIS_FLICKER")+": "+_on_off(flicker),Rect2(124,635,1040,62),page,func(): flicker = not flicker; _apply(); _show("settings"))
	_button(tr("VIS_GRADE")+": "+_on_off(global_amount>0.0),Rect2(124,717,1040,62),page,func(): global_amount = 0.25 if global_amount == 0.0 else 0.0; _apply(); _show("settings"))
	_button(tr("VIS_AUDIO"),Rect2(510,803,654,57),page,func(): _show("audio"))
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("menu"))
func _audio_settings() -> void:
	_label(tr("VIS_AUDIO"),Rect2(124,212,1150,60),page,41)
	_button(tr("VIS_SOUND")+": "+_on_off(audio.enabled),Rect2(124,300,1040,70),page,func(): audio.set_levels(audio.sfx_level,audio.hum_level,not audio.enabled); _save_session(); _show("audio"))
	_audio_slider(tr("VIS_SFX"),audio.sfx_level,410,true)
	_audio_slider(tr("VIS_HUM"),audio.hum_level,570,false)
	_button(tr("VIS_AUDIO_TEST"),Rect2(124,718,640,60),page,func(): audio.play_event("reveal"))
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("settings"))
func _audio_slider(caption: String, value: float, y: float, sfx: bool) -> void:
	var readout := _label(caption+": "+str(roundi(value*100))+"%",Rect2(124,y,1040,55),page,32)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	_place(slider,Rect2(124,y+65,1040,46),page)
	slider.value_changed.connect(func(v: float):
		readout.text = caption+": "+str(roundi(v*100))+"%"
		if sfx: audio.set_levels(v,audio.hum_level,audio.enabled)
		else: audio.set_levels(audio.sfx_level,v,audio.enabled)
		_save_session())
func _fullscreen_active() -> bool:
	if DisplayServer.get_name() == "headless": return int(ProjectSettings.get_setting("display/window/size/mode",0)) == 3
	var mode: int = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
func _on_off(value: bool) -> String:
	return tr("VIS_ON" if value else "VIS_OFF")
func _apply() -> void:
	effects_changed.emit(amount,glass,reduced,flicker,global_amount,glitches)
	_save_session()
func _game() -> void:
	var left := _panel(Rect2(80,180,284,608))
	var right := _panel(Rect2(1062,180,284,608))
	_label(tr("VIS_SECTOR")+" %02d" % sector_number,Rect2(16,17,252,50),left,32)
	_label(tr("VIS_DIFFICULTY")+"\n"+tr("VIS_PROFILE_"+Profiles.IDS[profile].to_upper()),Rect2(16,85,252,84),left,30)
	integrity = _label("",Rect2(16,189,252,105),left,33)
	recovered = _label("",Rect2(16,315,252,93),left,31)
	var track := ColorRect.new()
	track.color = Color("193b24")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(track,Rect2(16,421,252,10),left)
	progress_fill = ColorRect.new()
	progress_fill.color = GREEN
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(progress_fill,Rect2(0,0,0,10),track)
	flag_count = _label("",Rect2(16,475,252,99),left,31)
	_label(tr("VIS_RULE"),Rect2(16,17,252,44),right,30,DIM)
	rule_button = _button("CLASSIC",Rect2(16,64,252,56),right,_cycle_rule,28)
	_label(tr("VIS_RULE_HOVER"),Rect2(16,132,252,82),right,24,DIM)
	hint_button = _button("",Rect2(16,232,252,62),right,_request_hint,25)
	rewind_button = _button("",Rect2(16,310,252,62),right,_rewind,25)
	_label(tr("VIS_CONTROL_SHORT"),Rect2(16,390,252,198),right,24)
	grid = GridContainer.new()
	var w: int = Profiles.SIZES[profile] if board == null else board.width
	var h: int = Profiles.SIZES[profile] if board == null else board.height
	grid.columns = w
	grid.add_theme_constant_override("h_separation",Geometry.GAME_CELL_GAP)
	grid.add_theme_constant_override("v_separation",Geometry.GAME_CELL_GAP)
	var gap: float = float(Geometry.GAME_CELL_GAP)
	var cell: Vector2 = Geometry.grid_metrics(Geometry.GAME_GRID_AREA,w,h,gap)
	var extent := Vector2(w,h)*cell+Vector2(w-1,h-1)*gap
	_place(grid,Rect2(Geometry.GAME_GRID_CENTER-extent*0.5,extent),page)
	last_states.clear()
	for i in range(w*h):
		var btn := Button.new()
		btn.custom_minimum_size = cell
		btn.add_theme_font_size_override("font_size",maxi(14,int(cell.x*0.68)))
		for style_name in ["normal","hover","pressed","disabled","focus"]:
			var style: StyleBoxFlat = _style(Color("183b27"),DIM,2)
			style.content_margin_left = 2
			style.content_margin_right = 2
			style.content_margin_top = 2
			style.content_margin_bottom = 2
			btn.add_theme_stylebox_override(style_name,style)
		btn.pressed.connect(_reveal.bind(i))
		btn.gui_input.connect(_cell_input.bind(i))
		grid.add_child(btn)
		buttons.append(btn)
		var mark := Panel.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(mark)
		mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mark.hide()
		marks.append(mark)
		btn.mouse_entered.connect(_inspect_cell.bind(i))
		btn.mouse_exited.connect(_leave_cell.bind(i))
		btn.focus_entered.connect(_inspect_cell.bind(i))
		btn.focus_exited.connect(_leave_cell.bind(i))
		last_states.append(-1)
	status = _label("",Rect2(86,794,1250,46),page,31)
	_label(tr("CORE_SEED"),Rect2(86,850,100,54),page,28)
	seed_input = LineEdit.new()
	seed_input.text = str(active_seed) if board != null else seed_value
	seed_input.editable = board == null
	_place(seed_input,Rect2(184,844,230,60),page)
	next_button = _button(tr("CORE_NEW"),Rect2(430,844,330,60),page,func():
		if pending_sector: _advance_sector()
		else: _show("profiles"),28)
	_button("EN" if is_uk else "UA",Rect2(774,844,126,60),page,_language,28)
	_button(tr("VIS_BACK"),Rect2(914,844,422,60),page,func(): _show("menu"),28)
	_refresh()
func _reset() -> void:
	if protocol_active: return
	pending_sector = false
	sector_ready = true
	_reset_tools()
	if is_instance_valid(outcome_banner): outcome_banner.queue_free()
	board = null
	certificate.clear()
	last_hits = 0
	message_key = "CORE_READY"
	first_cell = -1
	if is_instance_valid(seed_input): seed_input.editable = true
	_save_session()
	_refresh()
func _reveal(i: int) -> void:
	if protocol_active or pending_sector: return
	if board == null:
		if not seed_input.text.is_valid_int():
			message_key = "CORE_SEED_BAD"
			audio.play_event("invalid")
			_refresh()
			return
		var generated: Dictionary = Profiles.generate(profile,seed_input.text.to_int(),i)
		if generated.is_empty():
			message_key = "CORE_FAIL"
			audio.play_event("invalid")
			_refresh()
			return
		certificate = generated["certificate"]
		active_seed = seed_input.text.to_int()
		first_cell = i
		seed_input.editable = false
		board = Board.new(Profiles.SIZES[profile],Profiles.SIZES[profile],generated["mask"],Profiles.HP[profile])
		sessions += 1
		sector_ready = false
	if board.finished() or board.cells[i] != Board.Cell.CLOSED: return
	var saved: Dictionary = _before_move()
	var before: int = board.opened
	board.reveal(i)
	_remember_move(saved)
	_after_action("flood" if board.opened-before > 1 else ("reveal" if board.opened > before else ""))
func _cell_input(event: InputEvent, i: int) -> void:
	if protocol_active or board == null or board.finished(): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_flag_action(i)
			buttons[i].accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_chord_action(i)
			buttons[i].accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and board.cells[i] == Board.Cell.OPEN:
			_chord_action(i)
			buttons[i].accept_event()
		elif event.keycode == KEY_F:
			_flag_action(i)
			buttons[i].accept_event()
func _flag_action(i: int) -> void:
	if protocol_active or board == null or board.finished(): return
	var saved: Dictionary = _before_move()
	var previous: int = board.cells[i]
	board.flag(i)
	if previous != board.cells[i]:
		_remember_move(saved)
		_after_action("flag" if board.cells[i] == Board.Cell.FLAG else "unflag")
func _chord_action(i: int) -> void:
	if protocol_active or board == null or board.finished(): return
	var saved: Dictionary = _before_move()
	var before: int = board.opened
	var hits: int = board.hits
	board.chord(i)
	if board.opened != before or board.hits != hits:
		_remember_move(saved)
		_after_action("flood" if board.opened-before > 1 else "reveal")
func _after_action(sound: String = "") -> void:
	hint_cell = -1
	hint_sources.clear()
	if board.finished(): rewind_data.clear()
	message_key = "CORE_ACTIVE"
	if board.hits > last_hits:
		message_key = "CORE_HIT"
		fault_triggered.emit()
		sound = "fault"
	last_hits = board.hits
	if board.won():
		message_key = "CORE_WIN"
		sound = "win"
	elif board.hp <= 0:
		message_key = "CORE_LOSS"
		sound = "loss"
	if not sound.is_empty(): audio.play_event(sound)
	_refresh()
	if board.finished() and not pending_sector:
		sector_ready = false
		if board.won():
			wins += 1
			pending_sector = true
		else: losses += 1
		outcome_triggered.emit(board.won())
		if not protocol_active: _show_outcome(board.won())
		_refresh()
	_save_session()
func _refresh() -> void:
	if is_instance_valid(next_button): next_button.text = tr("VIS_NEXT_SECTOR" if pending_sector else "CORE_NEW")
	var max_hp: int = Profiles.HP[profile]
	var hp: int = max_hp if board == null else board.hp
	integrity.text = tr("CORE_HP")+"\n%d / %d" % [hp,max_hp]
	integrity.add_theme_color_override("font_color",RED if hp < 2 else (AMBER if hp == 2 else GREEN))
	var opened: int = 0 if board == null else board.opened
	var total: int = Profiles.SIZES[profile]*Profiles.SIZES[profile]-Profiles.MINES[profile] if board == null else board.width * board.height - board.mine_total
	recovered.text = tr("CORE_OPEN")+"\n%d / %d" % [opened,total]
	progress_fill.size.x = 252.0 * float(opened) / float(maxi(total,1))
	var flags: int = 0
	status.text = "> " + tr(message_key)
	if hint_cell >= 0: status.text += "  #%d" % (hint_cell+1)
	status.add_theme_color_override("font_color",RED if message_key == "CORE_LOSS" else (AMBER if message_key in ["CORE_HIT","CORE_FAIL","CORE_SEED_BAD"] else GREEN))
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var state: int = Board.Cell.CLOSED if board == null else board.cells[i]
		var color: Color = Color("7fa58a")
		var fill: Color = Color("183b27")
		var edge: Color = Color("5c936c")
		b.text = "·"
		b.disabled = protocol_active or (board != null and board.finished())
		var desc: String = tr("CORE_CLOSED")
		if state == Board.Cell.OPEN:
			var clue: int = board.clue(i,board.rule)
			b.text = str(clue)
			color = Color("668b71") if clue == 0 else (GREEN if clue <= 2 else AMBER)
			fill = Color("081a11")
			edge = Color("2c5238")
			desc = b.text
		elif state == Board.Cell.FLAG:
			b.text = "⚑"
			color = AMBER
			fill = Color("352c17")
			edge = Color("987743")
			flags += 1
			desc = tr("CORE_FLAG")
		elif state == Board.Cell.NEUTRALIZED:
			b.text = "×"
			color = RED
			fill = Color("491e19")
			edge = Color("b15a50")
			desc = tr("CORE_NEUTRAL")
		b.add_theme_stylebox_override("normal",_style(fill,edge,2))
		b.add_theme_stylebox_override("disabled",_style(fill,edge,2))
		b.add_theme_stylebox_override("hover",_style(fill.lightened(0.13),color,2))
		b.add_theme_stylebox_override("pressed",_style(fill.lightened(0.25),color,3))
		if last_states[i] >= 0 and last_states[i] != state and not reduced:
			b.self_modulate = Color(1.4,1.4,1.4,1.0)
			b.create_tween().tween_property(b,"self_modulate",Color.WHITE,0.18)
		last_states[i] = state
		for key in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]:
			b.add_theme_color_override(key,color)
		b.tooltip_text = "%s %d: %s" % [tr("CORE_CELL"),i+1,desc]
	flag_count.text = tr("VIS_FLAGS")+"\n%d / %d" % [flags,Profiles.MINES[profile] if board == null else board.mine_total]
	_refresh_tools()

# Hidden input is intercepted before forwarding normal UI key events.
func protocol_input(event: InputEventKey) -> bool:
	if protocol_active: return true
	if screen != "game" or board == null or board.finished() or pending_sector:
		protocol.reset_input()
		return false
	if protocol.feed(event):
		_begin_protocol()
		return true
	return false
func _begin_protocol() -> void:
	if protocol_active or screen != "game" or not protocol.prepare(board): return
	protocol_active = true
	hint_cell = -1
	hint_sources.clear()
	protocol_elapsed = 0.0
	protocol_finished = false
	protocol_finish_elapsed = 0.0
	protocol_scan = 0.0
	protocol_panel = Panel.new()
	protocol_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	protocol_panel.add_theme_stylebox_override("panel",_style(Color("061b0f"),GREEN,3))
	_place(protocol_panel,Rect2(80,180,284,608),page)
	_label("PROTOCOL K-30",Rect2(14,12,256,54),protocol_panel,26,GREEN)
	protocol_log = _label("",Rect2(14,72,256,520),protocol_panel,23,GREEN)
	audio.play_event("k30")
	protocol_triggered.emit()
	_refresh()
	_protocol_lines(1)
func _protocol_lines(count: int) -> void:
	if not is_instance_valid(protocol_log): return
	var lines := PackedStringArray()
	for i in range(clampi(count,0,5)):
		lines.append("> "+tr("K30_"+str(i)))
	protocol_log.text = "\n\n".join(lines)
func _process(delta: float) -> void:
	if not protocol_active: return
	if protocol_finished:
		protocol_finish_elapsed += delta
		if protocol_finish_elapsed >= (0.6 if reduced else 1.35):
			protocol_active = false
			protocol_scan = -1.0
			protocol.reset_input()
			_advance_sector()
		return
	protocol_elapsed += delta
	var intro: float = 0.35 if reduced else 1.0
	if protocol_elapsed < intro:
		_protocol_lines(clampi(int(protocol_elapsed/intro*4.0)+1,1,4))
		return
	_protocol_lines(4)
	var duration: float = 0.65 if reduced else 1.85
	var target: int = mini(protocol.queue.size(),ceili(clampf((protocol_elapsed-intro)/duration,0.0,1.0)*protocol.queue.size()))
	if target > protocol.cursor:
		protocol.advance(board,target-protocol.cursor)
		protocol_scan = protocol.progress()
		_refresh()
	if board.won() and protocol.done():
		protocol_finished = true
		protocol_scan = -1.0
		_protocol_lines(5)
		_after_action()

func _reset_tools() -> void:
	hints_left = Tools.HINT_LIMITS[profile]
	rewinds_left = Tools.REWIND_LIMITS[profile]
	rewind_data.clear()
	hint_cell = -1
	hint_sources.clear()
func _before_move() -> Dictionary:
	if rewinds_left<=0 or board==null or first_cell<0 or first_cell>=board.cells.size(): return {}
	if board.cells[first_cell]!=Board.Cell.OPEN: return {}
	return Store.snapshot(board,profile,active_seed,first_cell)
func _remember_move(previous: Dictionary) -> void:
	if rewinds_left>0 and not previous.is_empty() and not board.finished(): rewind_data = previous
func _rewind() -> void:
	if protocol_active or board==null or board.finished() or rewinds_left<=0 or rewind_data.is_empty(): return
	var restored: Dictionary = Store.restore(rewind_data)
	if restored.is_empty(): return
	board = restored["board"]
	last_hits = board.hits
	rewinds_left -= 1
	rewind_data.clear()
	hint_cell = -1
	hint_sources.clear()
	message_key = "VIS_REWOUND"
	audio.play_event("boot")
	_refresh()
	_save_session()
func _request_hint() -> void:
	if protocol_active or board==null or board.finished() or hints_left<=0 or hint_cell>=0: return
	var available: Array[int] = [board.rule]
	var result: Dictionary = Tools.safe_hint(board.observation(available))
	if result.is_empty():
		message_key = "VIS_NO_PROOF"
	else:
		hints_left -= 1
		hint_cell = result["cell"]
		hint_sources.clear()
		for item in result["proof"]["premises"]:
			var source: int = item["source"]
			if source>=0 and not hint_sources.has(source): hint_sources.append(source)
		message_key = "VIS_PROVEN_SAFE"
	audio.play_event("key")
	_refresh()
	_save_session()
func _cycle_rule() -> void:
	if protocol_active or board==null or board.finished(): return
	board.rule = (board.rule+1)%Tools.NAMES.size()
	hint_cell = -1
	hint_sources.clear()
	message_key = "VIS_RULE_CHANGED"
	_refresh()
	_save_session()
func _inspect_cell(i: int) -> void:
	hover_cell = i
	_refresh_marks()
func _leave_cell(i: int) -> void:
	if hover_cell==i:
		hover_cell = -1
		_refresh_marks()
func _refresh_tools() -> void:
	var active: bool = board!=null and not board.finished() and not protocol_active
	if is_instance_valid(rule_button):
		rule_button.text = Tools.NAMES[board.rule] if board!=null else "CLASSIC"
		rule_button.disabled = not active
	if is_instance_valid(hint_button):
		hint_button.text = tr("VIS_HINT")+" [%d]" % hints_left
		hint_button.disabled = not active or hints_left<=0 or hint_cell>=0
	if is_instance_valid(rewind_button):
		rewind_button.text = tr("VIS_REWIND")+" [%d]" % rewinds_left
		rewind_button.disabled = not active or rewinds_left<=0 or rewind_data.is_empty()
	_refresh_marks()
func _refresh_marks() -> void:
	var neighbors: Array[int] = []
	if board!=null and hover_cell>=0 and hover_cell<board.cells.size() and board.cells[hover_cell]==Board.Cell.OPEN and not protocol_active:
		neighbors = Rules.neighbors(board.width,board.height,hover_cell,board.rule)
	for i in range(marks.size()):
		if not is_instance_valid(marks[i]): continue
		var target: bool = i==hint_cell
		var premise: bool = hint_sources.has(i)
		var adjacent: bool = neighbors.has(i)
		marks[i].visible = not protocol_active and (target or premise or adjacent)
		if marks[i].visible:
			marks[i].add_theme_stylebox_override("panel",_style(Color(0,0,0,0),GREEN if target else (AMBER if premise else Color("81b6a6")),5 if target else 3))
