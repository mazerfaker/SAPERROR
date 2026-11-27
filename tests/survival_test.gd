extends SceneTree
const Economy = preload("res://scripts/run/economy.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Board = preload("res://scripts/board/state.gd")
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
	check(e.repair(2,3)==3 and e.credits==0,"repair")
	check(e.repair(2,3)==2,"insufficient credits")
	e.credits=100
	check(e.buy_shield() and e.arm_shield(),"buy and arm shield")
	check(not e.arm_shield(),"no duplicate arm")
	e.owned.assign(["SECOND_LIFE","FUSE","AUDITOR","CAPACITOR"])
	check(e.consume_protection()=="SHIELD","shield priority")
	check(e.consume_protection()=="SECOND_LIFE","second life")
	check(not e.can_protect(),"fuse not ready")
	var previous: Dictionary = e.move_state()
	e.observe(15,true)
	check(e.can_protect() and e.credits==88,"fuse and auditor threshold")
	check(e.consume_protection()=="FUSE" and not e.can_protect(),"fuse once")
	e.restore_move(previous)
	check(e.credits==82 and e.auditor_awards==0 and not e.can_protect(),"rewind reward and fuse")
	e.observe(45,true)
	check(e.credits==94 and e.auditor_awards==2,"auditor capped")
	e.begin_sector(2)
	e.credits=500
	var offer: String = e.offers()[0]
	check(e.replace_module("CAPACITOR",offer) and e.owned.size()==4 and not e.owned.has("CAPACITOR") and e.owned.has(offer),"confirmed replacement")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active board")
	if ui.board!=null and not ui.board.finished():
		var mine: int = ui.board._mask.find(1)
		ui._reveal(mine)
		check(ui.run_hp==2,"damage carried in run")
		ui._begin_protocol()
		ui._process(4.0)
		ui._process(2.0)
		check(ui.sector_number==2 and ui.run_hp==2,"K30 preserves damage across sectors")
		ui._show("shop")
		var money: int = ui.economy.credits
		ui._repair()
		check(ui.run_hp==3 and ui.economy.credits==money-30,"shop repair")
		ui._buy_shield()
		check(ui.economy.shield_stock==1,"shop shield")
		ui._show("game")
		ui._reveal(0)
		check(ui.board!=null and ui.board.hp==3,"repaired next sector")
		if ui.board!=null and not ui.board.finished():
			ui._arm_shield()
			mine = ui.board._mask.find(1)
			ui._reveal(mine)
			check(ui.board.hp==3 and ui.board.hits==1 and ui.protected_hits==1 and not ui.economy.shield_armed,"actual protected hit")
			var data: Dictionary = ui._snapshot_board()
			var resumed: Dictionary = Store.restore(data)
			check(not resumed.is_empty() and resumed["board"].hp==3 and resumed["protected_hits"]==1,"protected save restored")
			ui._rewind()
			check(ui.board.hp==3 and ui.board.hits==0 and ui.economy.shield_armed,"protected move rewind")
		else: check(false,"nonvacuous next field")
	# Start a new test run with low carry HP and verify legacy-compatible save validation.
	ui._start_profile(1)
	ui.run_hp=1
	ui._reveal(0)
	check(ui.board.hp==1 and ui.sector_start_hp==1,"low HP start")
	check(not Store.restore(ui._snapshot_board()).is_empty(),"low HP save")
	game.queue_free()
	print("SURVIVAL_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
