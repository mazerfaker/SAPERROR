extends SceneTree
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Board = preload("res://scripts/board/state.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Store = preload("res://scripts/save/session_store.gd")
const Rules = preload("res://scripts/board/rules.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var found: int = 0
	for p in range(4):
		var w: int = Profiles.SIZES[p]
		for seed_value in range(16):
			var gen: Dictionary = Profiles.generate(p,seed_value,0)
			check(not gen.is_empty(),"certified generation")
			if gen.is_empty(): continue
			var board := Board.new(w,w,gen["mask"],Profiles.HP[p])
			board.reveal(0)
			if board.finished(): continue
			var initial: PackedInt32Array = board.cells.duplicate()
			for rule in [Rules.Rule.CLASSIC,Rules.Rule.CROSS,Rules.Rule.DIAGONAL]:
				board.rule = rule
				var active: Array[int] = [rule]
				var hint: Dictionary = Tools.safe_hint(board.observation(active))
				if not hint.is_empty():
					found += 1
					check(board._mask[hint["cell"]]==0,"public proof safe")
				check(board.cells==initial,"rule and scanner nonmutating")
				var saved: Dictionary = Store.snapshot(board,p,seed_value,0)
				var restored: Dictionary = Store.restore(saved)
				check(not restored.is_empty() and restored["board"].rule==rule,"rule persisted")
			if board.hp>1:
				var prior: Dictionary = Tools.capture(board)
				var mine: int = board._mask.find(1)
				board.reveal(mine)
				check(Tools.restore_action(board,prior) and board.cells==initial and board.hp==Profiles.HP[p] and board.hits==0,"damage rewind")
	check(found>0,"nonvacuous scanner test")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	var ui = game.ui
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.board!=null and not ui.board.finished(),"active standard field")
	check(ui.rewind_data.is_empty(),"first reveal cannot be rewound before generation")
	if ui.board!=null and not ui.board.finished():
		ui._cycle_rule()
		check(ui.board.rule==Rules.Rule.CROSS,"cartridge UI")
		var mine: int = ui.board._mask.find(1)
		var hp: int = ui.board.hp
		ui._reveal(mine)
		check(ui.board.hp==hp-1,"damage")
		ui._rewind()
		check(ui.board.hp==hp and ui.rewinds_left==0,"one charged rewind")
		ui._rewind()
		check(ui.rewinds_left==0,"no repeat charge")
		ui._cycle_rule()
		ui._cycle_rule()
		var before: int = ui.hints_left
		ui._request_hint()
		check(ui.hints_left==before or ui.hints_left==before-1,"scanner charge bounded")
		if ui.hint_cell>=0:
			check(ui.board._mask[ui.hint_cell]==0,"UI hint safe")
			ui._request_hint()
			check(ui.hints_left==before-1,"no duplicate scan")
	game.queue_free()
	print("TOOLS_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
