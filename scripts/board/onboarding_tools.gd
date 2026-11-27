extends RefCounted
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Solver = preload("res://scripts/solver/solver.gd")
const HINT_LIMITS := [3,1,0,0]
const REWIND_LIMITS := [1,1,0,0]
const NAMES := ["CLASSIC","CROSS","DIAGONAL","INVERT","RANGE II","WRAP"]
static func safe_hint(observation: Dictionary) -> Dictionary:
	var known: Array[int] = []
	var trace: Array[Dictionary] = []
	for _i in range(int(observation["size"])+1):
		var proof: Dictionary = Solver.deduce(observation,known)
		if proof.is_empty() or proof.has("error"): return {}
		trace.append(proof.duplicate(true))
		if not proof["mine"]:
			return {"cell":int(proof["cells"][0]),"trace":trace,"proof":proof}
		var added: bool = false
		for i in proof["cells"]:
			if not known.has(i):
				known.append(i)
				added = true
		if not added: return {}
	return {}
static func capture(board: Board) -> Dictionary:
	if board==null or board.finished(): return {}
	return {"cells":board.cells.duplicate(),"hp":board.hp,"hits":board.hits,"opened":board.opened,"rule":board.rule}
static func restore_action(board: Board, before: Dictionary) -> bool:
	if board==null or before.is_empty() or board.finished(): return false
	if before["cells"].size()!=board.cells.size(): return false
	board.cells = before["cells"].duplicate()
	board.hp = before["hp"]
	board.hits = before["hits"]
	board.opened = before["opened"]
	board.rule = before["rule"]
	return true

# Analyzer reads an additional real clue from an already open cell.
static func analyzer(board: Board, index: int) -> Dictionary:
	if board==null or board.finished() or index<0 or index>=board.cells.size() or board.cells[index]!=Board.Cell.OPEN: return {}
	var rule: int = Rules.Rule.CLASSIC if board.rule!=Rules.Rule.CLASSIC else Rules.Rule.CROSS
	return {"rule":rule,"value":board.clue(index,rule),"cells":Rules.neighbors(board.width,board.height,index,rule)}
# Third Eye reads an explicitly bounded, non-wrapping 3x3 group including its center.
static func third_eye(board: Board, index: int) -> Dictionary:
	if board==null or board.finished() or index<0 or index>=board.cells.size(): return {}
	var cells: Array[int] = Rules.neighbors(board.width,board.height,index,Rules.Rule.CLASSIC)
	cells.append(index)
	cells.sort()
	var count: int = board.count_mines(index,Rules.Rule.CLASSIC)+int(board._mask[index])
	return {"cells":cells,"value":count}
