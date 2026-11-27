extends SceneTree
const Classic = preload("res://scripts/board/classic_game.gd")
const Board = preload("res://scripts/board/state.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const UI = preload("res://scripts/ui/terminal_ui.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model:=Classic.new()
	for profile in range(3):
		for seed_value in range(4):
			model.start(profile,1701+seed_value)
			check(not model.act(0,"flag") and model.board==null,"no flag before first generation")
			check(model.act(0) and model.board!=null,"certified first move")
			if model.board==null: continue
			check(model.board.hp==1 and model.board.rule==0 and not model.board.has_portal(),"one life and classic only")
			model.tick(1.0)
			check(model.elapsed==1.0 or model.board.finished(),"optional timer")
			for step in range(150):
				if model.board.finished(): break
				var proof: Dictionary=Tools.safe_hint(model.board.observation([0]))
				if proof.is_empty(): break
				model.act(int(proof["cell"]))
			check(model.board.won(),"public deductions complete classic")
			var elapsed: float=model.elapsed
			model.tick(10.0)
			check(model.elapsed==elapsed,"finished timer stops")
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(1)
	ui.sector_number=10
	ui.pending_sector=true
	ui._advance_sector()
	check(ui.sector_number==11,"legacy endless preserved")
	ui._start_profile(1,false,true)
	ui.sector_number=10
	ui.pending_sector=true
	ui._advance_sector()
	check(ui.screen=="free_complete" and ui.sector_number==10,"finite run ends at ten")
	var before: Dictionary=ui.economy.snapshot()
	ui._show("classic")
	check(ui.screen=="classic" and ui.economy.snapshot()==before and ui.sector_number==10,"classic does not mutate run")
	ui.queue_free()
	print("CLASSIC_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
