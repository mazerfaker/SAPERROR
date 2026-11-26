extends SceneTree
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Board = preload("res://scripts/board/state.gd")
const Tutorial = preload("res://scripts/ui/tutorial.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	create_timer(120.0).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	for p in range(4):
		var w: int = Profiles.SIZES[p]
		for seed_value in range(12):
			var first: int = (seed_value*17)%(w*w)
			var gen: Dictionary = Profiles.generate(p,seed_value,first)
			check(not gen.is_empty(),"certified profile %d seed %d" % [p,seed_value])
			if gen.is_empty(): continue
			var board := Board.new(w,w,gen["mask"],Profiles.HP[p])
			board.reveal(first)
			check(board.mine_total==Profiles.MINES[p] and board.hits==0,"density and safe start")
			if not board.finished():
				var data: Dictionary = Store.snapshot(board,p,seed_value,first)
				var restored: Dictionary = Store.restore(data)
				check(not restored.is_empty(),"resume validated")
				if not restored.is_empty():
					var resumed: Board = restored["board"]
					check(resumed.cells==board.cells and resumed.hp==board.hp,"resume state")
				data["hp"] = 99
				check(Store.restore(data).is_empty(),"invalid HP rejected")
	var cfg := ConfigFile.new()
	cfg.set_value("settings","crt",0.25)
	var path := "user://onboarding_qa.cfg"
	check(Store.write_config(cfg,path)==OK,"config write")
	check(Store.load_config(path).get_value("settings","crt",0.0)==0.25,"config reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var tutorial := Tutorial.new()
	tutorial.size = Vector2(1266,710)
	root.add_child(tutorial)
	tutorial._action(1,"reveal")
	check(tutorial.solved,"lesson 1")
	tutorial._next()
	tutorial._action(1,"reveal")
	check(tutorial.solved,"lesson 2")
	tutorial._next()
	tutorial._action(0,"flag")
	tutorial._action(0,"flag")
	check(tutorial.solved,"lesson 3")
	tutorial._next()
	tutorial._action(0,"flag")
	check(tutorial.solved,"lesson 4")
	tutorial._next()
	tutorial._action(4,"chord")
	tutorial._action(8,"reveal")
	check(tutorial.solved,"lesson 5")
	tutorial.queue_free()
	print("ONBOARDING_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
