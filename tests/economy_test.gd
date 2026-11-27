extends SceneTree
const Economy = preload("res://scripts/run/economy.gd")
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
	check(e.credits==30 and e.stock==2,"standard start")
	check(e.reward(1,54,0)==45 and e.credits==75,"clean reward")
	check(e.reward(1,54,0)==0 and e.credits==75,"no duplicate reward")
	e.begin_sector(2)
	check(e.offers().size()==3,"three offers")
	var first: String = e.offers()[0]
	var before: int = e.credits
	check(e.buy(first) and e.credits==before-e.price(first),"module bought")
	check(not e.buy(first),"no duplicates")
	var snapshot: Dictionary = e.snapshot()
	var restored := Economy.new()
	restored.restore(snapshot,2,false)
	check(restored.snapshot()==snapshot,"economy roundtrip")
	e.credits = 500
	e.owned.assign(["XRAY","CHAIN","CAPACITOR","ASSISTANT"])
	e.stock = 0
	check(not e.buy("CHRONOMANCER"),"module limit")
	e.observe(10,true)
	check(e.stock==2,"combined xray and chain")
	var state: Dictionary = e.move_state()
	e.observe(10,true)
	check(e.stock==4,"second awards")
	e.observe(20,true)
	check(e.stock==4,"sector caps")
	e.restore_move(state)
	check(e.stock==2 and e.xray_awards==1 and e.chain_awards==1,"rewind counters")
	e.observe(10,true)
	check(e.stock==4,"rewind replay no extra stock")
	e.add_stock(100)
	check(e.stock==6 and not e.buy_charge(),"capacity")
	e.begin_sector(3)
	check(e.xray_awards==0 and e.chain_awards==0,"sector counters reset")
	check(e.reward(3,54,1)==35,"damaged reward")
	e.owned.clear()
	e.stock = 0
	before = e.credits
	check(e.buy_charge() and e.stock==1 and e.credits==before-12,"charge purchase")
	before = e.credits
	check(e.reroll() and e.credits==before-8 and e.reroll_price()==12,"reroll")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.economy.credits==30 and ui.economy.stock==2,"UI start")
	if ui.board!=null and not ui.board.finished():
		ui._begin_protocol()
		ui._process(4.0)
		check(ui.pending_sector and ui.economy.credits==75,"shared K30 reward")
		ui._process(2.0)
		check(ui.sector_number==2 and ui._shop_available(),"K30 next sector shop available")
		ui._show("shop")
		check(ui.screen=="shop","shop UI")
		var id: String = ui.economy.offers()[0]
		ui._buy_module(id)
		check(ui.economy.owned.has(id),"UI purchase")
		ui._show("game")
		ui._reveal(0)
		check(not ui._shop_available(),"shop blocked during sector")
	else: check(false,"nonvacuous active field")
	game.queue_free()
	print("ECONOMY_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
