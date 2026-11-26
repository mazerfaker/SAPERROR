extends SceneTree
const Rules = preload("res://scripts/board/rules.gd")
const Board = preload("res://scripts/board/state.gd")
const Solver = preload("res://scripts/solver/solver.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Generator = preload("res://scripts/board/generator.gd")
var failures: int = 0
var checks: int = 0
func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(Rules.neighbors(3,3,4).size() == 8, "classic interior")
	check(Rules.neighbors(3,3,0).size() == 3, "classic corner")
	check(Rules.neighbors(3,3,4,Rules.Rule.CROSS).size() == 4, "cross")
	check(Rules.neighbors(3,3,4,Rules.Rule.DIAGONAL).size() == 4, "diagonal")
	check(Rules.neighbors(5,5,12,Rules.Rule.RANGE_II).size() == 24, "range II")
	check(Rules.neighbors(2,2,0,Rules.Rule.WRAP).size() == 3, "wrap unique")
	check(Rules.neighbors(1,1,0,Rules.Rule.WRAP).is_empty(), "wrap excludes self")
	var mask := PackedByteArray([1,1,0,1,0,0,0,0,0])
	var b = Board.new(3,3,mask,3)
	b.reveal(4)
	check(b.clue(4,Rules.Rule.CLASSIC) == 3, "classic count")
	check(b.clue(4,Rules.Rule.CROSS) == 2, "cross count")
	check(b.clue(4,Rules.Rule.DIAGONAL) == 1, "diagonal count")
	check(b.clue(4,Rules.Rule.INVERT) == 5, "invert count")
	b.reveal(0)
	check(b.hp == 2 and b.cells[0] == Board.Cell.NEUTRALIZED, "mine damage")
	b.flag(1)
	b.flag(3)
	b.chord(4)
	check(b.won() and b.hp == 2, "chord counts neutralized, win without flags requirement")
	var c = Board.new(3,3,PackedByteArray([1,0,0,0,0,0,0,0,0]),1)
	c.flag(8)
	c.reveal(7)
	check(c.cells[8] == Board.Cell.FLAG and not c.won(), "flood respects flags")
	c.flag(8)
	c.reveal(8)
	check(c.won(), "win when every safe cell opened")
	var d = Board.new(2,2,PackedByteArray([1,1,1,0]),1)
	d.rule = Rules.Rule.INVERT
	d.reveal(3)
	check(d.clue(3,d.rule) == 0 and d.hp == 1 and d.opened == 1, "invert zero not flood")
	var e = Board.new(2,2,PackedByteArray([1,0,0,0]),1)
	e.reveal(0)
	check(e.finished() and not e.won() and e.hp == 0, "loss")
	var obs: Dictionary = {"size": 4, "mine_total": 2, "open": [], "neutralized": [], "constraints": [{"cells":[0,1],"mines":1,"source":10,"rule":0},{"cells":[0,1,2],"mines":1,"source":11,"rule":0}]}
	var known: Array[int] = []
	var proof: Dictionary = Solver.deduce(obs,known)
	check(proof.get("kind") == "subset" and proof.get("cells") == [2] and not proof.get("mine"), "public subset proof")
	var rules: Array[int] = [Rules.Rule.CLASSIC]
	var fallback_count: int = 0
	for seed_value in range(1000):
		var first: int = (seed_value * 37) % 64
		var gen: Dictionary = Generator.generate(seed_value,first)
		check(not gen.is_empty(), "generated seed %d" % seed_value)
		if gen.is_empty(): continue
		var truth: PackedByteArray = gen["mask"]
		var sum: int = 0
		for bit in truth: sum += bit
		check(sum == 10 and truth[first] == 0, "density and safe first")
		var zero: bool = true
		for n in Rules.neighbors(8,8,first):
			if truth[n] != 0: zero = false
		check(zero, "safe 3x3")
		check(Validator.certify(8,8,truth,first,rules) == gen["certificate"], "certificate replay")
		if gen["fallback"]: fallback_count += 1
		if seed_value % 25 == 0:
			check(Generator.generate(seed_value,first) == gen, "determinism")
	print("CORE_QA checks=",checks," failures=",failures," seeds=1000 fallback=",fallback_count)
	quit(0 if failures == 0 else 1)
