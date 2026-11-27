extends SceneTree
const Synergy=preload("res://scripts/board/anomaly_synergy.gd")
const Profiles=preload("res://scripts/board/profiles.gd")
const Board=preload("res://scripts/board/state.gd")
const Phantom=preload("res://scripts/board/phantom.gd")
const Parasite=preload("res://scripts/board/parasite.gd")
const Store=preload("res://scripts/save/session_store.gd")
const Tools=preload("res://scripts/board/onboarding_tools.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for profile in range(4):
		for sector in range(1,61):
			var plan: int=Synergy.plan(profile,sector)
			check(Synergy.valid(plan,profile),"valid profile plan")
			if sector<3: check(plan==0,"no early anomaly")
			if profile==3 and sector>=6: check(plan==7,"hardcore triple")
	check(Synergy.plan(1,6)==3 and Synergy.plan(1,8)==5 and Synergy.plan(2,8)==6,"all pair variants")
	check(not Synergy.valid(7,0) and not Synergy.valid(7,1) and not Synergy.valid(8,3),"reject illegal combinations")
	# Exercise actual UI paths across representative scheduled sector pairs/triples.
	for fixture in [[1,6],[1,8],[2,6],[2,8],[3,6],[3,8]]:
		for seed_index in range(3):
			await exercise(int(fixture[0]),int(fixture[1]),1701+seed_index)
	print("SYNERGY_QA checks=",checks," failures=",failures," scheduled_runs=18")
	quit(0 if failures==0 else 1)
func exercise(profile: int, sector: int, seed_value: int) -> void:
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui.reduced=true
	ui._start_profile(profile)
	ui.sector_number=sector
	ui.economy.begin_sector(sector)
	ui.seed_input.text=str(seed_value)
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active seeded board")
	if ui.board==null or ui.board.finished():
		ui.queue_free()
		await process_frame
		return
	var b: Board=ui.board
	var mask: PackedByteArray=b._mask.duplicate()
	var hp: int=b.hp
	var plan: int=ui.anomaly_plan
	check(plan==Synergy.plan(profile,sector),"real generation selects plan")
	var has_portal: bool=(plan&Synergy.PORTAL)!=0
	var has_phantom: bool=(plan&Synergy.PHANTOM)!=0
	var has_parasite: bool=(plan&Synergy.PARASITE)!=0
	check(b.has_portal()==has_portal,"scheduled portal")
	if has_portal: ui._toggle_portal()
	# Flag toggles are valid actions and force anomaly time to advance without guessing.
	var spare: int=b.cells.find(Board.Cell.CLOSED)
	check(spare>=0,"closed cell available")
	if spare<0:
		ui.queue_free()
		await process_frame
		return
	for _i in range(3): ui._flag_action(spare)
	if b.cells[spare]==Board.Cell.FLAG: ui._flag_action(spare)
	check(not has_phantom or ui.phantom.triggered,"phantom activated")
	check(not has_parasite or ui.parasite.cell>=0,"parasite target acquired")
	if ui.parasite.active() and ui.parasite.cell==spare and b.cells[spare]==Board.Cell.FLAG and not ui.parasite.blocked(): ui._flag_action(spare)
	# Reversible links never change recorded PHANTOM evidence.
	if has_portal:
		ui._toggle_portal()
		check(ui.phantom.cell<0 or ui.phantom.value==b.clue(ui.phantom.cell,ui.phantom.rule),"portal on preserves journal")
		ui._toggle_portal()
		check(ui.phantom.cell<0 or ui.phantom.value==b.clue(ui.phantom.cell,ui.phantom.rule),"portal off preserves journal")
	var snapshot: Dictionary=ui._snapshot_board()
	var restored: Dictionary=Store.restore(snapshot)
	check(not restored.is_empty(),"combined state restore")
	if not restored.is_empty():
		check(restored["anomaly_plan"]==plan and restored["phantom"].snapshot()==ui.phantom.snapshot() and restored["parasite"].snapshot()==ui.parasite.snapshot(),"exact combined state")
	var entries: Array[String]=ui._journal_entries()
	check(entries.size()==int(has_phantom)+int(has_parasite)+int(has_portal),"each anomaly has own journal")
	for entry in entries:
		ui._open_journal()
		check(ui.inspect_result.contains(entry),"journal reaches "+entry)
	# Exhaust resources; emergency cleanup may never require a purchase.
	ui.economy.stock=0
	ui.hints_left=0
	var attempts: int=0
	while not b.finished() and attempts<200:
		attempts+=1
		if ui.parasite.blocked():
			ui._cleanse()
			check(b.blocked_cell==-1 and ui.economy.stock==0,"free emergency unblock")
		var proof: Dictionary=Tools.safe_hint(b.observation([0]))
		if proof.is_empty(): break
		var target: int=int(proof["cell"])
		if b.cells[target]==Board.Cell.FLAG: ui._flag_action(target)
		ui._reveal(target)
	check(b.won() and b.hp==hp and b.hits==0 and b._mask==mask,"combined sector solved without guesses or damage")
	ui.queue_free()
	await process_frame
