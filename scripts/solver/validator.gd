extends RefCounted
const Board = preload("res://scripts/board/state.gd")
const Solver = preload("res://scripts/solver/solver.gd")
## Truth is confined to this validation boundary, never fed to deduce().
static func certify(w: int, h: int, mask: PackedByteArray, first: int, rules: Array[int]) -> Dictionary:
	if first < 0 or first >= mask.size() or mask[first] != 0: return {}
	var board = Board.new(w, h, mask, 1)
	var known: Array[int] = []
	var steps: Array[Dictionary] = []
	board.reveal(first)
	for _step in range(w * h):
		if board.won(): return {"first": first, "rules": rules.duplicate(), "steps": steps}
		var proof: Dictionary = Solver.deduce(board.observation(rules), known)
		if proof.is_empty() or proof.has("error"): return {}
		for i in proof["cells"]:
			if bool(mask[i]) != bool(proof["mine"]): return {}
			if proof["mine"]: known.append(i)
			else: board.reveal(i)
		steps.append(proof)
	return {"first": first, "rules": rules.duplicate(), "steps": steps} if board.won() else {}
