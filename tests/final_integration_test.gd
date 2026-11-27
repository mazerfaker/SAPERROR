extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Store=preload("res://scripts/save/session_store.gd")
const Board=preload("res://scripts/board/state.gd")
const Campaign=preload("res://scripts/run/campaign.gd")
const Tools=preload("res://scripts/board/onboarding_tools.gd")
var checks: int=0
var failures: int=0
var path: String
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	create_timer(120.0).timeout.connect(func(): printerr("FINAL_INTEGRATION timeout"); quit(1))
	call_deferred("run")
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
func open_ui() -> UI:
	var ui:=UI.new()
	ui.session_path=path
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	return ui
func run() -> void:
	path="user://qa_final_"+str(OS.get_process_id())+".cfg"
	clean()
	var ui:=open_ui()
	check(not ui.save_failed and ui.board==null,"fresh isolated install")
	ui.is_uk=true
	ui.high_contrast=true
	ui.large_symbols=true
	ui.clear_display=true
	ui.reduced=true
	ui.audio.set_levels(0.4,0.2,true)
	ui.audio.set_master(0.65)
	ui.audio.set_music_level(0.35)
	ui.collection.finish_trial("LOOP")
	ui.collection.recover("MEMORY_02")
	ui._start_profile(3)
	ui.sector_number=8
	ui.economy.begin_sector(8)
	ui.seed_input.text="1701"
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active hardcore field")
	if ui.board==null or ui.board.finished():
		ui.queue_free()
		clean()
		quit(1)
		return
	if ui.board.portal_enabled: ui._toggle_portal()
	var spare: int=ui.board.cells.find(Board.Cell.CLOSED)
	for _i in range(3): ui._flag_action(spare)
	ui._save_session()
	var expected: Dictionary=ui._snapshot_board()
	var economy: Dictionary=ui.economy.snapshot()
	var hints: int=ui.hints_left
	var rewinds: int=ui.rewinds_left
	var wins: int=ui.wins
	check(Store.load_report(path)["sealed"],"actual sealed production-path save")
	ui.queue_free()
	await process_frame
	ui=open_ui()
	check(not ui.save_failed and ui.profile==3 and ui.sector_number==8,"reload profile and sector")
	check(ui._snapshot_board()==expected and ui.anomaly_plan==7,"combined board and anomaly state roundtrip")
	check(ui.economy.snapshot()==economy and ui.hints_left==hints and ui.rewinds_left==rewinds,"economy and tools roundtrip")
	check(ui.is_uk and ui.high_contrast and ui.large_symbols and ui.clear_display and ui.reduced,"accessibility and language roundtrip")
	check(is_equal_approx(ui.audio.master_level,0.65) and is_equal_approx(ui.audio.sfx_level,0.4) and is_equal_approx(ui.audio.hum_level,0.2) and is_equal_approx(ui.audio.music_level,0.35),"mixer roundtrip")
	check(ui.collection.archives.has("MEMORY_02") and ui.collection.trials.has("LOOP"),"collection roundtrip")
	ui._continue_run()
	check(ui.screen=="game","resume real field")
	if ui.board==null:
		ui.queue_free()
		clean()
		quit(1)
		return
	# Use actual public proof actions rather than bypassing win accounting.
	for _i in range(200):
		if ui.board.finished(): break
		if ui.parasite.blocked(): ui._cleanse()
		var proof: Dictionary=Tools.safe_hint(ui.board.observation([0]))
		if proof.is_empty(): break
		var target: int=int(proof["cell"])
		if ui.board.cells[target]==Board.Cell.FLAG: ui._flag_action(target)
		ui._reveal(target)
	check(ui.board.won() and ui.pending_sector and ui.wins==wins+1,"one earned win")
	var reward: int=ui.last_reward
	var credits: int=ui.economy.credits
	ui._save_session()
	ui.queue_free()
	await process_frame
	ui=open_ui()
	check(ui.pending_sector and ui.board==null and ui.last_reward==reward and reward>0,"reload completed sector and reward readout")
	check(ui.economy.credits==credits and ui.wins==wins+1,"reward exactly once")
	check(ui.economy.reward(8,80,0)==0,"no replay reward after reload")
	ui._continue_run()
	check(ui.sector_number==9 and ui.board==null and not ui.pending_sector,"resume advances once")
	ui._save_session()
	# Two identical committed generations, then corrupt primary bytes.
	ui._save_session()
	ui.queue_free()
	await process_frame
	var file:=FileAccess.open(path,FileAccess.WRITE)
	check(file!=null,"corruption fixture")
	if file!=null:
		file.store_string("corrupted primary")
		file.close()
	ui=open_ui()
	check(ui.save_recovered and not ui.save_failed and ui.sector_number==9,"UI backup recovery")
	check(ui.economy.credits==credits and ui.wins==wins+1,"no loss or duplicate reward on backup")
	ui._save_session()
	check(not ui.save_recovered and Store.load_report(path)["source"]=="primary","repaired primary")
	ui._start_profile(1,true)
	ui.campaign.acknowledge(1)
	ui.campaign.choose_route(2,false)
	ui.sector_number=3
	ui.economy.begin_sector(3)
	ui.pending_sector=true
	ui.sector_ready=false
	ui._save_session()
	ui.queue_free()
	await process_frame
	ui=open_ui()
	ui._continue_run()
	check(ui.screen=="campaign_boss" and ui.campaign.boss_pending(3)=="WATCHER","mandatory boss gate after reload")
	ui.queue_free()
	await process_frame
	clean()
	print("FINAL_INTEGRATION_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
