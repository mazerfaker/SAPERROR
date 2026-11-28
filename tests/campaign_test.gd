extends SceneTree
const Campaign = preload("res://scripts/run/campaign.gd")
const TerminalUI = preload("res://scripts/ui/terminal_ui.gd")
const ChallengeUI = preload("res://scripts/ui/anomaly_challenge_ui.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Board = preload("res://scripts/board/state.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var cam := Campaign.new()
	check(cam.boss_pending(3)=="","free run")
	cam.active=true
	check(cam.needs_intro(1),"initial intro")
	cam.acknowledge(1)
	check(not cam.needs_intro(3),"intro once")
	for sector in [3,6,9]:
		var id: String=cam.boss_pending(sector)
		check(not cam.complete_boss(sector,"INVALID"),"wrong gate")
		if id=="LOOP":
			check(cam.advance_phase(sector,"LOOP"),"first LOOP state")
			check(cam.boss_pending(sector)=="LOOP","second state mandatory")
			check(cam.advance_phase(sector,"LOOP_B"),"second LOOP state")
		else: check(cam.complete_boss(sector,id),"boss unlock")
		check(not cam.complete_boss(sector,id),"no duplicate")
		cam.acknowledge(sector+1)
	check(cam.records.is_empty() and cam.boss_pending(10)=="ADMIN","bosses do not grant optional records")
	for sector in [2,5,8]:
		check(cam.choose_route(sector,true),"optional archive")
		check(not cam.choose_route(sector,true),"archive reward once")
	check(cam.records.size()==3,"three optional records")
	check(not cam.complete_boss(10,"ADMIN"),"cannot bypass final phases")
	for kind in Campaign.ADMIN_PHASES: check(cam.advance_phase(10,kind),"ADMIN phase "+kind)
	check(cam.can_end("SHUTDOWN") and cam.can_end("CONTAINMENT") and not cam.can_end("REWRITE"),"ending conditions")
	cam.rewrite_done=true
	check(cam.can_end("REWRITE"),"rewrite unlocked")
	var restored := Campaign.new()
	check(restored.restore(cam.snapshot(),10) and restored.snapshot()==cam.snapshot(),"metadata round trip")
	var invalid: Dictionary=cam.snapshot()
	invalid["cleared"]=[]
	check(not Campaign.new().restore(invalid,10),"reject missing bosses")
	var ui := TerminalUI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(1,true)
	check(ui.screen=="campaign_intro" and ui.campaign.active,"campaign entry")
	ui.campaign.acknowledge(1)
	ui._continue_run()
	check(ui.screen=="game","resume field")
	ui.campaign.choose_route(2,false)
	ui.sector_number=3
	ui.pending_sector=true
	ui._advance_sector()
	check(ui.screen=="campaign_boss" and ui.sector_number==3,"mandatory boss")
	ui.campaign.complete_boss(3,"WATCHER")
	ui._advance_sector()
	check(ui.screen=="campaign_intro" and ui.sector_number==4,"next act")
	var saved_credits: int=ui.economy.credits
	ui.economy.credits+=100
	ui.campaign_failed=true
	ui._retry_checkpoint()
	check(ui.sector_number==4 and ui.economy.credits==saved_credits and not ui.campaign_failed,"restore act checkpoint")
	ui._start_profile(3,true)
	ui.sector_number=7
	ui.campaign_failed=true
	ui._retry_checkpoint()
	check(ui.sector_number==1 and ui.profile==3 and ui.campaign.active,"Hardcore restarts")
	ui._start_profile(1)
	check(not ui.campaign.active and ui.sector_number==1 and ui.screen=="game","free run preserved")
	ui.queue_free()
	await process_frame
	for route in [0,1,2]:
		await full_campaign(route)
	for difficulty in [0,2,3]:
		await full_campaign(2,difficulty)
	print("CAMPAIGN_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)

func solve_trial(trial: ChallengeUI) -> bool:
	if not trial.model.valid: return false
	if trial.kind=="ADMIN_LINK": trial._switch_layer()
	if trial.kind=="WATCHER": trial._journal()
	if trial.kind=="LIAR":
		var truth: Array[int]=trial.model.decoded_sensors()
		for index in range(3):
			if truth[index]!=trial.model.sensor_values[index]: trial._select_sensor(index)
	for step in range(150):
		if trial.model.done(): break
		if trial.kind=="DOUBLE" and trial.model.board().won(): trial._switch_layer()
		var proof: Dictionary=Tools.safe_hint(trial.model.board().observation([0]))
		if proof.is_empty(): break
		trial._move(int(proof["cell"]),false,false)
	return trial.model.won()
func full_campaign(route: int, difficulty: int=1) -> void:
	var ui := TerminalUI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(difficulty,true)
	var entered: int=0
	var completed: int=0
	for transition in range(100):
		if ui.screen=="campaign_intro":
			ui.campaign.acknowledge(ui.sector_number)
			ui._show("game")
		elif ui.screen=="shop":
			ui._show("game")
		elif ui.screen=="game":
			if not ui.pending_sector:
				entered+=1
				ui._reveal(0)
				if ui.board==null: break
				if ui.board.portal_enabled: ui._toggle_portal()
				for step in range(150):
					if ui.board.finished(): break
					if ui.parasite.blocked(): ui._cleanse()
					var proof: Dictionary=Tools.safe_hint(ui.board.observation([0]))
					if proof.is_empty(): break
					var target: int=int(proof["cell"])
					if ui.board.cells[target]==Board.Cell.FLAG: ui._flag_action(target)
					ui._reveal(target)
				check(ui.board.won(),"sector %d solved on route %d" % [ui.sector_number,route])
				if not ui.board.won(): break
				completed+=1
			ui._advance_sector()
		elif ui.screen=="campaign_route":
			if route==0:
				ui.campaign.choose_route(ui.sector_number,false)
				ui._advance_sector()
			else: ui._show("campaign_archive")
		elif ui.screen in ["campaign_archive","campaign_boss","rewrite_trial"]:
			var trial: ChallengeUI
			for child in ui.page.get_children():
				if child is ChallengeUI: trial=child
			check(is_instance_valid(trial),"trial UI "+ui.screen)
			if not is_instance_valid(trial): break
			check(trial.model.board().hp==Profiles.HP[difficulty],"encounter integrity matches difficulty")
			check(solve_trial(trial),"public proof "+trial.kind)
			if not trial.model.won(): break
			trial._proceed()
		elif ui.screen=="admin_intro":
			check(ui.campaign.admin_intro_seen,"ADMIN intro marked once")
			ui._show("campaign_boss")
		elif ui.screen=="ending_choice":
			var final_id: String=Campaign.ENDINGS[route]
			if route==2 and not ui.campaign.rewrite_done:
				check(not ui.campaign.can_end("REWRITE"),"rewrite gated")
				ui._show("rewrite_trial")
			else:
				check(ui.campaign.can_end(final_id),"ending unlocked "+final_id)
				ui._choose_ending(final_id)
		elif ui.screen=="ending_scene": break
		else: break
		await process_frame
	check(entered==10 and completed==10,"all ten normal sectors route "+str(route))
	check(ui.campaign.ending==Campaign.ENDINGS[route] and ui.screen=="ending_scene","correct ending "+str(route))
	check(ui.ending_gallery.has(Campaign.ENDINGS[route]),"gallery records ending")
	check(ui.campaign.cleared.size()==4 and ui.campaign.loop_phase==2 and ui.campaign.admin_phase==3,"all boss phases")
	check(ui.campaign.records.size()==(0 if route==0 else 3),"route records")
	var resumed := Campaign.new()
	check(resumed.restore(ui.campaign.snapshot(),10),"final save validation")
	check(not resumed.choose_ending("SHUTDOWN"),"ending immutable")
	var gallery_button:=ui.page.find_child("EndingGallery",true,false) as Button
	var back_button:=ui.page.find_child("EndingBack",true,false) as Button
	check(is_instance_valid(gallery_button) and is_instance_valid(back_button),"ending links directly to gallery and menu")
	if is_instance_valid(gallery_button): gallery_button.pressed.emit()
	check(ui.screen=="gallery","direct gallery navigation")
	if ui.screen!="gallery": ui._show("gallery")
	ui._show_gallery_ending(Campaign.ENDINGS[route])
	check(ui.screen=="gallery_preview","ending replay")
	check(ui.page.find_child("EndingGallery",true,false)==null,"replay only needs back")
	var replay_back:=ui.page.find_child("EndingBack",true,false) as Button
	check(is_instance_valid(replay_back),"replay back available")
	if is_instance_valid(replay_back): replay_back.pressed.emit()
	check(ui.screen=="gallery","replay returns to gallery")
	ui.queue_free()
	await process_frame
