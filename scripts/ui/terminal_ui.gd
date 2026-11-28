extends Control
const Board = preload("res://scripts/board/state.gd")
const Generator = preload("res://scripts/board/generator.gd")
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
const TerminalAudio = preload("res://scripts/audio/terminal_audio.gd")
const Atmosphere = preload("res://scripts/audio/atmosphere.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Tutorial = preload("res://scripts/ui/tutorial.gd")
const Protocol = preload("res://scripts/ui/protocol_k30.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Economy = preload("res://scripts/run/economy.gd")
const Phantom = preload("res://scripts/board/phantom.gd")
var phantom := Phantom.new()
const Parasite = preload("res://scripts/board/parasite.gd")
const Synergy=preload("res://scripts/board/anomaly_synergy.gd")
var anomaly_plan: int=Synergy.LEGACY
var journal_index: int=0
const ChallengeUI = preload("res://scripts/ui/anomaly_challenge_ui.gd")
const BossEmblem = preload("res://scripts/ui/boss_emblem.gd")
const ActPlate = preload("res://scripts/ui/act_plate.gd")
const EndingPlate = preload("res://scripts/ui/ending_plate.gd")
const Challenge = preload("res://scripts/board/anomaly_challenge.gd")
const Campaign = preload("res://scripts/run/campaign.gd")
const Collection = preload("res://scripts/run/collection.gd")
var collection := Collection.new()
var archive_preview: String = ""
var campaign := Campaign.new()
var campaign_selected: bool = false
var finite_selected: bool = false
var finite_run: bool = false
const Classic = preload("res://scripts/board/classic_game.gd")
const ClassicUI = preload("res://scripts/ui/classic_ui.gd")
var classic := Classic.new()
var act_checkpoint: Dictionary = {}
var campaign_failed: bool = false
var ending_gallery: Array[String] = []
var gallery_preview: String = ""
var challenge_kind: String = "LOOP"
var parasite := Parasite.new()
var portal_button: Button
var journal_button: Button
var cleanse_button: Button
const Rules = preload("res://scripts/board/rules.gd")
signal effects_changed(amount: float, glass: bool, reduced: bool, flicker: bool, global_amount: float, glitches: bool)
signal protocol_triggered
signal fault_triggered
signal fullscreen_requested
signal shutdown_requested
signal warning_accepted
signal outcome_triggered(won: bool)
signal immersion_triggered(id: String)
const Immersion=preload("res://scripts/ui/immersion.gd")
var immersion_cooldown: float=0.0
const Access=preload("res://scripts/ui/accessibility.gd")
var high_contrast: bool=false
var large_symbols: bool=false
var clear_display: bool=false
var text_scale: float=1.0
var requested_profile: int=1
var requested_campaign: bool=false
var requested_finite: bool=false
var lamp_animation: bool=true
var require_content_warning: bool=false
var warning_acknowledged: bool=false
var warning_pending: bool=false
var warning_sound: bool=true
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
var economy := Economy.new()
var run_hp: int = 3
var sector_start_hp: int = 3
var protected_hits: int = 0
var protected_this_move: int = 0
var shield_button: Button
var analyzer_button: Button
var third_button: Button
var inspect_mode: String = ""
var inspect_result: String = ""
var inspect_marks: Array[int] = []
var credit_label: Label
var shop_notice: String = ""
var last_reward: int = 0
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
var save_recovered: bool = false
var cfg := ConfigFile.new()
# Explicit isolated path for integration QA; production defaults to the existing save.
var session_path: String=Store.PATH
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
const StyleBank = preload("res://scripts/ui/style_bank.gd")
const PerformancePanel = preload("res://scripts/ui/performance_panel.gd")
var style_bank := StyleBank.new()
var last_visual_styles: Array=[]
var refresh_style_writes: int=0
var page: Control
var header_title: Label
var header_cursor: Label
var guide_label: Label
var narrative_label: Label
var narrative_tween: Tween
var guide_rule_title: Label
var guide_rule_help: Label
var header_emblem_slot: Control
var active_trial: ChallengeUI
var header_caret_elapsed: float=0.0
const HEADER_CARET_INTERVAL: float=0.5
var grid: GridContainer
var message_key: String = "CORE_READY"
var last_hits: int = 0
var is_uk: bool = false
var screen: String = "menu"
var amount: float = 0.45
var glass: bool = true
var reduced: bool = false
var flicker: bool = true
var glitches: bool = true
var global_amount: float = 0.0
func _ready() -> void:
	_load_session()
	warning_pending=require_content_warning and not warning_acknowledged
	warning_sound=bool(cfg.get_value("settings","sound",true))
	TranslationServer.set_locale("uk" if is_uk else "en")
	theme = _terminal_theme()
	audio = TerminalAudio.new()
	audio.set_levels(float(cfg.get_value("settings","sfx",0.55)),float(cfg.get_value("settings","hum",0.28)),warning_sound and not warning_pending)
	audio.set_music_level(float(cfg.get_value("settings","music",Atmosphere.DEFAULT_LEVEL)))
	audio.set_master(float(cfg.get_value("settings","master",1.0)))
	add_child(audio)
	var bg := ColorRect.new()
	bg.color = Color("081710")
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_show("warning" if warning_pending else "menu")
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
	t.default_font_size = roundi(29*text_scale)
	t.set_color("font_color","Label",Access.readable(GREEN,high_contrast))
	for state in ["normal","hover","pressed","disabled","focus"]:
		var fill := Color("0c2117")
		var border := DIM
		if state == "hover": fill = Color("244a30"); border = GREEN
		elif state == "pressed": fill = Color("396a43"); border = GREEN
		elif state == "disabled": fill = Color("09170f"); border = Color("284436")
		elif state == "focus": fill = Color(0,0,0,0); border = AMBER
		t.set_stylebox(state,"Button",Access.focus_style(high_contrast) if state=="focus" else _style(fill,Access.readable(border,high_contrast)))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		t.set_color(state,"Button",Access.readable(GREEN,high_contrast))
	t.set_color("font_disabled_color","Button",Access.readable(DIM,high_contrast))
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
	l.add_theme_font_size_override("font_size",Access.fit_font(theme.default_font,value,font_size,text_scale,rect.size,true))
	l.add_theme_color_override("font_color",Access.readable(color,high_contrast))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(l,rect,parent)
	return l
func _button(value: String, rect: Rect2, parent: Control, action: Callable, font_size: int = 27) -> Button:
	var b := Button.new()
	b.text = value
	b.add_theme_font_size_override("font_size",Access.fit_font(theme.default_font,value,font_size,text_scale,rect.size-Vector2(16,8),false))
	b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	b.tooltip_text=value
	b.pressed.connect(func():
		if protocol_active: return
		audio.play_event(TerminalAudio.button_event(screen))
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
	if protocol_active or (warning_pending and next!="warning"): return
	if next=="game" and campaign.active and campaign.compact and sector_ready and board==null and not pending_sector and not campaign.boss_pending(sector_number).is_empty():
		# Entry only; do not invent a win or reward before the encounter is solved.
		sector_ready=false
		pending_sector=true
		next="admin_intro" if sector_number==10 and not campaign.admin_intro_seen else "campaign_boss"
		_save_session()
	protocol.reset_input()
	if is_instance_valid(seed_input):
		seed_value = seed_input.text
		seed_input = null
	screen = next
	guide_label=null
	narrative_label=null
	if narrative_tween!=null and narrative_tween.is_valid(): narrative_tween.kill()
	narrative_tween=null
	guide_rule_title=null
	guide_rule_help=null
	active_trial=null
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.size = size
	add_child(page)
	buttons.clear()
	marks.clear()
	inspect_mode = ""
	inspect_result = ""
	inspect_marks.clear()
	hover_cell = -1
	_build_terminal_header()
	var version := _label("0.9.0-rc6",Rect2(850,82,486,48),page,24,DIM)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var line := ColorRect.new()
	line.color = DIM
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(line,Rect2(80,153,1266,2),page)
	if screen == "warning": _content_warning()
	elif screen == "game": _game()
	elif screen == "settings": _settings()
	elif screen == "help": _help()
	elif screen == "performance": _performance()
	elif screen == "audio": _audio_settings()
	elif screen == "accessibility": _accessibility()
	elif screen == "profiles": _profiles()
	elif screen == "confirm_run": _confirm_run()
	elif screen == "text_scale": _text_scale_page()
	elif screen == "modes": _modes()
	elif screen == "classic": _classic()
	elif screen == "free_complete": _free_complete()
	elif screen == "campaign_intro": _campaign_intro()
	elif screen == "campaign_boss": _campaign_boss()
	elif screen == "campaign_boundary": _campaign_boundary()
	elif screen == "campaign_route": _campaign_route()
	elif screen == "campaign_archive": _campaign_archive()
	elif screen == "campaign_recovery": _campaign_recovery()
	elif screen == "admin_intro": _admin_intro()
	elif screen == "ending_choice": _ending_choice()
	elif screen == "rewrite_trial": _rewrite_trial()
	elif screen == "ending_scene": _ending_scene(campaign.ending)
	elif screen == "gallery": _gallery()
	elif screen == "archives": _archives()
	elif screen == "archive_preview": _archive_preview()
	elif screen == "gallery_preview": _ending_scene(gallery_preview)
	elif screen == "tutorial": _tutorial()
	elif screen == "shop": _shop()
	elif screen == "challenges": _challenges()
	elif screen == "challenge": _challenge()
	else: _menu()
	_update_music()
	if screen!="game" or not Access.focus_tiles(buttons): Access.focus_first(page)
	if screen=="confirm_run":
		var cancel:=page.find_child("ConfirmCancel",true,false) as Button
		if is_instance_valid(cancel): cancel.grab_focus()
func _build_terminal_header() -> void:
	header_title=_label("SAPERROR",Rect2(88,52,550,92),page,72)
	header_title.name="TerminalHeaderTitle"
	header_title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var font_size: int=Access.fit_font(theme.default_font,"SAPERROR ▌",72,text_scale,Vector2(550,92),false)
	header_title.add_theme_font_size_override("font_size",font_size)
	var prefix_width: float=theme.default_font.get_string_size("SAPERROR ",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var title_width: float=theme.default_font.get_string_size("SAPERROR ▌",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	header_cursor=_label("▌",Rect2(88.0+prefix_width,52,maxf(30.0,title_width-prefix_width+4.0),92),page,72)
	header_cursor.name="TerminalHeaderCursor"
	header_cursor.add_theme_font_size_override("font_size",font_size)
	header_cursor.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_cursor.autowrap_mode=TextServer.AUTOWRAP_OFF
	header_emblem_slot=Control.new()
	header_emblem_slot.name="HeaderEmblemSlot"
	header_emblem_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# Center on the entire CRT raster, independent of title width or locale.
	var slot_x: float=(page.size.x-110.0)*0.5
	_place(header_emblem_slot,Rect2(slot_x,44,110,88),page)
	_update_header_caret(0.0)
func _update_header_caret(delta: float) -> void:
	header_caret_elapsed=fposmod(header_caret_elapsed+delta,HEADER_CARET_INTERVAL*2.0)
	if not is_instance_valid(header_cursor): return
	# Cursor feedback is independent of the CRT filter and reduced-motion flags.
	# Keep the first-launch safety notice static; offer a smooth pulse in gentle modes.
	if warning_pending:
		header_cursor.visible=true
		header_cursor.modulate.a=1.0
	elif reduced or clear_display:
		header_cursor.visible=true
		header_cursor.modulate.a=0.5+0.5*cos(TAU*header_caret_elapsed/(HEADER_CARET_INTERVAL*2.0))
	else:
		header_cursor.modulate.a=1.0
		header_cursor.visible=header_caret_elapsed<HEADER_CARET_INTERVAL
func _menu() -> void:
	_label(tr("VIS_BOOT"),Rect2(124,190,1170,80),page,36)
	_label(tr("VIS_TAGLINE"),Rect2(124,266,1170,62),page,28,DIM)
	var resume := _button(tr("VIS_CONTINUE"),Rect2(124,345,640,65),page,_continue_run)
	resume.disabled = not (campaign.active and campaign_failed) and not pending_sector and not sector_ready and (board == null or board.finished())
	_button(tr("VIS_NEW_GAME"),Rect2(124,423,640,65),page,func(): _show("modes"))
	_button(tr("VIS_TUTORIAL"),Rect2(124,501,640,65),page,func(): _show("tutorial"))
	_button(tr("VIS_SETTINGS"),Rect2(124,579,640,65),page,func(): _show("settings"))
	var power_button:=_button(tr("VIS_EXIT"),Rect2(124,657,640,65),page,_power_off)
	power_button.name="PowerOff"
	if sessions==0 and not _has_run():
		_label(tr("GUIDE_MENU_TITLE"),Rect2(820,345,500,64),page,32,AMBER)
		_label(tr("GUIDE_MENU_BODY"),Rect2(820,423,500,260),page,29)
	else:
		_label(tr("VIS_STATS")+"\n"+tr("VIS_RUNS")+" "+str(sessions)+"\n"+tr("VIS_WINS")+" "+str(wins)+"\n"+tr("VIS_LOSSES")+" "+str(losses),Rect2(820,345,500,285),page,32)
		_label(tr("VIS_LESSONS")+" %d / 9" % tutorial_done,Rect2(820,650,500,62),page,29,AMBER)
	if save_failed: _label(tr("VIS_SAVE_ERROR"),Rect2(820,714,500,80),page,27,RED)
	elif save_recovered: _label(tr("VIS_SAVE_RECOVERED"),Rect2(820,714,500,80),page,25,AMBER)
	_button(tr("CH_MENU"),Rect2(820,810,245,60),page,func(): _show("challenges"),21)
	_button(tr("COLLECTION_MENU"),Rect2(1075,810,245,60),page,func(): _show("gallery"),21)
func _profiles() -> void:
	_label(tr("VIS_DIFFICULTY"),Rect2(124,190,1170,70),page,42)
	if _has_run():
		_label(tr("VIS_REPLACE_RUN"),Rect2(124,265,1170,80),page,29,AMBER)
	for i in range(4):
		var label: String = tr("VIS_PROFILE_"+Profiles.IDS[i].to_upper())+"  //  %d×%d  ·  %d  ·  HP %d" % [Profiles.SIZES[i],Profiles.SIZES[i],Profiles.MINES[i],Profiles.HP[i]]
		if i==0 and campaign_selected: label=tr("GUIDE_RECOMMENDED")+"  //  6×6 · 4 "+tr("GUIDE_MINES")+" · 5 HP"
		var choice:=_button(label,Rect2(124,350+i*100,1170,74),page,_request_profile.bind(i,campaign_selected,finite_selected),32)
		choice.tooltip_text="%d CR | %s %d | %s %d" % [Economy.START_CREDITS[i],tr("VIS_STOCK"),Economy.START_STOCK[i],tr("VIS_HINT"),Tools.HINT_LIMITS[i]]
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("menu"))
func _start_profile(next_profile: int, story: bool = false, finite: bool = false) -> void:
	if protocol_active: return
	campaign=Campaign.new()
	campaign.active=story
	campaign.streamlined=story
	campaign.compact=story
	finite_run=finite and not story
	finite_selected=false
	campaign_selected=false
	act_checkpoint.clear()
	campaign_failed=false
	sector_number = 1
	pending_sector = false
	sector_ready = true
	profile = next_profile
	economy.reset(profile)
	economy.streamlined=campaign.active and campaign.streamlined
	economy.compact=campaign.active and campaign.compact
	run_hp = Profiles.HP[profile]
	sector_start_hp = run_hp
	protected_hits = 0
	last_reward = 0
	_reset_tools()
	board = null
	certificate.clear()
	first_cell = -1
	last_hits = 0
	message_key = "CORE_READY"
	if campaign.active: _capture_checkpoint()
	_save_session()
	_show("campaign_intro" if campaign.active else "game")
func _continue_run() -> void:
	if campaign.active and not campaign.ending.is_empty(): _show("ending_scene")
	elif campaign.active and campaign_failed: _show("campaign_recovery")
	elif pending_sector: _advance_sector()
	elif campaign.needs_intro(sector_number): _show("campaign_intro")
	else: _show("game")
func _advance_sector() -> void:
	if protocol_active or not pending_sector: return
	if finite_run and sector_number>=10:
		_show("free_complete")
		return
	if campaign.active:
		if campaign.archive_pending(sector_number):
			_show("campaign_route")
			return
		var boss: String=campaign.boss_pending(sector_number)
		if not boss.is_empty():
			_show("admin_intro" if boss=="ADMIN" and not campaign.admin_intro_seen else "campaign_boss")
			return
		if sector_number>=10:
			_show("ending_scene" if not campaign.ending.is_empty() else "ending_choice")
			return
	# Shared completion route for normal wins and the hidden protocol.
	pending_sector = false
	sector_ready = true
	sector_number += 1
	economy.begin_sector(sector_number)
	economy.replenish_campaign_stock()
	sector_start_hp = run_hp
	protected_hits = 0
	_reset_tools()
	active_seed = 0 if active_seed == 9223372036854775807 else active_seed+1
	seed_value = str(active_seed)
	if is_instance_valid(seed_input):
		seed_input.text = str(active_seed)
	seed_value = str(active_seed)
	board = null
	certificate.clear()
	first_cell = -1
	last_hits = 0
	message_key = "CORE_READY"
	if campaign.active and (profile==0 or sector_number in [4,7,10]): _capture_checkpoint()
	_save_session()
	_show("campaign_intro" if campaign.needs_intro(sector_number) else "game")
func _tutorial() -> void:
	tutorial = Tutorial.new()
	tutorial.size = Vector2(1266,710)
	tutorial.position = Vector2(80,180)
	tutorial.theme = theme
	tutorial.high_contrast=high_contrast
	tutorial.large_symbols=large_symbols
	tutorial.start_at = 0
	tutorial.text_scale = text_scale
	tutorial.completed.connect(func(step: int):
		tutorial_done = maxi(tutorial_done,step+1)
		_save_session())
	tutorial.back.connect(func(): _show("menu"))
	tutorial.ui_clicked.connect(func(): audio.play_event("menu_click"))
	tutorial.cell_clicked.connect(func(): audio.play_event("key"))
	page.add_child(tutorial)
func _reward_claimed_on_resume() -> bool:
	# Compact boss sectors use pending_sector for an unfinished encounter.
	return pending_sector and not (campaign.active and campaign.compact and not campaign.boss_pending(sector_number).is_empty())
func _load_session() -> void:
	if DisplayServer.get_name() != "headless" or session_path!=Store.PATH:
		var report: Dictionary=Store.load_report(session_path)
		cfg=report["config"]
		save_recovered=report["source"] in ["backup","staged"]
		save_failed=report["source"]=="invalid"
	is_uk = bool(cfg.get_value("settings","uk",false))
	high_contrast=bool(cfg.get_value("settings","contrast",false))
	large_symbols=bool(cfg.get_value("settings","large_symbols",false))
	clear_display=bool(cfg.get_value("settings","clear_display",false))
	text_scale=clampf(float(cfg.get_value("settings","text_scale",1.0)),0.75,1.5)
	lamp_animation=bool(cfg.get_value("settings","lamp_animation",true))
	warning_acknowledged=bool(cfg.get_value("settings","warning_acknowledged",false))
	amount = clampf(float(cfg.get_value("settings","crt",0.45)),0.0,1.0)
	glass = bool(cfg.get_value("settings","glass",true))
	reduced = bool(cfg.get_value("settings","reduced",false))
	flicker = bool(cfg.get_value("settings","flicker_v2",true))
	glitches = bool(cfg.get_value("settings","glitches",true))
	global_amount = clampf(float(cfg.get_value("settings","grade",0.0)),0.0,1.0)
	tutorial_done = clampi(int(cfg.get_value("stats","tutorial",0)),0,9)
	sessions = maxi(0,int(cfg.get_value("stats","sessions",0)))
	wins = maxi(0,int(cfg.get_value("stats","wins",0)))
	losses = maxi(0,int(cfg.get_value("stats","losses",0)))
	sector_number = maxi(1,int(cfg.get_value("run","sector",1)))
	campaign=Campaign.new()
	finite_run=bool(cfg.get_value("run","finite",false)) and sector_number<=10
	var raw_campaign: Variant = cfg.get_value("run","campaign",{})
	if raw_campaign is Dictionary and not raw_campaign.is_empty():
		if not campaign.restore(raw_campaign,sector_number): save_failed=true
	if campaign.active: finite_run=false
	var saved_checkpoint: Variant=cfg.get_value("run","act_checkpoint",{})
	act_checkpoint=saved_checkpoint.duplicate(true) if saved_checkpoint is Dictionary else {}
	ending_gallery.clear()
	var saved_gallery: Variant=cfg.get_value("stats","endings",[])
	if saved_gallery is Array:
		for id in saved_gallery:
			if id in Campaign.ENDINGS and not ending_gallery.has(id): ending_gallery.append(id)
	collection.restore(cfg,campaign.records)
	campaign_failed=campaign.active and bool(cfg.get_value("run","campaign_failed",false))
	last_reward=clampi(int(cfg.get_value("run","last_reward",0)),0,Economy.MAX_CREDITS)
	pending_sector = bool(cfg.get_value("run","pending_sector",false))
	sector_ready = bool(cfg.get_value("run","sector_ready",false)) and not pending_sector
	profile = clampi(int(cfg.get_value("run","profile",1)),0,3)
	active_seed = int(cfg.get_value("run","seed",1701))
	seed_value = str(active_seed)
	economy.reset(profile)
	economy.streamlined=campaign.active and campaign.streamlined
	economy.compact=campaign.active and campaign.compact
	run_hp = clampi(int(cfg.get_value("run","hp",Profiles.HP[profile])),1,Profiles.HP[profile])
	sector_start_hp = run_hp
	protected_hits = 0
	var econ: Variant = cfg.get_value("run","economy",{})
	var reward_claimed: bool=_reward_claimed_on_resume()
	if econ is Dictionary and not econ.is_empty(): economy.restore(econ,sector_number,reward_claimed)
	else:
		economy.begin_sector(sector_number)
		economy.rewarded_sector = sector_number if reward_claimed else sector_number-1
	_apply_hp_cap()
	_reset_tools()
	var raw: Variant = cfg.get_value("run","data",{})
	if raw is Dictionary and not raw.is_empty():
		var resumed: Dictionary = Store.restore(raw)
		if resumed.is_empty():
			save_failed = true
		else:
			board = resumed["board"]
			phantom = resumed["phantom"]
			parasite = resumed["parasite"]
			anomaly_plan=resumed["anomaly_plan"]
			pending_sector = false
			sector_ready = false
			profile = resumed["profile"]
			active_seed = resumed["seed"]
			seed_value = str(active_seed)
			first_cell = resumed["first"]
			certificate = resumed["certificate"]
			last_hits = board.hits
			run_hp = board.hp
			sector_start_hp = resumed["start_hp"]
			protected_hits = resumed["protected_hits"]
			message_key = "CORE_ACTIVE"
			hints_left = clampi(int(cfg.get_value("run","hints",_hint_limit())),0,_hint_limit())
			rewinds_left = clampi(int(cfg.get_value("run","rewinds",_rewind_limit())),0,_rewind_limit())
			var previous: Variant = cfg.get_value("run","rewind_data",{})
			if previous is Dictionary and rewinds_left>0 and not previous.is_empty():
				var checked: Dictionary = Store.restore(previous)
				if not checked.is_empty() and checked["profile"]==profile and checked["seed"]==active_seed and checked["first"]==first_cell:
					var prior: Board = checked["board"]
					if prior._mask==board._mask: rewind_data = previous.duplicate(true)
func _save_session() -> void:
	if warning_pending: return
	if DisplayServer.get_name() == "headless" and session_path==Store.PATH: return
	cfg.set_value("settings","uk",is_uk)
	cfg.set_value("settings","contrast",high_contrast)
	cfg.set_value("settings","large_symbols",large_symbols)
	cfg.set_value("settings","clear_display",clear_display)
	cfg.set_value("settings","text_scale",text_scale)
	cfg.set_value("settings","lamp_animation",lamp_animation)
	cfg.set_value("settings","warning_acknowledged",warning_acknowledged)
	cfg.set_value("settings","crt",amount)
	cfg.set_value("settings","glass",glass)
	if cfg.has_section_key("settings","curve"): cfg.erase_section_key("settings","curve")
	cfg.set_value("settings","reduced",reduced)
	cfg.set_value("settings","flicker_v2",flicker)
	cfg.set_value("settings","glitches",glitches)
	cfg.set_value("settings","grade",global_amount)
	cfg.set_value("settings","sfx",audio.sfx_level)
	cfg.set_value("settings","hum",audio.hum_level)
	cfg.set_value("settings","music",audio.music_level)
	cfg.set_value("settings","master",audio.master_level)
	cfg.set_value("settings","sound",audio.enabled)
	cfg.set_value("stats","tutorial",tutorial_done)
	cfg.set_value("stats","sessions",sessions)
	cfg.set_value("stats","wins",wins)
	cfg.set_value("stats","losses",losses)
	cfg.set_value("stats","endings",ending_gallery.duplicate())
	collection.write(cfg)
	cfg.set_value("run","sector",sector_number)
	cfg.set_value("run","campaign",campaign.snapshot())
	cfg.set_value("run","finite",finite_run)
	cfg.set_value("run","act_checkpoint",act_checkpoint)
	cfg.set_value("run","campaign_failed",campaign_failed)
	cfg.set_value("run","pending_sector",pending_sector)
	cfg.set_value("run","last_reward",last_reward)
	cfg.set_value("run","sector_ready",sector_ready)
	cfg.set_value("run","profile",profile)
	cfg.set_value("run","seed",active_seed)
	cfg.set_value("run","hp",run_hp)
	cfg.set_value("run","data",_snapshot_board())
	cfg.set_value("run","economy",economy.snapshot())
	cfg.set_value("run","hints",hints_left)
	cfg.set_value("run","rewinds",rewinds_left)
	cfg.set_value("run","rewind_data",rewind_data if board!=null and not board.finished() else {})
	save_failed = Store.write_config(cfg,session_path) != OK
	if not save_failed: save_recovered=false
func begin_boot() -> void:
	end_boot()
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
	if screen!="settings" or protocol_active: return
	is_uk = not is_uk
	cfg.set_value("settings","uk",is_uk)
	TranslationServer.set_locale("uk" if is_uk else "en")
	_save_session()
	_show(screen)
func _help() -> void:
	_label(tr("VIS_HELP_TEXT"),Rect2(124,215,1170,500),page,34)
	_button(tr("VIS_BACK"),Rect2(124,790,350,62),page,func(): _show("menu"))
	# No player-facing diagnostics entry; direct QA access is retained.
func _settings() -> void:
	_label(tr("VIS_SETTINGS"),Rect2(124,212,1150,60),page,41)
	var language_button := _button(tr("VIS_LANGUAGE")+": "+("Українська" if is_uk else "English"),Rect2(124,305,300,62),page,_language,22)
	language_button.name = "LanguageSetting"
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
	_button(tr("VIS_AUDIO"),Rect2(510,803,310,57),page,func(): _show("audio"))
	_button(tr("ACC_TITLE"),Rect2(840,803,324,57),page,func(): _show("accessibility"),22)
	_button(tr("VIS_BACK"),Rect2(124,803,350,57),page,func(): _show("menu"))
func _audio_settings() -> void:
	_label(tr("VIS_AUDIO"),Rect2(124,212,1150,60),page,41)
	_button(tr("VIS_SOUND")+": "+_on_off(audio.enabled),Rect2(124,300,1040,62),page,func(): audio.set_levels(audio.sfx_level,audio.hum_level,not audio.enabled); _save_session(); _show("audio"))
	_audio_slider(tr("VIS_MASTER"),audio.master_level,378,"master")
	_audio_slider(tr("VIS_SFX"),audio.sfx_level,465,"sfx")
	_audio_slider(tr("VIS_HUM"),audio.hum_level,552,"hum")
	_audio_slider(tr("VIS_MUSIC"),audio.music_level,639,"music")
	_button(tr("VIS_AUDIO_TEST"),Rect2(124,730,500,55),page,func(): audio.play_event("reveal"))
	var preview:=_button(tr("VIS_MUSIC_TEST"),Rect2(644,730,520,55),page,func():
		audio.select_music("" if audio.music.requested=="act_boot" else "act_boot"))
	preview.name="MusicPreview"
	_button(tr("VIS_BACK"),Rect2(124,810,350,57),page,func(): _show("settings"))
func _audio_slider(caption: String, value: float, y: float, channel: String) -> void:
	var readout := _label(caption+": "+str(roundi(value*100))+"%",Rect2(124,y,1040,42),page,28)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.name="AudioSlider_"+channel
	_place(slider,Rect2(124,y+45,1040,34),page)
	slider.value_changed.connect(func(v: float):
		readout.text = caption+": "+str(roundi(v*100))+"%"
		if channel=="sfx": audio.set_levels(v,audio.hum_level,audio.enabled)
		elif channel=="hum": audio.set_levels(audio.sfx_level,v,audio.enabled)
		elif channel=="master": audio.set_master(v)
		else: audio.set_music_level(v)
		_save_session())
func _fullscreen_active() -> bool:
	if DisplayServer.get_name() == "headless": return int(ProjectSettings.get_setting("display/window/size/mode",0)) == 3
	var mode: int = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
func _on_off(value: bool) -> String:
	return tr("VIS_ON" if value else "VIS_OFF")
func _apply() -> void:
	effects_changed.emit(0.0 if clear_display else amount,glass,reduced,flicker and not clear_display,0.0 if clear_display else global_amount,glitches and not clear_display)
	_save_session()
func _game() -> void:
	var left := _panel(Rect2(80,180,284,608))
	var right := _panel(Rect2(1062,180,284,608))
	_label(tr("VIS_SECTOR")+(" %02d/10" if _simple_campaign() else " %02d") % sector_number,Rect2(16,17,252,50),left,32)
	if campaign.active: _label("ACT %d // %s" % [campaign.act_index(sector_number)+1,Campaign.ACT_IDS[campaign.act_index(sector_number)]],Rect2(16,65,252,22),left,17,AMBER)
	if campaign.active:
		_label(tr("VIS_PROFILE_"+Profiles.IDS[profile].to_upper()),Rect2(16,92,252,32),left,21,DIM)
		narrative_label=_label("",Rect2(16,130,252,136),left,21,AMBER)
		narrative_label.name="LiveTransmission"
		narrative_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		integrity=_label("",Rect2(16,274,252,66),left,24)
		recovered=_label("",Rect2(16,344,252,68),left,24)
	else:
		_label(tr("VIS_DIFFICULTY")+"\n"+tr("VIS_PROFILE_"+Profiles.IDS[profile].to_upper()),Rect2(16,85,252,84),left,30)
		integrity=_label("",Rect2(16,189,252,105),left,33)
		recovered=_label("",Rect2(16,315,252,93),left,31)
	var track := ColorRect.new()
	track.color = Color("193b24")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(track,Rect2(16,421,252,10),left)
	progress_fill = ColorRect.new()
	progress_fill.color = GREEN
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(progress_fill,Rect2(0,0,0,10),track)
	flag_count = _label("",Rect2(16,440,252,64),left,24)
	credit_label = _label("",Rect2(16,504,252,35),left,24,AMBER)
	journal_button = _button(tr("VIS_JOURNAL"),Rect2(16,548,122,48),left,_open_journal,18)
	cleanse_button = _button(tr("VIS_CLEANSE"),Rect2(146,548,122,48),left,_cleanse,18)
	guide_rule_title=_label(tr("VIS_RULE"),Rect2(16,17,252,44),right,30,DIM)
	rule_button = _button("CLASSIC",Rect2(16,64,252,56),right,_cycle_rule,28)
	guide_rule_help=_label(tr("VIS_RULE_HOVER"),Rect2(16,132,252,42),right,18,DIM)
	portal_button = _button("PORTAL",Rect2(16,178,252,42),right,_toggle_portal,22)
	portal_button.hide()
	hint_button = _button("",Rect2(16,232,252,62),right,_request_hint,25)
	rewind_button = _button("",Rect2(16,310,252,62),right,_rewind,25)
	shield_button = _button("",Rect2(16,388,252,62),right,_arm_shield,24)
	analyzer_button = _button("",Rect2(16,466,252,56),right,_select_inspection.bind("analyzer"),22)
	third_button = _button("",Rect2(16,538,252,56),right,_select_inspection.bind("third"),22)
	if _guided_early():
		guide_label=_label("",Rect2(16,17,252,202),right,24,AMBER)
		guide_label.name="FieldGuide"
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
	last_visual_styles.clear()
	var grid_focus: StyleBoxFlat=Access.focus_style(high_contrast)
	for i in range(w*h):
		var btn := Button.new()
		btn.custom_minimum_size = cell
		btn.add_theme_font_size_override("font_size",maxi(14,int(cell.x*(0.78 if large_symbols else 0.68))))
		for style_name in ["normal","hover","pressed","disabled"]:
			btn.add_theme_stylebox_override(style_name,style_bank.get_style(Color("183b27"),DIM,2))
		btn.add_theme_stylebox_override("focus",grid_focus)
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
		last_visual_styles.append([])
	status = _label("",Rect2(86,794,1250,46),page,31)
	var seed_caption:=_label(tr("CORE_SEED"),Rect2(86,850,100,54),page,28)
	seed_caption.visible=not (_guided_early() or _simple_campaign())
	seed_input = LineEdit.new()
	seed_input.text = str(active_seed) if board != null else seed_value
	seed_input.editable = board == null
	_place(seed_input,Rect2(184,844,230,60),page)
	seed_input.visible=not (_guided_early() or _simple_campaign())
	next_button = _button(tr("CORE_NEW"),Rect2(430,844,470,60),page,func():
		if pending_sector:
			_advance_sector()
			if screen=="game" and _shop_available(): _show("shop")
		elif _shop_available(): _show("shop")
		elif campaign.active and campaign_failed: _show("campaign_recovery")
		else: _show("modes"),28)
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
	if not inspect_mode.is_empty():
		_inspect_target(i)
		return
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
		# Story checkpoint includes the chosen seed and purchases before opening.
		if campaign.active and profile==0: _capture_checkpoint()
		seed_input.editable = false
		sector_start_hp = clampi(run_hp,1,_max_hp())
		protected_hits = 0
		board = Board.new(Profiles.SIZES[profile],Profiles.SIZES[profile],generated["mask"],sector_start_hp)
		anomaly_plan=Synergy.campaign_plan(profile,sector_number) if _simple_campaign() else Synergy.plan(profile,sector_number)
		sessions += 1
		sector_ready = false
	if board.finished() or board.cells[i] != Board.Cell.CLOSED: return
	if i==board.blocked_cell:
		message_key = "VIS_PARASITE_BLOCKED"
		_refresh()
		return
	var saved: Dictionary = _before_move()
	var before: int = board.opened
	protected_this_move = 0
	_guarded_reveal(i)
	# Activate only after the certified initial reveal; the link is freely reversible.
	if before==0 and (anomaly_plan&Synergy.PORTAL)!=0 and not board.finished():
		board.configure_portal(0,board.cells.size()-1)
	economy.observe(board.opened-before,board.hits==last_hits,board.clue(i,board.rule) if board.cells[i]==Board.Cell.OPEN else 0)
	_remember_move(saved)
	_after_action("flood" if board.opened-before > 1 else ("reveal" if board.opened > before else ""))
func _cell_input(event: InputEvent, i: int) -> void:
	if protocol_active: return
	if Access.grid_key(event,buttons,i,grid.columns): return
	if board == null or board.finished(): return
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
		elif Access.physical(event) == KEY_F:
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
	protected_this_move = 0
	_guarded_chord(i)
	if board.opened != before or board.hits != hits:
		economy.observe(board.opened-before,board.hits==hits,board.clue(i,board.rule))
		_remember_move(saved)
		_after_action("flood" if board.opened-before > 1 else "reveal")
func _after_action(sound: String = "") -> void:
	var anomaly_event: String = ""
	var infection_event: String = ""
	if not protocol_active:
		var parasite_sector: bool=false
		var phantom_sector: bool=false
		if anomaly_plan==Synergy.LEGACY:
			# Existing active saves keep their original single-anomaly schedule.
			parasite_sector=sector_number>=4 and sector_number%2==0 and not phantom.triggered and not board.has_portal()
			phantom_sector=sector_number>=3 and not parasite_sector and parasite.cell<0 and not board.has_portal()
		else:
			parasite_sector=(anomaly_plan&Synergy.PARASITE)!=0
			phantom_sector=(anomaly_plan&Synergy.PHANTOM)!=0
		anomaly_event=phantom.advance(board,phantom_sector,economy.owned.has("SHIELDING") or (_simple_campaign() and economy.owned.has("STABILIZER")))
		infection_event=parasite.advance(board,parasite_sector,economy.owned.has("STABILIZER"))
	_clear_inspection()
	hint_cell = -1
	hint_sources.clear()
	if board.finished(): rewind_data.clear()
	message_key = "CORE_ACTIVE"
	if anomaly_event=="hidden": message_key = "VIS_PHANTOM_ALERT"
	elif anomaly_event=="shielded": message_key = "VIS_PHANTOM_SHIELDED"
	elif anomaly_event=="expired": message_key = "VIS_PHANTOM_CLEAR"
	if infection_event=="warning": message_key = "VIS_PARASITE_WARNING"
	elif infection_event=="blocked": message_key = "VIS_PARASITE_BLOCKED"
	elif infection_event=="escaped": message_key = "VIS_PARASITE_CLEAR"
	if board.hits > last_hits:
		message_key = "VIS_PROTECTED" if protected_this_move==board.hits-last_hits else "CORE_HIT"
		fault_triggered.emit()
		sound = "fault"
	last_hits = board.hits
	run_hp = board.hp
	protected_this_move = 0
	if board.won():
		message_key = "CORE_WIN"
		sound = "win"
	elif board.hp <= 0:
		message_key = "CORE_LOSS"
		sound = "loss"
	if not sound.is_empty(): audio.play_event(sound)
	if not board.finished() and infection_event in ["warning","blocked"]: _play_immersion("PARASITE",true)
	elif not board.finished() and anomaly_event=="hidden": _play_immersion("PHANTOM",true)
	_refresh()
	if board.finished() and not pending_sector:
		sector_ready = false
		if board.won():
			wins += 1
			last_reward = economy.reward(sector_number,board.opened,board.hits)
			pending_sector = true
		else:
			losses += 1
			if campaign.active: campaign_failed=true
		outcome_triggered.emit(board.won())
		if not protocol_active: _show_outcome(board.won())
		_refresh()
	_save_session()
func _refresh() -> void:
	if is_instance_valid(next_button):
		next_button.text = tr("CAM_RETRY") if campaign.active and campaign_failed else tr("CAM_ROUTE") if pending_sector and campaign.archive_pending(sector_number) else tr("CAM_BOSS") if pending_sector and not campaign.boss_pending(sector_number).is_empty() else tr("VIS_SHOP" if pending_sector or _shop_available() else "CORE_NEW")
	if is_instance_valid(credit_label): credit_label.text = "CR %d" % economy.credits
	var max_hp: int = _max_hp()
	var hp: int = run_hp if board == null else board.hp
	integrity.text = tr("CORE_HP")+"\n%d / %d" % [hp,max_hp]
	integrity.add_theme_color_override("font_color",Access.readable(RED if hp < 2 else (AMBER if hp == 2 else GREEN),high_contrast))
	var opened: int = 0 if board == null else board.opened
	var total: int = Profiles.SIZES[profile]*Profiles.SIZES[profile]-Profiles.MINES[profile] if board == null else board.width * board.height - board.mine_total
	recovered.text = tr("CORE_OPEN")+"\n%d / %d" % [opened,total]
	progress_fill.size.x = 252.0 * float(opened) / float(maxi(total,1))
	var flags: int = 0
	refresh_style_writes=0
	status.text = "> " + tr(message_key)
	if hint_cell >= 0: status.text += "  #%d" % (hint_cell+1)
	if not inspect_result.is_empty(): status.text = "> "+inspect_result
	elif phantom.active() and not protocol_active and board!=null and not board.finished():
		status.text += " // PHANTOM #%d [%d]" % [phantom.cell+1,phantom.until_action-phantom.actions]
	if inspect_result.is_empty() and parasite.active() and not protocol_active and board!=null and not board.finished():
		status.text += " // PARASITE #%d [%s]" % [parasite.cell+1,"LOCK" if parasite.blocked() else str(parasite.remaining())]
	if board!=null and board.has_portal() and not protocol_active and not board.finished() and inspect_result.is_empty():
		status.text += " // PORTAL %s [%d-%d]" % [_on_off(board.portal_enabled),board.portal_pair.x+1,board.portal_pair.y+1]
	if pending_sector and last_reward>0: status.text += "  +%d CR" % last_reward
	status.add_theme_font_size_override("font_size",Access.fit_font(theme.default_font,status.text,31,text_scale,Vector2(1250,46),false))
	status.tooltip_text=status.text
	status.add_theme_color_override("font_color",Access.readable(RED if message_key == "CORE_LOSS" else (AMBER if message_key in ["CORE_HIT","CORE_FAIL","CORE_SEED_BAD"] else GREEN),high_contrast))
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var state: int = Board.Cell.CLOSED if board == null else board.cells[i]
		var color: Color = Color("7fa58a")
		var fill: Color = Color("183b27")
		var edge: Color = Color("5c936c")
		var cell_text: String="·"
		var cell_disabled: bool=protocol_active or (board != null and board.finished())
		var desc: String = tr("CORE_CLOSED")
		if state == Board.Cell.OPEN:
			var clue: int = board.clue(i,board.rule)
			cell_text = str(clue)
			color = Color("668b71") if clue == 0 else (GREEN if clue <= 2 else AMBER)
			fill = Color("081a11")
			edge = Color("2c5238")
			desc = cell_text
			if not protocol_active and not board.finished() and phantom.hidden(i,board.rule):
				cell_text = "?"
				color = AMBER
				edge = AMBER
				desc = tr("VIS_PHANTOM_HIDDEN")
		elif state == Board.Cell.FLAG:
			cell_text = "⚑"
			color = AMBER
			fill = Color("352c17")
			edge = Color("987743")
			flags += 1
			desc = tr("CORE_FLAG")
		elif state == Board.Cell.NEUTRALIZED:
			cell_text = "×"
			color = RED
			fill = Color("491e19")
			edge = Color("b15a50")
			desc = tr("CORE_NEUTRAL")
		if board!=null and not protocol_active and not board.finished() and parasite.active() and i==parasite.cell:
			cell_text = "X" if parasite.blocked() else (("⚑" if state==Board.Cell.FLAG else "!")+str(parasite.remaining()))
			color = RED if parasite.blocked() else AMBER
			edge = color
			fill = Color("49221a") if parasite.blocked() else Color("382e15")
			desc = tr("VIS_PARASITE_BLOCKED" if parasite.blocked() else "VIS_PARASITE_WARNING")
			cell_disabled = parasite.blocked()
		if board!=null and board.has_portal() and i in [board.portal_pair.x,board.portal_pair.y] and not protocol_active:
			edge = Color("7ac5d0")
			desc += " / PORTAL #%d" % ((board.portal_pair.y if i==board.portal_pair.x else board.portal_pair.x)+1)
		var width: int=3 if board!=null and board.has_portal() and i in [board.portal_pair.x,board.portal_pair.y] else 2
		if high_contrast:
			color=Access.readable(color,true)
			edge=Access.readable(edge,true)
			fill=fill.darkened(0.32)
		var signature: Array=[fill,edge,color,width]
		if last_visual_styles[i]!=signature:
			b.add_theme_stylebox_override("normal",style_bank.get_style(fill,edge,width))
			b.add_theme_stylebox_override("disabled",style_bank.get_style(fill,edge,2))
			b.add_theme_stylebox_override("hover",style_bank.get_style(fill.lightened(0.13),color,2))
			b.add_theme_stylebox_override("pressed",style_bank.get_style(fill.lightened(0.25),color,3))
			for key in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]:
				b.add_theme_color_override(key,color)
			last_visual_styles[i]=signature
			refresh_style_writes+=1
		if b.text!=cell_text: b.text=cell_text
		if b.disabled!=cell_disabled: b.disabled=cell_disabled
		if last_states[i] >= 0 and last_states[i] != state and not reduced:
			b.self_modulate = Color(1.4,1.4,1.4,1.0)
			b.create_tween().tween_property(b,"self_modulate",Color.WHITE,0.18)
		last_states[i] = state
		var tooltip: String="%s %d: %s" % [tr("CORE_CELL"),i+1,desc]
		if b.tooltip_text!=tooltip: b.tooltip_text=tooltip
	flag_count.text = tr("VIS_FLAGS")+"\n%d / %d" % [flags,Profiles.MINES[profile] if board == null else board.mine_total]
	_refresh_tools()
	_refresh_field_guide()
	_refresh_simple_hud()
	_refresh_transmission()

# Hidden input is intercepted before forwarding normal UI key events.
func protocol_input(event: InputEventKey) -> bool:
	if protocol_active: return true
	if screen in ["challenge","campaign_boss","campaign_archive","rewrite_trial"] and is_instance_valid(active_trial):
		if not active_trial.can_protocol_complete():
			protocol.reset_input()
			return false
		if protocol.feed(event):
			audio.play_event("k30")
			active_trial.complete_with_protocol()
			return true
		return false
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
	_clear_inspection()
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
	immersion_cooldown=maxf(0.0,immersion_cooldown-delta)
	_update_header_caret(delta)
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
	phantom = Phantom.new()
	parasite = Parasite.new()
	anomaly_plan=Synergy.LEGACY
	journal_index=0
	hints_left = _hint_limit()
	rewinds_left = _rewind_limit()
	rewind_data.clear()
	hint_cell = -1
	hint_sources.clear()
func _before_move() -> Dictionary:
	if rewinds_left<=0 or board==null or first_cell<0 or first_cell>=board.cells.size(): return {}
	if board.cells[first_cell]!=Board.Cell.OPEN: return {}
	var state: Dictionary = _snapshot_board()
	if not state.is_empty(): state["economy_move"] = economy.move_state()
	return state
func _remember_move(previous: Dictionary) -> void:
	if rewinds_left>0 and not previous.is_empty() and not board.finished(): rewind_data = previous
func _rewind() -> void:
	if protocol_active or board==null or board.finished() or rewinds_left<=0 or rewind_data.is_empty(): return
	_clear_inspection()
	var restored: Dictionary = Store.restore(rewind_data)
	if restored.is_empty(): return
	board = restored["board"]
	phantom = restored["phantom"]
	parasite = restored["parasite"]
	anomaly_plan=restored["anomaly_plan"]
	run_hp = board.hp
	sector_start_hp = restored["start_hp"]
	protected_hits = restored["protected_hits"]
	if rewind_data.has("economy_move") and rewind_data["economy_move"] is Dictionary: economy.restore_move(rewind_data["economy_move"])
	last_hits = board.hits
	rewinds_left -= 1
	rewind_data.clear()
	hint_cell = -1
	hint_sources.clear()
	message_key = "VIS_REWOUND"
	audio.play_event("rewind")
	_refresh()
	_save_session()
func _request_hint() -> void:
	if protocol_active or board==null or board.finished() or (hints_left<=0 and economy.stock<=0) or hint_cell>=0: return
	_clear_inspection()
	if parasite.blocked():
		if hints_left>0: hints_left -= 1
		else: economy.stock -= 1
		parasite.cleanse(board)
		rewind_data.clear()
		message_key = "VIS_PARASITE_CLEAR"
		audio.play_event("cleanse")
		_refresh()
		_save_session()
		return
	if phantom.active():
		if hints_left>0: hints_left -= 1
		else: economy.stock -= 1
		phantom.clear_zone()
		rewind_data.clear()
		message_key = "VIS_PHANTOM_CLEAR"
		audio.play_event("cleanse")
		_refresh()
		_save_session()
		return
	var available: Array[int] = [board.rule]
	var result: Dictionary = Tools.safe_hint(board.observation(available))
	if result.is_empty():
		message_key = "VIS_NO_PROOF"
	else:
		if hints_left>0: hints_left -= 1
		else: economy.stock -= 1
		# A spent hint is never refunded by restoring an earlier move.
		rewind_data.clear()
		hint_cell = result["cell"]
		hint_sources.clear()
		for item in result["proof"]["premises"]:
			var source: int = item["source"]
			if source>=0 and not hint_sources.has(source): hint_sources.append(source)
		message_key = "VIS_PROVEN_SAFE"
	audio.play_event("scanner" if not result.is_empty() else "invalid")
	_refresh()
	_save_session()
func _cycle_rule() -> void:
	if protocol_active or board==null or board.finished(): return
	_clear_inspection()
	if _simple_campaign() and sector_number<4 and board.rule==Rules.Rule.CLASSIC: return
	board.rule = (board.rule+1)%(2 if _simple_campaign() else Tools.NAMES.size())
	hint_cell = -1
	hint_sources.clear()
	message_key = "VIS_RULE_CHANGED"
	audio.play_event("rule")
	_refresh()
	_save_session()
func _inspect_cell(i: int) -> void:
	hover_cell = i
	_refresh_marks()
func _leave_cell(i: int) -> void:
	if hover_cell==i:
		hover_cell = -1
		_refresh_marks()
func _transmission_key() -> String:
	if board!=null:
		if board.won(): return "NARR_CLEAR_%02d" % clampi(sector_number,1,10)
		if board.hp<=0: return "NARR_LOSS"
		if message_key=="CORE_HIT": return "NARR_HIT_FIRST" if board.hits==1 else "NARR_HIT_REPEAT"
		if message_key=="VIS_PHANTOM_ALERT": return "NARR_PHANTOM"
		if message_key in ["VIS_PARASITE_WARNING","VIS_PARASITE_BLOCKED"]: return "NARR_PARASITE"
	return "NARR_SECTOR_%02d" % clampi(sector_number,1,10)
func _animate_transmission(target: Label) -> Tween:
	target.visible_ratio=1.0
	if reduced or target.text.is_empty(): return null
	target.visible_ratio=0.0
	var animation:=target.create_tween()
	animation.tween_property(target,"visible_ratio",1.0,clampf(float(target.text.length())/52.0,0.25,2.4))
	return animation
func _play_immersion(id: String, force: bool=false) -> void:
	if warning_pending or not Immersion.IDS.has(id): return
	if immersion_cooldown>0.0 and not force: return
	immersion_cooldown=0.30
	audio.play_event(Immersion.sound(id))
	immersion_triggered.emit(id)
func _wire_trial_immersion(trial: ChallengeUI) -> void:
	trial.immersion_event.connect(func(id: String):
		if active_trial==trial: _play_immersion(id))
func _refresh_transmission() -> void:
	if not campaign.active or not is_instance_valid(narrative_label): return
	var value: String=tr(_transmission_key())
	if narrative_label.text==value: return
	var first_line: bool=narrative_label.text.is_empty()
	if narrative_tween!=null and narrative_tween.is_valid(): narrative_tween.kill()
	narrative_label.text=value
	narrative_label.tooltip_text=value
	narrative_label.add_theme_font_size_override("font_size",Access.fit_font(theme.default_font,value,21,text_scale,Vector2(252,136),true))
	narrative_label.add_theme_color_override("font_color",Access.readable(AMBER if value.begins_with("ECHO:") else GREEN,high_contrast))
	narrative_tween=_animate_transmission(narrative_label)
	if first_line and board==null and not pending_sector: _play_immersion("ECHO" if value.begins_with("ECHO:") else "VOICE_ADMIN")
func _simple_campaign() -> bool:
	return campaign.active and campaign.streamlined
func _guided_early() -> bool:
	return campaign.active and profile==0 and sector_number<=3
func _refresh_simple_hud() -> void:
	if not _simple_campaign(): return
	if not _guided_early():
		var rules_available: bool=sector_number>=4 or (board!=null and board.rule!=Rules.Rule.CLASSIC)
		guide_rule_title.visible=rules_available
		guide_rule_help.visible=rules_available
		rule_button.visible=rules_available
	hint_button.visible=true
	hint_button.text=tr("SIMPLE_HINT")+" [%d]" % (hints_left+economy.stock)
	rewind_button.visible=rewinds_left>0 and (not _guided_early() or sector_number>=2 or (board!=null and board.hits>0))
	rewind_button.text=tr("SIMPLE_UNDO")+" [%d]" % rewinds_left
	analyzer_button.visible=false
	shield_button.visible=economy.shield_stock>0 or economy.shield_armed
	third_button.visible=economy.owned.has("THIRD_EYE")
	journal_button.visible=phantom.active() or not _journal_entries().is_empty()
	cleanse_button.visible=phantom.active() or parasite.active()
	flag_count.visible=false
	if campaign.compact: recovered.tooltip_text=tr("BALANCE_MINES")+" "+(flag_count.text.split("\n")[-1])
	integrity.text=tr("SIMPLE_HEALTH")+"\n%d / %d" % [run_hp if board==null else board.hp,_max_hp()]
	recovered.text=tr("SIMPLE_PROGRESS")+"\n%d / %d" % [0 if board==null else board.opened,Profiles.SIZES[profile]*Profiles.SIZES[profile]-Profiles.MINES[profile] if board==null else board.cells.size()-board.mine_total]
	next_button.visible=pending_sector or campaign_failed or (not campaign.compact and board==null) or _shop_available()
	if pending_sector: next_button.text=tr("GUIDE_NEXT")
func _refresh_field_guide() -> void:
	if not _guided_early() or not is_instance_valid(guide_label): return
	var advanced_rule: bool=board!=null and board.rule!=Rules.Rule.CLASSIC
	guide_rule_title.visible=advanced_rule
	guide_rule_help.visible=advanced_rule
	rule_button.visible=advanced_rule
	guide_label.visible=not advanced_rule
	var key: String="GUIDE_FIRST"
	if pending_sector: key="GUIDE_WIN"
	elif board!=null:
		if board.hp<=0: key="GUIDE_LOSS"
		elif message_key=="CORE_HIT": key="GUIDE_HIT"
		elif hint_cell>=0: key="GUIDE_HINT"
		elif phantom.active(): key="GUIDE_PHANTOM"
		elif sector_number==1: key="GUIDE_NUMBERS"
		elif sector_number==2: key="GUIDE_ECHO"
		else: key="GUIDE_WATCHER"
	guide_label.text=tr(key)
	guide_label.add_theme_font_size_override("font_size",Access.fit_font(theme.default_font,guide_label.text,24,text_scale,Vector2(252,202),true))
	guide_label.tooltip_text=guide_label.text
	hint_button.visible=true
	rewind_button.visible=sector_number>=2 or (board!=null and board.hits>0)
	shield_button.visible=economy.shield_stock>0 or economy.shield_armed
	analyzer_button.visible=sector_number>=2 and economy.stock>0
	third_button.visible=economy.owned.has("THIRD_EYE")
	journal_button.visible=sector_number>=3 or phantom.active()
	cleanse_button.visible=sector_number>=3 or phantom.active() or parasite.active()
	if pending_sector:
		next_button.text=tr("GUIDE_NEXT")
func _refresh_tools() -> void:
	var active: bool = board!=null and not board.finished() and not protocol_active
	if is_instance_valid(portal_button):
		portal_button.visible = board!=null and board.has_portal()
		portal_button.disabled = not active
		portal_button.text = "PORTAL: "+_on_off(board.portal_enabled) if board!=null else "PORTAL"
	if is_instance_valid(journal_button):
		var entries: Array[String]=_journal_entries()
		journal_button.disabled=not active or entries.is_empty()
		journal_button.text=tr("VIS_JOURNAL")+((" [%d]" % entries.size()) if entries.size()>1 else "")
		journal_button.tooltip_text=tr("SYNERGY_JOURNAL")
	if is_instance_valid(cleanse_button):
		cleanse_button.tooltip_text=tr("SYNERGY_CLEANSE")
		cleanse_button.disabled = not active or not (phantom.active() or parasite.active()) or (economy.stock<=0 and not _free_cleanse() and not parasite.blocked())
	if is_instance_valid(rule_button):
		rule_button.text = Tools.NAMES[board.rule] if board!=null else "CLASSIC"
		rule_button.disabled = not active
	if is_instance_valid(hint_button):
		hint_button.text = tr("VIS_HINT")+" [%d]" % (hints_left+economy.stock)
		hint_button.disabled = not active or (hints_left<=0 and economy.stock<=0) or hint_cell>=0
	if is_instance_valid(analyzer_button):
		analyzer_button.text = tr("VIS_ANALYZER")+" [%d]" % economy.stock
		analyzer_button.disabled = not active or economy.stock<=0
	if is_instance_valid(third_button):
		third_button.text = tr("MOD_THIRD_EYE")+" [%d]" % (1 if economy.owned.has("THIRD_EYE") and not economy.third_used else 0)
		third_button.disabled = not active or not economy.owned.has("THIRD_EYE") or economy.third_used
	if is_instance_valid(shield_button):
		shield_button.text = tr("VIS_ARMED") if economy.shield_armed else tr("VIS_SHIELD")+" [%d]" % economy.shield_stock
		shield_button.disabled = not active or economy.shield_stock<=0 or economy.shield_armed
	if is_instance_valid(rewind_button):
		rewind_button.text = tr("VIS_REWIND")+" [%d]" % rewinds_left
		rewind_button.disabled = not active or rewinds_left<=0 or rewind_data.is_empty()
	_refresh_marks()
func _refresh_marks() -> void:
	var neighbors: Array[int] = []
	if board!=null and hover_cell>=0 and hover_cell<board.cells.size() and board.cells[hover_cell]==Board.Cell.OPEN and not protocol_active:
		neighbors = board.neighbors(hover_cell,board.rule)
	for i in range(marks.size()):
		if not is_instance_valid(marks[i]): continue
		var target: bool = i==hint_cell
		var premise: bool = hint_sources.has(i)
		var adjacent: bool = neighbors.has(i) or inspect_marks.has(i)
		marks[i].visible = not protocol_active and (target or premise or adjacent)
		if marks[i].visible:
			var style: StyleBoxFlat=style_bank.get_style(Color(0,0,0,0),GREEN if target else (AMBER if premise else Color("81b6a6")),5 if target else 3)
			if marks[i].get_theme_stylebox("panel")!=style: marks[i].add_theme_stylebox_override("panel",style)

func _hint_limit() -> int:
	return Tools.HINT_LIMITS[profile]+(1 if campaign.active and campaign.compact and profile==1 else 0)+(1 if economy.owned.has("ASSISTANT") else 0)
func _rewind_limit() -> int:
	return Tools.REWIND_LIMITS[profile]+(1 if economy.owned.has("CHRONOMANCER") else 0)
func _shop_available() -> bool:
	return sector_number>1 and sector_ready and board==null and not protocol_active and (not campaign.active or not campaign.compact or sector_number in [2,4,7,8])
func _lock_shop_offer(button: Button, unaffordable: bool) -> void:
	button.disabled=unaffordable or economy.shop_locked()
	if economy.shop_locked():
		var grey: Color=Access.readable(Color("737973"),high_contrast)
		button.add_theme_color_override("font_disabled_color",grey)
		button.add_theme_stylebox_override("disabled",_style(Color("171b18"),grey.darkened(0.45)))
		button.tooltip_text=tr("SHOP_FULL")
func _shop() -> void:
	if not _shop_available():
		_show("game")
		return
	if _simple_campaign():
		_simple_shop()
		return
	_label((tr("GUIDE_SHOP") if campaign.active and profile==0 else tr("VIS_SHOP"))+" // %02d" % sector_number,Rect2(124,185,1160,65),page,40)
	_label("CR %d  |  HP %d/%d  |  %s %d/%d  |  %s %d/%d" % [economy.credits,run_hp,_max_hp(),tr("VIS_STOCK"),economy.stock,economy.capacity(),tr("VIS_MODULES"),economy.owned.size(),economy.slot_limit()],Rect2(124,256,1170,60),page,27,AMBER)
	var offers: Array[String] = economy.offers()
	for i in range(offers.size()):
		var id: String = offers[i]
		var y: int = 340+i*110
		var buy := _button(tr("MOD_"+id)+"  /  "+str(economy.price(id))+" CR",Rect2(124,y,510,86),page,_buy_module.bind(id),26)
		buy.name="ModuleOffer_"+id
		_lock_shop_offer(buy,economy.credits<economy.price(id))
		_label(tr("DESC_PROFIT_HARD" if id=="PROFIT" and profile==3 else "DESC_"+id),Rect2(654,y,630,100),page,25,DIM if economy.shop_locked() else GREEN)
	var charge := _button(tr("VIS_BUY_CHARGE")+" / 12",Rect2(124,684,275,60),page,_buy_charge,21)
	_lock_shop_offer(charge,economy.stock>=economy.capacity() or economy.credits<12)
	var repair := _button(tr("VIS_REPAIR")+" / %d" % economy.repair_price(),Rect2(419,684,275,60),page,_repair,21)
	repair.disabled = run_hp>=_max_hp() or economy.credits<economy.repair_price()
	var shield := _button(tr("VIS_SHIELD")+" / 18",Rect2(714,684,275,60),page,_buy_shield,21)
	_lock_shop_offer(shield,economy.shield_stock>=1 or economy.credits<18)
	var reroll := _button(tr("VIS_REROLL")+" / %d" % economy.reroll_price(),Rect2(1009,684,275,60),page,_reroll_shop,21)
	_lock_shop_offer(reroll,economy.credits<economy.reroll_price() or economy.rerolls>=100)
	var installed := PackedStringArray()
	for id in economy.owned: installed.append(tr("MOD_"+id))
	_label(tr("VIS_MODULES")+": "+(", ".join(installed) if not installed.is_empty() else "—"),Rect2(124,754,1160,68),page,24,DIM)
	if economy.shop_locked(): _label(tr("SHOP_FULL"),Rect2(124,316,1160,24),page,18,DIM)
	_button(tr("GUIDE_SHOP_NEXT" if campaign.active and profile==0 else "VIS_NEXT_SECTOR"),Rect2(124,836,570,64),page,func(): _show("game"),28)
	_button(tr("VIS_BACK"),Rect2(714,836,570,64),page,func(): _show("menu"),28)
func _simple_shop() -> void:
	_label(tr("GUIDE_SHOP")+" // %02d" % sector_number,Rect2(124,185,1160,65),page,40)
	_label("%d CR  |  %s %d/%d  |  %s %d/%d" % [economy.credits,tr("SIMPLE_HEALTH"),run_hp,_max_hp(),tr("VIS_MODULES"),economy.owned.size(),economy.slot_limit()],Rect2(124,256,1170,60),page,27,AMBER)
	var repair:=_button(tr("SIMPLE_REPAIR")+" / %d CR" % economy.repair_price(),Rect2(124,340,510,86),page,_repair,26)
	repair.name="SimpleRepair"
	repair.disabled=run_hp>=_max_hp() or economy.credits<economy.repair_price()
	_label(tr("SIMPLE_REPAIR_DESC"),Rect2(654,340,630,86),page,25)
	if campaign.compact and profile<=1:
		_label(tr("BALANCE_STOCK_NOTE"),Rect2(124,310,1160,28),page,18,DIM)
	var offers: Array[String]=economy.offers()
	for i in range(offers.size()):
		var id: String=offers[i]
		var y: int=450+i*110
		var buy:=_button(tr("MOD_"+id)+" / %d CR" % economy.price(id),Rect2(124,y,510,86),page,_buy_module.bind(id),26)
		buy.name="SimpleOffer_"+id
		_lock_shop_offer(buy,economy.credits<economy.price(id))
		_label(tr("SIMPLE_DESC_"+id),Rect2(654,y,630,100),page,25,DIM if economy.shop_locked() else GREEN)
	var installed:=PackedStringArray()
	for id in economy.owned: installed.append(tr("MOD_"+id))
	_label(tr("VIS_MODULES")+": "+(", ".join(installed) if not installed.is_empty() else "—"),Rect2(124,690,1160,74),page,24,DIM)
	if economy.shop_locked(): _label(tr("SHOP_FULL"),Rect2(124,766,1160,54),page,23,DIM)
	_button(tr("GUIDE_SHOP_NEXT"),Rect2(124,836,570,64),page,func(): _show("game"),28)
	_button(tr("VIS_BACK"),Rect2(714,836,570,64),page,func(): _show("menu"),28)
func _buy_module(id: String) -> void:
	if not _shop_available() or screen!="shop": return
	if economy.shop_locked(): return
	if economy.buy(id):
		audio.play_event("module")
		_apply_hp_cap()
		hints_left = _hint_limit()
		rewinds_left = _rewind_limit()
		_save_session()
		_show("shop")
func _buy_charge() -> void:
	if _shop_available() and screen=="shop" and economy.buy_charge():
		audio.play_event("purchase")
		_save_session()
		_show("shop")
func _reroll_shop() -> void:
	if _shop_available() and screen=="shop" and economy.reroll():
		audio.play_event("reroll")
		_save_session()
		_show("shop")

func _snapshot_board() -> Dictionary:
	var data: Dictionary = Store.snapshot(board,profile,active_seed,first_cell,sector_start_hp,protected_hits)
	if not data.is_empty():
		data["phantom"] = phantom.snapshot()
		data["parasite"] = parasite.snapshot()
		if anomaly_plan!=Synergy.LEGACY: data["anomaly_plan"]=anomaly_plan
	return data
func _guarded_reveal(i: int) -> void:
	if board.finished() or i<0 or i>=board.cells.size() or board.cells[i]!=Board.Cell.CLOSED or i==board.blocked_cell: return
	if not economy.can_protect():
		board.reveal(i)
		return
	# Temporarily reserve one integrity point; only consume protection on a real hit.
	var hp: int = board.hp
	var hits: int = board.hits
	board.hp += 1
	board.reveal(i)
	if board.hits>hits:
		economy.consume_protection()
		protected_hits += 1
		protected_this_move += 1
	else:
		board.hp = hp
func _guarded_chord(i: int) -> void:
	if board.finished() or board.cells[i]!=Board.Cell.OPEN: return
	var neighbors: Array[int] = board.neighbors(i,board.rule)
	var count: int = 0
	for n in neighbors:
		if board.cells[n] in [Board.Cell.FLAG,Board.Cell.NEUTRALIZED]: count += 1
	if count!=Rules.mine_count(board.clue(i,board.rule),neighbors.size(),board.rule): return
	for n in neighbors:
		if board.finished(): break
		_guarded_reveal(n)
func _arm_shield() -> void:
	if protocol_active or board==null or board.finished() or not economy.arm_shield(): return
	_clear_inspection()
	rewind_data.clear()
	message_key = "VIS_ARMED"
	audio.play_event("shield")
	_refresh()
	_save_session()
func _repair() -> void:
	if not _shop_available() or screen!="shop": return
	var old_hp: int=run_hp
	run_hp = economy.repair(run_hp,_max_hp())
	if run_hp>old_hp: audio.play_event("repair")
	sector_start_hp = run_hp
	_save_session()
	_show("shop")
func _buy_shield() -> void:
	if _shop_available() and screen=="shop" and economy.buy_shield():
		audio.play_event("purchase")
		_save_session()
		_show("shop")
func _max_hp() -> int:
	return economy.max_hp(Profiles.HP[profile])
func _apply_hp_cap() -> void:
	run_hp = clampi(run_hp,1,_max_hp())
	sector_start_hp = run_hp
func _clear_inspection() -> void:
	inspect_mode = ""
	inspect_result = ""
	inspect_marks.clear()
func _select_inspection(mode: String) -> void:
	if protocol_active or board==null or board.finished(): return
	if mode=="analyzer" and economy.stock<=0: return
	if mode=="third" and (not economy.owned.has("THIRD_EYE") or economy.third_used): return
	var same: bool = inspect_mode==mode
	_clear_inspection()
	hint_cell = -1
	hint_sources.clear()
	if not same:
		inspect_mode = mode
		inspect_result = tr("VIS_SELECT_OPEN" if mode=="analyzer" else "VIS_SELECT_GROUP")
	_refresh()
func _inspect_target(i: int) -> void:
	if board==null or board.finished() or protocol_active: return
	var result: Dictionary = Tools.analyzer(board,i) if inspect_mode=="analyzer" else Tools.third_eye(board,i)
	if result.is_empty(): return
	if inspect_mode=="analyzer":
		if not economy.use_analyzer(): return
		inspect_result = "%s #%d: %s = %d" % [tr("VIS_ANALYZER"),i+1,Tools.NAMES[result["rule"]],result["value"]]
	else:
		if not economy.use_third(): return
		inspect_result = "%s #%d: %d %s" % [tr("MOD_THIRD_EYE"),i+1,result["value"],tr("VIS_GROUP_MINES")]
	inspect_marks.assign(result["cells"])
	inspect_mode = ""
	rewind_data.clear()
	audio.play_event("scanner")
	_refresh()
	_save_session()

func _free_cleanse() -> bool:
	return (economy.owned.has("HOTFIX") or (_simple_campaign() and economy.owned.has("STABILIZER"))) and not phantom.hotfix_used and not parasite.hotfix_used
func _journal_entries() -> Array[String]:
	var entries: Array[String]=[]
	if board==null: return entries
	if phantom.cell>=0: entries.append("PHANTOM")
	if parasite.cell>=0: entries.append("PARASITE")
	if board.has_portal(): entries.append("PORTAL")
	return entries
func _open_journal() -> void:
	if protocol_active or board==null or board.finished(): return
	var entries: Array[String]=_journal_entries()
	if entries.is_empty(): return
	_clear_inspection()
	journal_index=posmod(journal_index,entries.size())
	var entry: String=entries[journal_index]
	var prefix: String="%d/%d " % [journal_index+1,entries.size()] if entries.size()>1 else ""
	journal_index=posmod(journal_index+1,entries.size())
	if entry=="PORTAL":
		inspect_result=prefix+"PORTAL #%d <-> #%d / %s" % [board.portal_pair.x+1,board.portal_pair.y+1,tr("VIS_PORTAL_HELP")]
		inspect_marks.assign([board.portal_pair.x,board.portal_pair.y])
	elif entry=="PARASITE":
		inspect_result=prefix+"PARASITE #%d / %s" % [parasite.cell+1,tr("VIS_PARASITE_SAFE")]
		inspect_marks.append(parasite.cell)
	else:
		inspect_result=prefix+"PHANTOM #%d / %s = %d" % [phantom.cell+1,Tools.NAMES[phantom.rule],phantom.value]
		inspect_marks.assign(Rules.neighbors(board.width,board.height,phantom.cell,phantom.rule))
		inspect_marks.append(phantom.cell)
	audio.play_event("key")
	_refresh()

func _cleanse() -> void:
	if protocol_active or board==null or board.finished() or not (phantom.active() or parasite.active()): return
	var infection: bool = parasite.active()
	var free: bool = _free_cleanse()
	# Fail-safe: no stock or Hotfix must never make a proven safe cell permanently inaccessible.
	var emergency: bool = infection and parasite.blocked() and economy.stock<=0 and not free
	if not free and not emergency and economy.stock<=0: return
	var cleared: bool = parasite.cleanse(board,free) if infection else phantom.clear_zone(free)
	if not cleared: return
	if not free and not emergency: economy.stock -= 1
	rewind_data.clear()
	_clear_inspection()
	message_key = "VIS_PARASITE_CLEAR" if infection else "VIS_PHANTOM_CLEAR"
	audio.play_event("cleanse")
	_refresh()
	_save_session()

func _toggle_portal() -> void:
	if protocol_active or board==null or board.finished() or not board.has_portal(): return
	board.portal_enabled = not board.portal_enabled
	_clear_inspection()
	hint_cell = -1
	hint_sources.clear()
	message_key = "VIS_PORTAL_CHANGED"
	audio.play_event("portal")
	immersion_triggered.emit("PORTAL")
	_refresh()
	_save_session()

func _challenges() -> void:
	_label(tr("CH_MENU")+" %d/%d" % [collection.trials.size(),Challenge.KINDS.size()],Rect2(124,215,1170,70),page,40)
	_label(tr("CH_MENU_INTRO"),Rect2(124,292,1170,90),page,28,DIM)
	for i in range(Challenge.KINDS.size()):
		var id: String = Challenge.KINDS[i]
		var completed: bool=collection.trials.has(id)
		var item:=_button(id+("  ✓" if completed else ""),Rect2(124+float(i%2)*570,395+float(i/2)*97,540,76),page,_start_challenge.bind(id),30)
		item.name="LabCard_"+id
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))
func _start_challenge(id: String) -> void:
	if not Challenge.KINDS.has(id): return
	challenge_kind=id
	_show("challenge")
func _challenge() -> void:
	var challenge := ChallengeUI.new()
	challenge.emblem_host=header_emblem_slot
	challenge.reduced_motion=reduced
	challenge.kind=challenge_kind
	challenge.position=Vector2(80,180)
	challenge.size=Vector2(1266,710)
	challenge.theme=theme
	challenge.high_contrast=high_contrast
	challenge.large_symbols=large_symbols
	challenge.text_scale=text_scale
	challenge.back.connect(func(): _show("challenges"))
	challenge.clicked.connect(func(): audio.play_event("key"))
	challenge.ui_clicked.connect(func(): audio.play_event("menu_click"))
	challenge.trial_completed.connect(func(id: String):
		if screen=="challenge" and challenge.model.won() and collection.finish_trial(id): _save_session())
	active_trial=challenge
	_wire_trial_immersion(challenge)
	page.add_child(challenge)
	_play_immersion(Immersion.identity(challenge_kind),true)

func _modes() -> void:
	_label(tr("CAM_MODE"),Rect2(124,205,1170,65),page,42)
	_label(tr("MODE_DESC"),Rect2(124,278,1170,94),page,26,DIM)
	_button(tr("CAM_CAMPAIGN"),Rect2(124,390,1170,80),page,func():
		campaign_selected=true
		finite_selected=false
		_show("profiles"),30)
	var free := _button(tr("MODE_FREE_TEN"),Rect2(124,490,1170,80),page,func():
		campaign_selected=false
		finite_selected=true
		_show("profiles"),30)
	free.disabled=ending_gallery.is_empty()
	_button(tr("MODE_ENDLESS"),Rect2(124,590,1170,80),page,func():
		campaign_selected=false
		finite_selected=false
		_show("profiles"),30)
	_button("CLASSIC",Rect2(124,690,1170,80),page,func(): _show("classic"),30)
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))

func _campaign_intro() -> void:
	var act: int=campaign.act_index(sector_number)
	var tint: Color=ActPlate.TINTS[act]
	_label("ACT %d // %s" % [act+1,Campaign.ACT_IDS[act]],Rect2(124,215,1170,80),page,42,tint)
	var ranges: Array[String]=["01–03","04–06","07–09","10"]
	_label(tr("CAM_ACT_RANGE")+" "+ranges[act]+"  //  "+tr("CAM_ACT_SIGNAL_%d" % act),Rect2(124,298,1170,48),page,25,tint)
	var dialogue:=_label(tr("CAM_ACT_%d" % act),Rect2(124,363,696,300),page,30)
	dialogue.name="ActDialogue"
	_animate_transmission(dialogue)
	var plate:=ActPlate.new()
	plate.name="ActIllustration"
	plate.act_index=act
	plate.reduced_motion=reduced
	_place(plate,Rect2(850,353,470,372),page)
	_label(tr("CAM_RECORDS")+" %d / 3" % campaign.records.size(),Rect2(124,705,696,52),page,27,DIM)
	_button(tr("GUIDE_START" if act==0 else "CAM_ENTER"),Rect2(124,810,570,60),page,func():
		campaign.acknowledge(sector_number)
		_save_session()
		_show("shop" if _shop_available() else "game"))
	_button(tr("VIS_BACK"),Rect2(714,810,570,60),page,func(): _show("menu"))
func _campaign_boss() -> void:
	var id: String=campaign.boss_pending(sector_number)
	var kind: String=campaign.phase_kind(sector_number)
	if kind.is_empty():
		_show("ending_choice" if sector_number==10 else "menu")
		return
	var trial := ChallengeUI.new()
	trial.emblem_host=header_emblem_slot
	trial.reduced_motion=reduced
	trial.kind=kind
	trial.boss_identity=id
	trial.guided_encounter=campaign.compact
	trial.campaign_encounter=true
	trial.encounter_hp=Profiles.HP[profile]
	if id=="LOOP": trial.encounter_title="LOOP // %d/2" % (campaign.loop_phase+1)
	elif id=="ADMIN": trial.encounter_title="ADMIN // %d/3" % (campaign.admin_phase+1)
	trial.position=Vector2(80,180)
	trial.size=Vector2(1266,710)
	trial.theme=theme
	trial.high_contrast=high_contrast
	trial.large_symbols=large_symbols
	trial.text_scale=text_scale
	trial.back.connect(func(): _show("menu"))
	trial.clicked.connect(func(): audio.play_event("key"))
	trial.ui_clicked.connect(func(): audio.play_event("menu_click"))
	trial.encounter_won.connect(func():
		if screen!="campaign_boss" or not pending_sector or not trial.model.won(): return
		if not campaign.advance_phase(sector_number,kind): return
		if campaign.compact and campaign.cleared.has(sector_number):
			# Fixed reward after the complete encounter; no misleading last-phase clean bonus.
			last_reward=economy.boss_reward(sector_number)
		audio.play_event("phase")
		_save_session()
		_advance_sector()
		if screen=="game" and _shop_available(): _show("shop"))
	active_trial=trial
	_wire_trial_immersion(trial)
	page.add_child(trial)
	if trial.kind!="ADMIN_LINK": _play_immersion(Immersion.identity(trial.kind),true)

func _campaign_boundary() -> void:
	_label("ACT IV // ADMIN",Rect2(124,215,1170,80),page,42,AMBER)
	_label(tr("CAM_BOUNDARY"),Rect2(124,320,1170,300),page,32)
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))

func _capture_checkpoint() -> void:
	act_checkpoint={"sector":sector_number,"profile":profile,"hp":run_hp,"seed":active_seed,"economy":economy.snapshot(),"campaign":campaign.snapshot()}
func _retry_checkpoint() -> void:
	if not campaign.active or not campaign_failed: return
	if profile==3 or act_checkpoint.is_empty():
		_start_profile(profile,true)
		return
	var target: int=int(act_checkpoint.get("sector",0))
	var saved := Campaign.new()
	if target<1 or target>10 or (profile!=0 and target not in [1,4,7,10]) or target>sector_number or int(act_checkpoint.get("profile",-1))!=profile or not saved.restore(act_checkpoint.get("campaign",{}),target):
		_start_profile(profile,true)
		return
	var data: Variant=act_checkpoint.get("economy",{})
	if not data is Dictionary:
		_start_profile(profile,true)
		return
	campaign=saved
	sector_number=target
	active_seed=int(act_checkpoint.get("seed",1701))
	seed_value=str(active_seed)
	economy.reset(profile)
	economy.streamlined=campaign.active and campaign.streamlined
	economy.compact=campaign.active and campaign.compact
	economy.restore(data,target,false)
	run_hp=clampi(int(act_checkpoint.get("hp",1)),1,_max_hp())
	sector_start_hp=run_hp
	protected_hits=0
	board=null
	certificate.clear()
	first_cell=-1
	last_hits=0
	pending_sector=false
	sector_ready=true
	campaign_failed=false
	_reset_tools()
	message_key="CORE_READY"
	_save_session()
	_show("campaign_intro" if campaign.needs_intro(sector_number) else "game")
func _campaign_recovery() -> void:
	_label(tr("CAM_RETRY"),Rect2(124,215,1170,80),page,42,RED)
	_label(tr("CAM_RETRY_HARD" if profile==3 else ("CAM_RETRY_SECTOR" if profile==0 else "CAM_RETRY_ACT")),Rect2(124,320,1170,280),page,32)
	_button(tr("CAM_ENTER"),Rect2(124,810,570,60),page,_retry_checkpoint)
	_button(tr("VIS_BACK"),Rect2(714,810,570,60),page,func(): _show("menu"))
func _campaign_route() -> void:
	if not pending_sector or not campaign.archive_pending(sector_number): return
	_label(tr("CAM_ROUTE"),Rect2(124,215,1170,80),page,42,AMBER)
	var route_dialogue:=_label(tr("NARR_ARCHIVE_%02d" % sector_number)+"\n\n"+tr("COMPACT_ROUTE_DESC" if campaign.compact else "CAM_ROUTE_DESC"),Rect2(124,310,1170,220),page,30)
	_animate_transmission(route_dialogue)
	_button(tr("COMPACT_READ" if campaign.compact else "CAM_ARCHIVE"),Rect2(124,575,1170,80),page,func(): _show("campaign_archive"))
	_button(tr("COMPACT_SKIP" if campaign.compact else "CAM_SKIP"),Rect2(124,680,1170,80),page,func():
		if campaign.choose_route(sector_number,false):
			_save_session()
			_advance_sector()
			if screen=="game" and _shop_available(): _show("shop"))
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))
func _keep_compact_archive() -> void:
	if screen!="campaign_archive" or not campaign.active or not campaign.compact or not pending_sector or not campaign.choose_route(sector_number,true): return
	collection.recover("MEMORY_%02d" % sector_number)
	last_reward=economy.archive_reward()
	audio.play_event("archive")
	_save_session()
	_advance_sector()
	if screen=="game" and _shop_available(): _show("shop")
func _campaign_archive() -> void:
	if not pending_sector or not campaign.archive_pending(sector_number): return
	if campaign.compact:
		var record: String="MEMORY_%02d" % sector_number
		_label(tr("COL_TITLE_"+record),Rect2(124,215,1170,90),page,38,AMBER)
		var text_record:=_label(tr("COL_BODY_"+record),Rect2(124,320,1170,380),page,30)
		text_record.name="RecoveredRecord"
		_animate_transmission(text_record)
		var save_record:=_button(tr("COMPACT_KEEP"),Rect2(124,810,570,60),page,_keep_compact_archive)
		save_record.name="KeepRecord"
		_button(tr("VIS_BACK"),Rect2(714,810,570,60),page,func(): _show("campaign_route"))
		return
	var trial := ChallengeUI.new()
	trial.emblem_host=header_emblem_slot
	trial.reduced_motion=reduced
	trial.kind=Campaign.ARCHIVES[sector_number]
	trial.campaign_encounter=true
	trial.encounter_hp=Profiles.HP[profile]
	trial.position=Vector2(80,180)
	trial.size=Vector2(1266,710)
	trial.theme=theme
	trial.high_contrast=high_contrast
	trial.large_symbols=large_symbols
	trial.text_scale=text_scale
	trial.back.connect(func(): _show("campaign_route"))
	trial.clicked.connect(func(): audio.play_event("key"))
	trial.ui_clicked.connect(func(): audio.play_event("menu_click"))
	trial.encounter_won.connect(func():
		if screen!="campaign_archive" or not trial.model.won() or not campaign.choose_route(sector_number,true): return
		collection.recover("MEMORY_%02d" % sector_number)
		last_reward=economy.archive_reward()
		audio.play_event("archive")
		_save_session()
		_advance_sector()
		if screen=="game" and _shop_available(): _show("shop"))
	active_trial=trial
	_wire_trial_immersion(trial)
	page.add_child(trial)
	if trial.kind!="ADMIN_LINK": _play_immersion(Immersion.identity(trial.kind),true)

func _admin_intro() -> void:
	if not campaign.active or not pending_sector or campaign.boss_pending(sector_number)!="ADMIN": return
	_label("ADMIN // ROOT ACCESS",Rect2(124,215,1170,90),page,48,RED)
	var admin_dialogue:=_label(tr("CAM_ADMIN_INTRO"),Rect2(124,330,1170,350),page,32)
	_animate_transmission(admin_dialogue)
	var emblem:=BossEmblem.new()
	emblem.boss_id="ADMIN"
	emblem.reduced_motion=reduced
	_place(emblem,Rect2(Vector2.ZERO,header_emblem_slot.size),header_emblem_slot)
	_button(tr("CAM_ENTER"),Rect2(124,810,570,60),page,func(): _show("campaign_boss"))
	_button(tr("VIS_BACK"),Rect2(714,810,570,60),page,func(): _show("menu"))
	if not campaign.admin_intro_seen:
		campaign.admin_intro_seen=true
		audio.play_event("admin_intro")
		fault_triggered.emit()
		_save_session()
func _ending_choice() -> void:
	if not campaign.active or not campaign.cleared.has(10): return
	if not campaign.ending.is_empty():
		_show("ending_scene")
		return
	_label(tr("CAM_FINAL_CHOICE"),Rect2(124,205,1170,70),page,40,AMBER)
	_label(tr("CAM_FINAL_DESC")+"  "+tr("CAM_RECORDS")+" %d/3" % campaign.records.size(),Rect2(124,282,1170,100),page,27)
	var y: int=400
	for id in Campaign.ENDINGS:
		var choice := _button(id,Rect2(124,y,490,75),page,_choose_ending.bind(id),29)
		choice.disabled=not campaign.can_end(id)
		_label(tr("CAM_REQUIRE_"+id),Rect2(635,y,650,80),page,25,DIM)
		y+=96
	var rewrite := _button(tr("CAM_REWRITE_TRIAL"),Rect2(124,705,1170,65),page,func(): _show("rewrite_trial"),25)
	rewrite.disabled=campaign.records.size()!=3 or campaign.rewrite_done
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))
func _rewrite_trial() -> void:
	if not campaign.cleared.has(10) or campaign.records.size()!=3 or campaign.rewrite_done or not campaign.ending.is_empty(): return
	var trial := ChallengeUI.new()
	trial.emblem_host=header_emblem_slot
	trial.reduced_motion=reduced
	trial.kind="REWRITE"
	trial.campaign_encounter=true
	trial.encounter_hp=Profiles.HP[profile]
	trial.position=Vector2(80,180)
	trial.size=Vector2(1266,710)
	trial.theme=theme
	trial.high_contrast=high_contrast
	trial.large_symbols=large_symbols
	trial.text_scale=text_scale
	trial.back.connect(func(): _show("ending_choice"))
	trial.clicked.connect(func(): audio.play_event("key"))
	trial.ui_clicked.connect(func(): audio.play_event("menu_click"))
	trial.encounter_won.connect(func():
		if screen!="rewrite_trial" or not trial.model.won() or campaign.rewrite_done: return
		campaign.rewrite_done=true
		_save_session()
		_show("ending_choice"))
	active_trial=trial
	_wire_trial_immersion(trial)
	page.add_child(trial)
	if trial.kind!="ADMIN_LINK": _play_immersion(Immersion.identity(trial.kind),true)
func _choose_ending(id: String) -> void:
	if not campaign.choose_ending(id): return
	if not ending_gallery.has(id): ending_gallery.append(id)
	_save_session()
	audio.play_event("shutdown" if id=="SHUTDOWN" else "win")
	_show("ending_scene")
func _ending_scene(id: String) -> void:
	if id not in Campaign.ENDINGS: return
	var tint: Color=EndingPlate.TINTS[id]
	var replay: bool=screen=="gallery_preview"
	_label("MINE // "+id,Rect2(124,215,1170,80),page,48,tint)
	_label(tr("CAM_FINAL_STATUS")+" // "+tr("CAM_END_STATUS_"+id),Rect2(124,298,1170,48),page,25,tint)
	var dialogue:=_label(tr("CAM_END_"+id),Rect2(124,365,696,340),page,30)
	dialogue.name="EndingDialogue"
	_animate_transmission(dialogue)
	var plate:=EndingPlate.new()
	plate.name="EndingIllustration"
	plate.ending_id=id
	plate.reduced_motion=reduced
	_place(plate,Rect2(850,353,470,372),page)
	if not replay:
		var gallery_button:=_button(tr("CAM_GALLERY"),Rect2(124,810,570,60),page,func(): _show("gallery"))
		gallery_button.name="EndingGallery"
	var back_button:=_button(tr("VIS_BACK"),Rect2(124,810,1170,60) if replay else Rect2(714,810,570,60),page,func(): _show("gallery" if replay else "menu"))
	back_button.name="EndingBack"
func _gallery() -> void:
	_label(tr("CAM_GALLERY")+" %d/3" % ending_gallery.size(),Rect2(124,205,1170,70),page,42)
	_label(tr("COLLECTION_DESC"),Rect2(124,280,1170,48),page,24,DIM)
	for i in range(Campaign.ENDINGS.size()):
		var id: String=Campaign.ENDINGS[i]
		var unlocked: bool=ending_gallery.has(id)
		var y: float=340+i*135
		var item:=_button(id+" // "+tr("CAM_UNLOCKED" if unlocked else "CAM_LOCKED"),Rect2(124,y,1170,112),page,_show_gallery_ending.bind(id),30)
		item.name="EndingCard_"+id
		item.disabled=not unlocked
		item.alignment=HORIZONTAL_ALIGNMENT_LEFT
		if unlocked:
			var thumb:=TextureRect.new()
			thumb.texture=EndingPlate.ART[id]
			thumb.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			thumb.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumb.mouse_filter=Control.MOUSE_FILTER_IGNORE
			_place(thumb,Rect2(1010,6,148,100),item)
	_button(tr("VIS_BACK"),Rect2(124,810,570,60),page,func(): _show("menu"))
	_button(tr("COLLECTION_ARCHIVES")+" %d/3" % collection.archives.size(),Rect2(714,810,570,60),page,func(): _show("archives"),24)

func _show_gallery_ending(id: String) -> void:
	if not ending_gallery.has(id): return
	gallery_preview=id
	_show("gallery_preview")

func _classic() -> void:
	var view:=ClassicUI.new()
	view.model=classic
	view.position=Vector2(80,180)
	view.size=Vector2(1266,710)
	view.theme=theme
	view.high_contrast=high_contrast
	view.large_symbols=large_symbols
	view.back.connect(func(): _show("modes"))
	view.clicked.connect(func(): audio.play_event("key"))
	view.ui_clicked.connect(func(): audio.play_event("menu_click"))
	page.add_child(view)
func _free_complete() -> void:
	_label(tr("MODE_FREE_COMPLETE"),Rect2(124,215,1170,100),page,42,AMBER)
	_label(tr("MODE_FREE_RESULT")+"\nCR %d / HP %d" % [economy.credits,run_hp],Rect2(124,350,1170,300),page,32)
	_button(tr("VIS_BACK"),Rect2(124,810,570,60),page,func(): _show("menu"))

func _update_music() -> void:
	if not is_instance_valid(audio): return
	var ending_id: String=gallery_preview if screen=="gallery_preview" else campaign.ending
	audio.select_music(Atmosphere.scene_theme(screen,campaign.active,campaign.act_index(sector_number),campaign.boss_pending(sector_number),ending_id,challenge_kind))

func _archives() -> void:
	_label(tr("COLLECTION_ARCHIVES")+" %d/3" % collection.archives.size(),Rect2(124,205,1170,70),page,42)
	_label(tr("COLLECTION_ARCHIVE_DESC"),Rect2(124,280,1170,80),page,25,DIM)
	for i in range(Collection.RECORDS.size()):
		var id: String=Collection.RECORDS[i]
		var unlocked: bool=collection.archives.has(id)
		var item:=_button(id+" // "+tr("COL_TITLE_"+id if unlocked else "CAM_LOCKED"),Rect2(124,380+i*120,1170,92),page,_open_archive.bind(id),28)
		item.name="ArchiveCard_"+id
		item.disabled=not unlocked
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("gallery"))
func _open_archive(id: String) -> void:
	if not collection.archives.has(id) or not Collection.RECORDS.has(id): return
	archive_preview=id
	_show("archive_preview")
func _archive_preview() -> void:
	if not Collection.RECORDS.has(archive_preview) or not collection.archives.has(archive_preview):
		_show("archives")
		return
	_label(archive_preview+" // "+tr("COL_TITLE_"+archive_preview),Rect2(124,215,1170,90),page,38,AMBER)
	var record:=_label(tr("COL_BODY_"+archive_preview),Rect2(124,345,1170,365),page,30)
	record.name="ArchiveText"
	_label(tr("COLLECTION_READ_ONLY"),Rect2(124,727,1170,50),page,24,DIM)
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("archives"))

func _performance() -> void:
	_label(tr("PERF_TITLE"),Rect2(124,205,1170,76),page,42)
	var panel:=PerformancePanel.new()
	panel.name="PerformanceReadout"
	_place(panel,Rect2(124,310,1170,450),page)
	_button(tr("VIS_BACK"),Rect2(124,810,350,60),page,func(): _show("menu"))

func _accessibility() -> void:
	_label(tr("ACC_TITLE"),Rect2(124,205,1170,68),page,40)
	var contrast_button:=_button(tr("ACC_CONTRAST")+": "+_on_off(high_contrast),Rect2(124,292,1170,60),page,func():
		high_contrast=not high_contrast
		theme=_terminal_theme()
		_save_session()
		_show("accessibility"))
	contrast_button.name="ContrastSetting"
	var symbols_button:=_button(tr("ACC_SYMBOLS")+": "+_on_off(large_symbols),Rect2(124,368,1170,60),page,func():
		large_symbols=not large_symbols
		_save_session()
		_show("accessibility"))
	symbols_button.name="SymbolsSetting"
	var clear_button:=_button(tr("ACC_CLEAR")+": "+_on_off(clear_display),Rect2(124,444,1170,60),page,func():
		clear_display=not clear_display
		_apply()
		_show("accessibility"))
	clear_button.name="ClearDisplaySetting"
	_button(tr("VIS_MOTION")+": "+_on_off(reduced),Rect2(124,520,1170,60),page,func():
		reduced=not reduced
		_apply()
		_show("accessibility"))
	var lamp:=_button(tr("RC_LAMP")+": "+_on_off(lamp_animation),Rect2(124,596,1170,60),page,func():
		lamp_animation=not lamp_animation
		_save_session()
		_show("accessibility"))
	lamp.name="LampSetting"
	_button(tr("POLISH_TEXT_SCALE")+" %d%%" % roundi(text_scale*100),Rect2(124,672,1170,60),page,func(): _show("text_scale"))
	_label(tr("ACC_KEYS"),Rect2(124,742,1170,72),page,20)
	_button(tr("VIS_BACK"),Rect2(124,820,350,58),page,func(): _show("settings"))

func back_shortcut() -> bool:
	if protocol_active or warning_pending or screen=="menu": return false
	var parent_screen: String={
		"audio":"settings","accessibility":"settings","text_scale":"accessibility","confirm_run":"profiles","performance":"menu",
		"classic":"modes","profiles":"modes","challenge":"challenges",
		"archive_preview":"archives","gallery_preview":"gallery","archives":"gallery",
		"campaign_archive":"campaign_route","rewrite_trial":"ending_choice"
	}.get(screen,"menu")
	_save_session()
	_show(parent_screen)
	return true

func _content_warning() -> void:
	_label(tr("RC_WARNING_TITLE"),Rect2(124,210,1170,74),page,42,AMBER)
	_label(tr("RC_WARNING_TEXT"),Rect2(124,305,1170,230),page,34)
	_button(tr("VIS_LANGUAGE")+": "+("Українська" if is_uk else "English"),Rect2(124,560,1170,62),page,func():
		is_uk=not is_uk
		TranslationServer.set_locale("uk" if is_uk else "en")
		_show("warning"),25)
	var normal:=_button(tr("RC_WARNING_CONTINUE"),Rect2(124,650,1170,64),page,_accept_warning.bind(false),30)
	normal.name="WarningContinue"
	var safe:=_button(tr("RC_WARNING_SAFE"),Rect2(124,734,1170,72),page,_accept_warning.bind(true),28)
	safe.name="WarningSafe"
func _accept_warning(safe: bool) -> void:
	if not warning_pending: return
	warning_pending=false
	warning_acknowledged=true
	if safe:
		clear_display=true
		reduced=true
		lamp_animation=false
		audio.set_levels(audio.sfx_level,audio.hum_level,false)
	else:
		audio.set_levels(audio.sfx_level,audio.hum_level,warning_sound)
	_apply()
	_show("menu")
	warning_accepted.emit()

func _has_run() -> bool:
	return sector_ready or pending_sector or (campaign.active and campaign_failed) or (board!=null and not board.finished())
func _request_profile(next_profile: int,story: bool,finite: bool) -> void:
	if not _has_run():
		_start_profile(next_profile,story,finite)
		return
	requested_profile=next_profile
	requested_campaign=story
	requested_finite=finite
	_show("confirm_run")
func _confirm_run() -> void:
	_label(tr("POLISH_REPLACE_TITLE"),Rect2(124,240,1170,100),page,42,AMBER)
	_label(tr("POLISH_REPLACE_BODY"),Rect2(124,365,1170,200),page,32)
	var cancel:=_button(tr("POLISH_CANCEL"),Rect2(124,630,1170,72),page,func(): _show("profiles"))
	cancel.name="ConfirmCancel"
	var confirm:=_button(tr("POLISH_REPLACE_CONFIRM"),Rect2(124,730,1170,72),page,func(): _start_profile(requested_profile,requested_campaign,requested_finite))
	confirm.name="ConfirmAction"
func _power_off() -> void:
	if screen!="menu" or warning_pending or protocol_active: return
	_save_session()
	shutdown_requested.emit()

func _text_scale_page() -> void:
	_label(tr("POLISH_TEXT_SCALE"),Rect2(124,205,1170,72),page,42)
	_label(tr("POLISH_SCALE_DESC"),Rect2(124,300,1170,145),page,30)
	for i in range(4):
		var value: float=[0.75,1.0,1.25,1.5][i]
		var b:=_button("%d%% %s" % [roundi(value*100),"●" if is_equal_approx(value,text_scale) else ""],Rect2(124+float(i%2)*590,490+float(i/2)*110,570,88),page,func():
			text_scale=value
			theme=_terminal_theme()
			_save_session()
			_show("text_scale"),32)
		b.name="TextScale"+str(roundi(value*100))
	_button(tr("VIS_BACK"),Rect2(124,820,350,58),page,func(): _show("accessibility"))
