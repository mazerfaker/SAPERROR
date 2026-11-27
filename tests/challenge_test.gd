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
	check(model.start("DOUBLE"),"two certified authored boards")
	if model.valid:
		check(model.boards.size()==2 and model.certificates.size()==2,"independent certificates")
		var a: Board=model.board()
		var before: PackedInt32Array=a.cells.duplicate()
		model.switch_layer()
		check(model.active_layer==1 and model.board()!=a,"layer switch")
		check(model.marker(13)=="PARALLEL" and model.details().contains("A#12"),"explicit links")
		model.act(0,true)
		check(a.cells==before,"other layer unchanged")
		model.switch_layer()
		check(model.active_layer==0 and model.board()==a,"return to layer A")
	check(model.start("WATCHER"),"WATCHER certificate")
	if model.valid:
		check(model.watcher_groups.size()==3 and model.watcher_log.size()==6,"three marked groups")
		var target: int=int(model.watcher_groups[0][0])
		var recorded: int=model.watcher_log[target]
		for i in range(5): model.act(0,true)
		check(model.watcher_closed and model.hidden(target),"groups close after five moves")
		model.toggle_journal()
		check(model.journal_open and model.watcher_log[target]==recorded and model.details().contains("#%d=%d" % [target+1,recorded]),"truth preserved in journal")
		check(model.board().clue(target,0)==recorded,"no false ordinary clue")
	check(model.start("LIAR"),"LIAR certificate")
	if model.valid:
		var decoded: Array[int]=model.decoded_sensors()
		var wrong: int=0
		for i in range(3):
			var truth: int=0
			for column in range(Challenge.SIZE): truth+=int(model.board()._mask[int(Challenge.LIAR_ROWS[i])*Challenge.SIZE+column])
			check(decoded[i]==truth,"checksum resolves true row count")
			if model.sensor_values[i]!=decoded[i]: wrong+=1
		check(wrong==1,"exactly one false special sensor")
		check(not model.submit_sensor(0) and not model.liar_solved,"wrong sensor rejected")
		check(model.submit_sensor(1) and model.liar_solved,"correct sensor decoded")
		check(not model.won(),"sensor alone is not victory")
	print("CHALLENGE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
