extends SceneTree
const Board = preload("res://scripts/board/state.gd")
const Parasite = preload("res://scripts/board/parasite.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for p in range(4):
		for seed_value in range(8):
			var g: Dictionary = Profiles.generate(p,seed_value,0)
			check(not g.is_empty(),"certified board")
			if g.is_empty(): continue
			var width: int = Profiles.SIZES[p]
			var b := Board.new(width,width,g["mask"],Profiles.HP[p])
			b.reveal(0)
			if b.finished(): continue
			var a := Parasite.new()
			var prior: Dictionary = b.observation([0])
			check(a.advance(b,false,false)=="" and a.actions==0,"disabled sector")
			a.advance(b,true,false)
			var proof: Dictionary = Tools.safe_hint(prior)
			var event: String = a.advance(b,true,false)
			if proof.is_empty(): 
				check(event=="","no guess")
				continue
			check(event=="warning" and a.cell==proof["cell"] and a.remaining()==3,"public proof and three actions")
			if not a.active(): continue
			var target: int = a.cell
			check(b._mask[target]==0,"safe target")
			a.advance(b,true,false)
			a.advance(b,true,false)
			check(a.remaining()==1 and b.blocked_cell==-1,"warning before lock")
			check(a.advance(b,true,false)=="blocked" and b.blocked_cell==target,"lock after exactly three actions")
			var open_count: int = b.opened
			var hp: int = b.hp
			b.reveal(target)
			b.flag(target)
			check(b.cells[target]==Board.Cell.CLOSED and b.opened==open_count and b.hp==hp,"blocked direct actions")
			check(b.observation([0])==prior,"no changed clues or mine mask")
			var data: Dictionary = Store.snapshot(b,p,seed_value,0)
			data["parasite"] = a.snapshot()
			var restored: Dictionary = Store.restore(data)
			check(not restored.is_empty() and restored["board"].blocked_cell==target and restored["parasite"].snapshot()==a.snapshot(),"blocked save restore")
			var bad: Dictionary = data.duplicate(true)
			bad["parasite"]["cell"] = width*width
			check(Store.restore(bad).is_empty(),"invalid target rejected")
			var stabilizer := Parasite.new()
			check(stabilizer.mark(b,target,true)=="warning" and stabilizer.remaining()==5,"stabilizer adds two actions")
			check(a.cleanse(b,true) and a.hotfix_used and b.blocked_cell==-1 and not a.cleanse(b,true),"hotfix one use")
			b.reveal(target)
			check(b.cells[target]==Board.Cell.OPEN and b.hp==hp,"cleanse restores access")
	# Explicit flood fixture: lock an otherwise flood-reachable safe cell.
	var mask := PackedByteArray([1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1])
	var fixture := Board.new(4,4,mask,3)
	fixture.blocked_cell=10
	fixture.reveal(5)
	fixture.reveal(2)
	check(fixture.cells[10]==Board.Cell.CLOSED,"flood cannot bypass lock")
	fixture.blocked_cell=-1
	fixture.reveal(10)
	check(fixture.cells[10]==Board.Cell.OPEN,"flood target unlocked")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui._reveal(0)
	if ui.board!=null and not ui.board.finished():
		var target: int = -1
		for i in range(ui.board.cells.size()):
			if ui.board.cells[i]==Board.Cell.CLOSED and ui.board._mask[i]==0:
				target=i
				break
		check(target>=0,"UI fixture safe target")
		if target>=0:
			ui.parasite.mark(ui.board,target)
			ui.parasite.actions=ui.parasite.deadline
			ui.board.blocked_cell=target
			ui.economy.stock=0
			ui.economy.owned.clear()
			ui._refresh()
			check(ui.buttons[target].disabled and not ui.cleanse_button.disabled,"emergency cleanse accessible")
			ui._cleanse()
			check(not ui.parasite.active() and ui.board.blocked_cell==-1 and ui.economy.stock==0,"no-resource emergency cleanse")
			# Test the real override with a locked, falsely flagged safe tile.
			ui.parasite = Parasite.new()
			ui.parasite.mark(ui.board,target)
			ui.board.flag(target)
			ui.parasite.actions=ui.parasite.deadline
			ui.board.blocked_cell=target
			ui._begin_protocol()
			ui._process(4.0)
			ui._process(2.0)
			check(ui.sector_number==2 and not ui.parasite.active(),"K30 and sector reset")
	game.queue_free()
	print("PARASITE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
