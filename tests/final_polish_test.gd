extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Access=preload("res://scripts/ui/accessibility.gd")
const Profiles=preload("res://scripts/board/profiles.gd")
const Rules=preload("res://scripts/board/rules.gd")
const Validator=preload("res://scripts/solver/validator.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		if failures<=20: printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(1)
	ui._reveal(0)
	var before: Dictionary=ui._snapshot_board()
	ui._request_profile(3,true,false)
	check(ui.screen=="confirm_run" and ui._snapshot_board()==before,"new run requires confirmation")
	var cancel:=ui.page.find_child("ConfirmCancel",true,false) as Button
	check(is_instance_valid(cancel),"cancel exists")
	if is_instance_valid(cancel): cancel.pressed.emit()
	check(ui.screen=="profiles" and ui._snapshot_board()==before,"cancel preserves run")
	ui._request_profile(3,true,false)
	var confirm:=ui.page.find_child("ConfirmAction",true,false) as Button
	if is_instance_valid(confirm): confirm.pressed.emit()
	check(ui.profile==3 and ui.campaign.active and ui.board==null,"explicit replacement")
	ui._show("confirm_exit")
	check(ui.back_shortcut() and ui.screen=="menu","escape cancels exit")
	for lang in ["en","uk"]:
		TranslationServer.set_locale(lang)
		for id in ["CORE_SUB","CORE_HINT","CORE_NEW","CORE_SEED","CORE_HP","CORE_OPEN","CORE_READY","CORE_ACTIVE","CORE_WIN","CORE_LOSS","CORE_FAIL","CORE_HIT","CORE_SEED_BAD","CORE_CELL","CORE_FLAG","CORE_CLOSED","CORE_NEUTRAL","VIS_BOOT","VIS_TAGLINE","VIS_CONTINUE","VIS_START","VIS_HELP","VIS_SETTINGS","VIS_EXIT","VIS_CORE_ONLY","VIS_HELP_TEXT","VIS_BACK","VIS_FULLSCREEN","VIS_CRT","VIS_CURVE","VIS_MOTION","VIS_FLICKER","VIS_GRADE","VIS_ON","VIS_OFF","VIS_SECTOR","VIS_DIFFICULTY","VIS_STANDARD","VIS_RULE","VIS_MODULES","VIS_ANOMALY","VIS_NONE","VIS_RESOURCES","VIS_FLAGS","VIS_CONTROL_HEADER","VIS_CONTROL_SHORT","VIS_AUDIO","VIS_SOUND","VIS_SFX","VIS_HUM","VIS_AUDIO_TEST","VIS_SKIP_BOOT","VIS_BOOT_CRT","VIS_BOOT_CORE","VIS_BOOT_AUDIO","VIS_BOOT_READY","VIS_WIN_BANNER","VIS_LOSS_BANNER","VIS_NEW_GAME","VIS_TUTORIAL","VIS_STATS","VIS_RUNS","VIS_WINS","VIS_LOSSES","VIS_LESSONS","VIS_SAVE_ERROR","VIS_REPLACE_RUN","VIS_PROFILE_STORY","VIS_PROFILE_STANDARD","VIS_PROFILE_EXPERT","VIS_PROFILE_HARDCORE","TUT_REPEAT","TUT_SKIP","TUT_NEXT","TUT_COMPLETE","TUT_TITLE_0","TUT_TITLE_1","TUT_TITLE_2","TUT_TITLE_3","TUT_TITLE_4","TUT_HINT_0_0","TUT_HINT_1_0","TUT_HINT_2_0","TUT_HINT_2_1","TUT_HINT_3_0","TUT_HINT_4_0","TUT_HINT_4_1","VIS_GLASS","VIS_GLITCHES","VIS_NEXT_SECTOR","K30_0","K30_1","K30_2","K30_3","K30_4","VIS_RULE_HOVER","VIS_HINT","VIS_REWIND","VIS_REWOUND","VIS_NO_PROOF","VIS_PROVEN_SAFE","VIS_RULE_CHANGED","TUT_TITLE_5","TUT_TITLE_6","TUT_HINT_5_0","TUT_HINT_5_1","TUT_HINT_6_0","TUT_HINT_6_1","VIS_SHOP","VIS_STOCK","VIS_BUY_CHARGE","VIS_REROLL","MOD_XRAY","MOD_CHAIN","MOD_CAPACITOR","MOD_ASSISTANT","MOD_CHRONOMANCER","DESC_XRAY","DESC_CHAIN","DESC_CAPACITOR","DESC_ASSISTANT","DESC_CHRONOMANCER","VIS_PROTECTED","VIS_SHIELD","VIS_ARMED","VIS_REPAIR","VIS_REPLACE_MODULE","VIS_REPLACE_WARN","MOD_SECOND_LIFE","MOD_FUSE","MOD_AUDITOR","DESC_SECOND_LIFE","DESC_FUSE","DESC_AUDITOR","TUT_TITLE_7","TUT_HINT_7_0","MOD_RESONANCE","MOD_PROFIT","MOD_THIRD_EYE","DESC_RESONANCE","DESC_PROFIT","DESC_THIRD_EYE","VIS_ANALYZER","VIS_SELECT_OPEN","VIS_SELECT_GROUP","VIS_GROUP_MINES","VIS_JOURNAL","VIS_CLEANSE","VIS_PHANTOM_ALERT","VIS_PHANTOM_SHIELDED","VIS_PHANTOM_CLEAR","VIS_PHANTOM_HIDDEN","MOD_SHIELDING","MOD_HOTFIX","DESC_SHIELDING","DESC_HOTFIX","TUT_TITLE_8","TUT_HINT_8_0","TUT_HINT_8_1","VIS_LANGUAGE","VIS_PARASITE_WARNING","VIS_PARASITE_BLOCKED","VIS_PARASITE_CLEAR","VIS_PARASITE_SAFE","MOD_STABILIZER","DESC_STABILIZER","VIS_PORTAL_CHANGED","VIS_PORTAL_HELP","CH_MENU","CH_MENU_INTRO","CH_AUTHORED","CH_LOOP_INTRO","CH_LOOP_COUNT","CH_LOOP_DONE","CH_LOOP_RESET","CH_ACTIONS","CH_INVALID","CH_VICTORY","CH_DEFEAT","CH_DOUBLE_INTRO","CH_DOUBLE_LINKS","CH_DOUBLE_PROGRESS","CH_WATCHER_INTRO","CH_WATCHER_CLOSED","CH_WATCHER_COUNT","CH_LIAR_INTRO","CH_LIAR_SELECT","CH_LIAR_WRONG","CH_LIAR_CORRECT","CH_JOURNAL_OPEN","CH_JOURNAL_CLOSED","CAM_MODE","CAM_MODE_DESC","CAM_CAMPAIGN","CAM_FREE","CAM_RECORDS","CAM_ENTER","CAM_BOSS","CAM_BOUNDARY","CAM_ACT_0","CAM_ACT_1","CAM_ACT_2","CAM_ACT_3","MOD_ARCHIVIST","DESC_ARCHIVIST","CAM_ROUTE","CAM_ROUTE_DESC","CAM_ARCHIVE","CAM_SKIP","CAM_RETRY","CAM_RETRY_HARD","CAM_RETRY_ACT","CH_LOOP_B_INTRO","CH_ADMIN_LINK_INTRO","CH_ADMIN_LINK_STATUS","CH_REWRITE_INTRO","CAM_ADMIN_INTRO","CAM_FINAL_CHOICE","CAM_FINAL_DESC","CAM_REQUIRE_SHUTDOWN","CAM_REQUIRE_CONTAINMENT","CAM_REQUIRE_REWRITE","CAM_REWRITE_TRIAL","CAM_END_SHUTDOWN","CAM_END_CONTAINMENT","CAM_END_REWRITE","CAM_CREDITS","CAM_CREDIT_TEXT","CAM_GALLERY","CAM_UNLOCKED","CAM_LOCKED","CH_MIMIC_INTRO","CH_MIMIC_STATUS","CH_NULL_INTRO","CH_NULL_STATUS","CH_NULL_BLOCKED","CH_SCAN_NONE","CH_SCAN_FOUND","CH_SCAN_SPENT","CH_SCAN_READY","CH_INSTABILITY_INTRO","CH_INST_SWITCH","CH_INST_COUNT","CH_INST_RULE","CH_MAGNET_INTRO","CH_MAGNET_WARNING","CH_MAGNET_COMMITTED","CH_MAGNET_APPLY","MODE_DESC","MODE_FREE_TEN","MODE_ENDLESS","MODE_FREE_COMPLETE","MODE_FREE_RESULT","CLASSIC_TITLE","CLASSIC_READY","CLASSIC_MINES","CLASSIC_TIMER","CLASSIC_ON","CLASSIC_OFF","CAM_ACT_RANGE","CAM_ACT_SIGNAL_0","CAM_ACT_SIGNAL_1","CAM_ACT_SIGNAL_2","CAM_ACT_SIGNAL_3","CAM_FINAL_STATUS","CAM_END_STATUS_SHUTDOWN","CAM_END_STATUS_CONTAINMENT","CAM_END_STATUS_REWRITE","VIS_MUSIC","VIS_MUSIC_TEST","COLLECTION_MENU","COLLECTION_DESC","COLLECTION_ARCHIVES","COLLECTION_ARCHIVE_DESC","COLLECTION_READ_ONLY","COL_TITLE_MEMORY_02","COL_BODY_MEMORY_02","COL_TITLE_MEMORY_05","COL_BODY_MEMORY_05","COL_TITLE_MEMORY_08","COL_BODY_MEMORY_08","VIS_SAVE_RECOVERED","PERF_TITLE","PERF_FPS","PERF_FRAME","PERF_MEMORY","PERF_VIDEO","PERF_DRAW","PERF_NODES","PERF_NOTE","CAM_RETRY_SECTOR","DESC_PROFIT_HARD","VIS_MASTER","ACC_TITLE","ACC_CONTRAST","ACC_SYMBOLS","ACC_CLEAR","ACC_KEYS","ACC_WARNING","SYNERGY_JOURNAL","SYNERGY_CLEANSE","RC_WARNING_TITLE","RC_WARNING_TEXT","RC_WARNING_CONTINUE","RC_WARNING_SAFE","RC_LAMP","POLISH_REPLACE_TITLE","POLISH_REPLACE_BODY","POLISH_REPLACE_CONFIRM","POLISH_CANCEL","POLISH_EXIT_TITLE","POLISH_EXIT_BODY","POLISH_TEXT_SCALE","POLISH_SCALE_DESC"]:
			check(TranslationServer.translate(id)!=id,"translated "+lang+" "+id)
		for scale in [0.75,1.0,1.25,1.5]:
			ui.text_scale=scale
			ui.theme=ui._terminal_theme()
			for screen in ["menu","settings","accessibility","text_scale","profiles","confirm_exit"]:
				ui._show(screen)
				check(ui.page.size==Vector2(1426,962),"fixed CRT page "+screen)
	ui.queue_free()
	await process_frame
	var rules: Array[int]=[Rules.Rule.CLASSIC]
	for profile in range(4):
		var fallback: int=0
		var begin: int=Time.get_ticks_msec()
		var width: int=Profiles.SIZES[profile]
		for seed_value in range(1000):
			var first: int=(seed_value*37)%(width*width)
			var gen: Dictionary=Profiles.generate(profile,seed_value,first)
			check(not gen.is_empty(),"certified generation profile "+str(profile))
			if gen.is_empty(): continue
			var mask: PackedByteArray=gen["mask"]
			check(mask[first]==0 and mask.count(1)==Profiles.MINES[profile],"safe first and density")
			check(Validator.certify(width,width,mask,first,rules)==gen["certificate"],"certificate replay")
			if gen.get("fallback",false): fallback+=1
			if seed_value%100==0: check(Profiles.generate(profile,seed_value,first)==gen,"determinism")
		print("POLISH_PROFILE id=",Profiles.IDS[profile]," seeds=1000 fallback=",fallback," elapsed_ms=",Time.get_ticks_msec()-begin)
	print("FINAL_POLISH_QA checks=",checks," failures=",failures," seeds=4000")
	quit(0 if failures==0 else 1)
