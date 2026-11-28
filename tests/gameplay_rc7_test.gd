extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Model=preload("res://scripts/board/anomaly_challenge.gd")
const Campaign=preload("res://scripts/run/campaign.gd")
const Board=preload("res://scripts/board/state.gd")
const Tools=preload("res://scripts/board/onboarding_tools.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("RC7 FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._request_profile(1,true,false)
	check(ui.economy.choice_mode and ui.campaign.reworked,"new player-facing start opts into RC7")
	ui.campaign.acknowledge(1)
	ui._show("game")
	ui._reveal(0)
	if ui.board!=null:
		ui.protocol.prepare(ui.board)
		ui.protocol.advance(ui.board,ui.board.cells.size())
		ui._after_action()
	ui._advance_sector()
	check(ui.screen=="shop" and ui.economy.reward_choices.size()==3,"draft before second sector")
	var id: String=ui.economy.reward_choices[0]
	ui._claim_reward(id)
	check(ui.economy.chosen_reward==id and ui.economy.credits==0,"one free choice")
	for option in ui.economy.reward_choices:
		var b:=ui.page.find_child("Reward_"+option,true,false) as Button
		check(is_instance_valid(b) and b.disabled,"all choices locked after selection")
	var keep: Dictionary=ui.economy.snapshot()
	ui._claim_reward(ui.economy.reward_choices[1])
	check(ui.economy.snapshot()==keep,"second choice rejected")
	ui._show("menu")
	ui._continue_run()
	check(ui.screen=="game" and ui.economy.chosen_reward==id,"resume does not repeat draft")
	ui.queue_free()
	for profile in range(4):
		for boss in ["WATCHER","LIAR","LOOP","ADMIN"]:
			var model:=Model.new()
			check(model.start_reworked(boss,3,profile,1701,"ASSISTANT"),"certified new boss "+boss+" "+str(profile))
			if not model.valid: continue
			var board: Board=model.board()
			check(board.width==(12 if boss=="ADMIN" else 8) and model.boards.size()==1 and not model.certificates[0].is_empty(),"single certified field "+boss)
			var mines: PackedByteArray=board._mask.duplicate()
			check(model.reward_hint() or board.won(),"assistant offers public hint")
			for step in range(300):
				if model.done(): break
				if not model.corruption.is_empty(): model.restore_signal()
				if not model.reopened.is_empty():
					model.act(int(model.reopened.keys()[0]))
					continue
				var proof: Dictionary=Tools.safe_hint(board.observation([0]))
				if proof.is_empty(): break
				model.act(int(proof["cell"]))
			check(model.won() and board._mask==mines,"public proof wins without moving mines "+boss)
	var cam:=Campaign.new()
	cam.active=true
	cam.streamlined=true
	cam.compact=true
	cam.reworked=true
	check(cam.advance_phase(3,"WATCHER") and cam.advance_phase(6,"LIAR") and cam.advance_phase(9,"LOOP") and cam.advance_phase(10,"ADMIN"),"one encounter per boss")
	check(cam.loop_phase==2 and cam.admin_phase==3 and cam.can_end("SHUTDOWN"),"final gate on single ADMIN board")
	print("GAMEPLAY_RC7_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
