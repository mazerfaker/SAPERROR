extends SceneTree
const Phantom = preload("res://scripts/board/phantom.gd")
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
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
		var width: int = Profiles.SIZES[p]
		for seed_value in range(8):
			var gen: Dictionary = Profiles.generate(p,seed_value,0)
			check(not gen.is_empty(),"certified board")
			if gen.is_empty(): continue
			var b := Board.new(width,width,gen["mask"],Profiles.HP[p])
			b.reveal(0)
			if b.finished(): continue
			var a := Phantom.new()
			var before: PackedInt32Array = b.cells.duplicate()
			var obs: Dictionary = b.observation([0])
			check(a.advance(b,false,false)=="" and a.actions==0,"disabled sectors unchanged")
			a.advance(b,true,false)
			a.advance(b,true,false)
			check(not a.active(),"warning delay")
			var event: String = a.advance(b,true,false)
			check(event=="hidden" and a.active(),"third action hides known clue")
			if not a.active(): continue
			check(a.value==b.clue(a.cell,a.rule) and a.hidden(a.cell,a.rule),"journal truthful")
			check(not a.hidden(a.cell,Rules.Rule.CROSS),"other cartridge unaffected")
			check(b.cells==before and b.observation([0])==obs,"public evidence available through free journal")
			var saved: Dictionary = Store.snapshot(b,p,seed_value,0)
			saved["phantom"] = a.snapshot()
			var restored: Dictionary = Store.restore(saved)
			check(not restored.is_empty() and restored["phantom"].snapshot()==a.snapshot(),"save and rewind state")
			var bad: Dictionary = saved.duplicate(true)
			bad["phantom"]["value"] = 99
			check(Store.restore(bad).is_empty(),"invalid clue rejected")
			var shield := Phantom.new()
			check(shield.trigger(b,a.cell,true)=="shielded" and not shield.active(),"shielding")
			var hotfix := Phantom.new()
			hotfix.trigger(b,a.cell)
			check(hotfix.clear_zone(true) and hotfix.hotfix_used and not hotfix.clear_zone(true),"hotfix once")
			a.advance(b,true,false)
			a.advance(b,true,false)
			check(a.active(),"temporary concealment")
			check(a.advance(b,true,false)=="expired" and not a.active(),"expiry")
			check(a.advance(b,true,false)=="" and not a.active(),"no duplicate episode")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active scene")
	if ui.board!=null and not ui.board.finished():
		var index: int = -1
		for i in range(ui.board.cells.size()):
			if ui.board.cells[i]==Board.Cell.OPEN and ui.board.clue(i,0)>0:
				index=i
				break
		check(index>=0,"open clue")
		if index>=0:
			ui.phantom.trigger(ui.board,index)
			ui._refresh()
			check(ui.buttons[index].text=="?","no hidden number in tile")
			var stock: int = ui.economy.stock
			ui._open_journal()
			check(not ui.inspect_result.is_empty() and ui.economy.stock==stock,"free journal")
			ui.economy.owned.assign(["HOTFIX"])
			ui._cleanse()
			check(not ui.phantom.active() and ui.economy.stock==stock and ui.phantom.hotfix_used,"free cleanse")
			check(ui.buttons[index].text==str(ui.board.clue(index,0)),"clue restored")
			ui._begin_protocol()
			ui._process(4.0)
			ui._process(2.0)
			check(ui.sector_number==2 and not ui.phantom.triggered,"K30 progression and reset")
	game.queue_free()
	print("PHANTOM_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
