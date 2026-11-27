extends SceneTree
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
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
	var b := Board.new(4,4,PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]),3)
	check(b.configure_portal(0,15),"configure")
	b.reveal(0)
	check(b.clue(0,0)==1 and b.opened==1,"portal affects clue and flood")
	check(b.neighbors(0,0).has(15) and b.neighbors(15,0).has(0),"bidirectional")
	check(b.neighbors(0,Rules.Rule.WRAP).size()==8,"duplicate edge removed")
	b.flag(15)
	b.chord(0)
	check(b.hp==3 and b.cells[15]==Board.Cell.FLAG,"chord uses same topology")
	b.portal_enabled=false
	check(b.clue(0,0)==0,"classic fallback")
	for p in range(4):
		var g: Dictionary = Profiles.generate(p,1701,0)
		if g.is_empty(): continue
		var width: int = Profiles.SIZES[p]
		var board := Board.new(width,width,g["mask"],Profiles.HP[p])
		board.reveal(0)
		if board.finished(): continue
		var obs: Dictionary = board.observation([0])
		board.configure_portal(0,width*width-1)
		var saved: Dictionary = Store.snapshot(board,p,1701,0)
		var restored: Dictionary = Store.restore(saved)
		check(not restored.is_empty() and restored["board"].portal_enabled,"save link")
		board.portal_enabled=false
		check(board.observation([0])==obs,"classic evidence restored")
		check(not board.configure_portal(0,0),"reject self link")
	print("PORTAL_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
