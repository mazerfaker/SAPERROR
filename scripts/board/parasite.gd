extends RefCounted
# One public, proven-safe target. Blocking changes accessibility, never mines or clues.
const Board = preload("res://scripts/board/state.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
var actions: int = 0
var cell: int = -1
var deadline: int = 0
var resolved: bool = false
var hotfix_used: bool = false
func active() -> bool:
	return cell>=0 and not resolved
func blocked() -> bool:
	return active() and actions>=deadline
func remaining() -> int:
	return maxi(0,deadline-actions)
func advance(board: Board, enabled: bool, stabilizer: bool) -> String:
	if board==null or board.finished() or not enabled or resolved: return ""
	actions += 1
	if active():
		if board.cells[cell]==Board.Cell.OPEN:
			resolved = true
			board.blocked_cell = -1
			return "escaped"
		if actions==deadline:
			board.blocked_cell = cell
			return "blocked"
		return ""
	if actions<2: return ""
	var proof: Dictionary = Tools.safe_hint(board.observation([board.rule]))
	if proof.is_empty(): return ""
	var target: int = proof["cell"]
	if board.cells[target]!=Board.Cell.CLOSED: return ""
	return mark(board,target,stabilizer)
func mark(board: Board, target: int, stabilizer: bool = false) -> String:
	if active() or resolved or board==null or board.finished() or target<0 or target>=board.cells.size(): return ""
	if board.cells[target]!=Board.Cell.CLOSED or board._mask[target]!=0: return ""
	cell = target
	deadline = actions+3+(2 if stabilizer else 0)
	return "warning"
func cleanse(board: Board, use_hotfix: bool = false) -> bool:
	if not active() or (use_hotfix and hotfix_used): return false
	if use_hotfix: hotfix_used = true
	resolved = true
	board.blocked_cell = -1
	return true
func snapshot() -> Dictionary:
	return {"actions":actions,"cell":cell,"deadline":deadline,"resolved":resolved,"hotfix":hotfix_used}
func restore(data: Dictionary, board: Board) -> bool:
	if data.is_empty(): return true
	for key in ["actions","cell","deadline"]:
		if typeof(data.get(key))!=TYPE_INT: return false
	for key in ["resolved","hotfix"]:
		if typeof(data.get(key))!=TYPE_BOOL: return false
	var a: int = data["actions"]
	var i: int = data["cell"]
	var end: int = data["deadline"]
	if a<0 or a>1000000000 or i< -1 or i>=board.cells.size() or end<0 or end>a+5: return false
	if i<0:
		if end!=0 or data["resolved"] or data["hotfix"]: return false
	else:
		if end<3 or board._mask[i]!=0 or (not data["resolved"] and board.cells[i] not in [Board.Cell.CLOSED,Board.Cell.FLAG]): return false
		if data["hotfix"] and not data["resolved"]: return false
	actions=a
	cell=i
	deadline=end
	resolved=data["resolved"]
	hotfix_used=data["hotfix"]
	board.blocked_cell=cell if blocked() else -1
	return true
