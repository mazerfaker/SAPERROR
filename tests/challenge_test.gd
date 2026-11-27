extends SceneTree
const Challenge = preload("res://scripts/board/anomaly_challenge.gd")
const Board = preload("res://scripts/board/state.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model := Challenge.new()
	check(model.start("LOOP"),"authored LOOP certificate")
	if model.valid:
		var b: Board=model.board()
		var hp: int=b.hp
		model.act(0,true)
		model.act(1,true)
		model.act(2,true)
		check(model.loop_done and model.actions==3 and b.cells[0]==model.checkpoint[0] and b.cells[1]==model.checkpoint[1],"local flag reset on third move")
		check(b.hp==hp and b._mask==model.make_mask(Challenge.MASK_A),"no health or mine reset")
		model.act(0,true)
		check(b.cells[0]==Board.Cell.FLAG,"one-shot reset")
		check(model.start("LOOP") and not model.loop_done and model.actions==0,"clean retry")
	print("CHALLENGE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
