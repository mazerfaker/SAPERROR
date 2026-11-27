extends SceneTree
const Economy = preload("res://scripts/run/economy.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var e := Economy.new()
	e.reset(1)
	e.owned.assign(["RESONANCE","PROFIT","THIRD_EYE","AUDITOR"])
	check(e.max_hp(3)==2 and e.max_hp(1)==1,"profit HP cap")
	e.observe(1,true,2)
	e.observe(1,true,2)
	var prior: Dictionary = e.move_state()
	e.observe(1,true,2)
	check(e.credits==34 and e.earned==4,"resonance")
	e.restore_move(prior)
	check(e.credits==30 and e.resonance_streak==2 and e.earned==0,"resonance rewind")
	e.observe(1,false,2)
	e.observe(1,true,2)
	check(e.credits==30,"damage resets resonance")
	check(e.use_third() and not e.use_third(),"one third eye")
	check(e.use_analyzer() and e.stock==1,"analyzer consumes stock")
	check(e.reward(1,54,0)==67 and e.credits==97,"profit reward floor")
	check(e.reward(1,54,0)==0,"no double reward")
	e.begin_sector(2)
	check(not e.third_used and e.resonance_streak==0,"sector reset")
	var data: Dictionary = e.snapshot()
	var copy := Economy.new()
	copy.restore(data,2,false)
	check(copy.snapshot()==data,"extended state roundtrip")
	for p in range(4):
		var width: int = Profiles.SIZES[p]
		var gen: Dictionary = Profiles.generate(p,1701,0)
		check(not gen.is_empty(),"certified profile")
		if gen.is_empty(): continue
		var board := Board.new(width,width,gen["mask"],Profiles.HP[p])
		board.reveal(0)
		if board.finished(): continue
		var cells: PackedInt32Array = board.cells.duplicate()
		for rule in range(6):
			board.rule = rule
			var ns: Array[int] = Rules.neighbors(width,width,0,rule)
			var mines: int = 0
			for n in ns: mines += board._mask[n]
			check(board.clue(0,rule)==(ns.size()-mines if rule==Rules.Rule.INVERT else mines),"clue truth")
			var snapshot: Dictionary = Store.snapshot(board,p,1701,0)
			var restored: Dictionary = Store.restore(snapshot)
			check(not restored.is_empty() and restored["board"].rule==rule,"all rule save")
			var proof: Dictionary = Tools.analyzer(board,0)
			check(not proof.is_empty() and proof["rule"]!=rule,"additional clue")
			check(board.cells==cells,"analysis nonmutating")
		var group: Dictionary = Tools.third_eye(board,0)
		var total: int = 0
		for i in group["cells"]: total += board._mask[i]
		check(group["cells"].size()==4 and group["value"]==total,"edge group includes center")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui.economy.owned.assign(["PROFIT","THIRD_EYE"])
	ui._apply_hp_cap()
	ui._reveal(0)
	check(ui.board!=null and ui.board.hp==2,"profit cap applied")
	if ui.board!=null and not ui.board.finished():
		for rule in range(1,6):
			ui._cycle_rule()
			check(ui.board.rule==rule,"UI rule cycle")
		ui._cycle_rule()
		check(ui.board.rule==0,"UI cycle returns classic")
		var old: PackedInt32Array = ui.board.cells.duplicate()
		ui._select_inspection("analyzer")
		ui._reveal(0)
		check(ui.economy.stock==1 and not ui.inspect_result.is_empty() and ui.board.cells==old,"analyzer UI consumes once")
		ui._select_inspection("third")
		ui._reveal(0)
		check(ui.economy.third_used and ui.board.cells==old,"third eye UI no reveal")
		ui._begin_protocol()
		ui._process(4.0)
		check(ui.pending_sector and ui.economy.credits==97,"profit K30 shared reward")
		ui._process(2.0)
		check(ui.run_hp==2 and not ui.economy.third_used,"profit next sector and third reset")
	else: check(false,"active UI")
	game.queue_free()
	print("ADVANCED_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
