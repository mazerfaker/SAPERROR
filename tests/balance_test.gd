extends SceneTree
const Profiles=preload("res://scripts/board/profiles.gd")
const Economy=preload("res://scripts/run/economy.gd")
const Tools=preload("res://scripts/board/onboarding_tools.gd")
const Board=preload("res://scripts/board/state.gd")
const Challenge=preload("res://scripts/board/anomaly_challenge.gd")
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
	for difficulty in range(4):
		var economy:=Economy.new()
		economy.reset(difficulty)
		check(economy.credits==Economy.START_CREDITS[difficulty] and economy.stock==Economy.START_STOCK[difficulty],"start resources")
		var width: int=Profiles.SIZES[difficulty]
		var safe_count: int=width*width-Profiles.MINES[difficulty]
		var expected: int=25+safe_count/5+10
		var prior: int=economy.credits
		check(economy.reward(1,safe_count,0)==expected and economy.credits==prior+expected,"clean reward")
		check(economy.reward(1,safe_count,0)==0,"no duplicate sector payment")
		economy.begin_sector(2)
		economy.owned.assign(["PROFIT"])
		check(economy.reward(2,safe_count,0)==(expected*5/4 if difficulty==3 else expected*3/2),"profile profit bonus")
		economy.owned.clear()
		var hp: int=Profiles.HP[difficulty]
		prior=economy.credits
		if hp>1:
			check(economy.repair(hp-1,hp)==hp and economy.credits==prior-economy.repair_price(),"repair price and integrity")
		else: check(economy.repair(1,1)==1 and economy.credits==prior,"hardcore no unnecessary repair")
		var trial:=Challenge.new()
		check(trial.start("DOUBLE",hp) and trial.boards[0].hp==hp and trial.boards[1].hp==hp,"both encounter layers use profile HP")
		check(trial.start("LOOP") and trial.board().hp==3,"lab default unchanged")
		var fallback: int=0
		var proof_steps: int=0
		var opened_on_first: int=0
		var generation_usec: int=0
		for seed_index in range(16):
			var seed_value: int=5000+seed_index
			var first: int=[0,width/2,width*width/2,width*width-1][seed_index%4]
			var start: int=Time.get_ticks_usec()
			var generated: Dictionary=Profiles.generate(difficulty,seed_value,first)
			generation_usec+=Time.get_ticks_usec()-start
			check(not generated.is_empty(),"generated certified profile "+str(difficulty))
			if generated.is_empty(): continue
			if generated.get("fallback",false): fallback+=1
			proof_steps+=generated["certificate"]["steps"].size()
			var board:=Board.new(width,width,generated["mask"],hp)
			board.reveal(first)
			opened_on_first+=board.opened
			check(board.hits==0 and board.mine_total==Profiles.MINES[difficulty],"safe initial reveal")
			for step in range(width*width):
				if board.finished(): break
				var proof: Dictionary=Tools.safe_hint(board.observation([0]))
				if proof.is_empty(): break
				board.reveal(int(proof["cell"]))
			check(board.won() and board.hp==hp,"public proof route, no damage")
		print("BALANCE_PROFILE id=",Profiles.IDS[difficulty]," seeds=16 fallback=",fallback," avg_proof_steps=",float(proof_steps)/16.0," avg_first_open=",float(opened_on_first)/16.0," avg_generation_ms=",float(generation_usec)/16000.0," clean_reward=",expected)
	for difficulty in range(4):
		var compact:=Economy.new()
		compact.reset(difficulty)
		compact.streamlined=true
		compact.compact=true
		compact.stock=0
		compact.begin_sector(2)
		compact.replenish_campaign_stock()
		check(compact.stock==(1 if difficulty<=1 else 0),"compact reserve charge")
		check(compact.repair_price()==Economy.COMPACT_REPAIR_COST[difficulty],"compact repair cost")
		var available: Array[String]=[]
		for sector in [2,4,7,8]:
			compact.begin_sector(sector)
			for id in compact.offers():
				if not available.has(id): available.append(id)
		check(available.size()==6,"all compact modules offered across the four shops")
		compact.begin_sector(3)
		var prior_credits: int=compact.credits
		check(compact.boss_reward(3)==40 and compact.credits==prior_credits+40,"fixed boss reward")
		check(compact.boss_reward(3)==0,"no duplicate boss reward")
		var snapshot: Dictionary=compact.snapshot()
		var resumed:=Economy.new()
		resumed.reset(difficulty)
		resumed.streamlined=true
		resumed.compact=true
		resumed.restore(snapshot,3,true)
		check(resumed.boss_reward(3)==0 and resumed.snapshot()==snapshot,"boss reward persisted")
		compact.reset(difficulty)
		check(not compact.compact and compact.repair_price()==Economy.REPAIR_COST[difficulty],"legacy reset")
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(0,true)
	ui.campaign.acknowledge(1)
	ui.pending_sector=true
	ui._advance_sector()
	check(ui.sector_number==2 and int(ui.act_checkpoint.get("sector",0))==2,"story captures every sector")
	ui._show("shop")
	var offer: String=ui.economy.offers()[0]
	ui._buy_module(offer)
	check(ui.economy.owned.has(offer),"story shop purchase")
	ui._show("game")
	ui._reveal(0)
	check(ui.board!=null and int(ui.act_checkpoint.get("sector",0))==2,"story first move checkpoint")
	var credits: int=ui.economy.credits
	ui.economy.credits+=100
	ui.campaign_failed=true
	ui._retry_checkpoint()
	check(ui.sector_number==2 and ui.economy.credits==credits and ui.economy.owned.has(offer),"story retry preserves purchased loadout, no credit exploit")
	ui.queue_free()
	print("BALANCE_QA checks=",checks," failures=",failures," profiles=4 seeds=64")
	quit(0 if failures==0 else 1)
