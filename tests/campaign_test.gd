extends SceneTree
const Campaign = preload("res://scripts/run/campaign.gd")
const TerminalUI = preload("res://scripts/ui/terminal_ui.gd")
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
	ui.sector_number=3
	ui.pending_sector=true
	ui._advance_sector()
	check(ui.screen=="campaign_boss" and ui.sector_number==3,"mandatory boss")
	ui.campaign.complete_boss(3,"WATCHER")
	ui._advance_sector()
	check(ui.screen=="campaign_intro" and ui.sector_number==4,"next act")
	ui._start_profile(1)
	check(not ui.campaign.active and ui.sector_number==1 and ui.screen=="game","free run preserved")
	ui.queue_free()
	print("CAMPAIGN_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
