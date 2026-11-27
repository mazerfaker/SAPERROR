extends RefCounted
# PHANTOM only hides a previously visible clue. The board, mine mask and topology
# are not modified. A free journal always exposes exactly the recorded evidence.
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const TRIGGER_ACTION := 3
const DURATION := 3
var actions: int = 0
var triggered: bool = false
var cell: int = -1
var rule: int = 0
var value: int = 0
var until_action: int = 0
var shielded: bool = false
var hotfix_used: bool = false
func active() -> bool:
	return cell>=0 and actions<until_action
func hidden(index: int, current_rule: int) -> bool:
	return active() and index==cell and current_rule==rule
func advance(board: Board, enabled: bool, shielding: bool) -> String:
	if board==null or board.finished() or not enabled: return ""
	actions += 1
	if active(): return ""
	if triggered:
		return "expired" if cell>=0 and actions==until_action else ""
	if actions<TRIGGER_ACTION: return ""
	for i in range(board.cells.size()):
		if board.cells[i]==Board.Cell.OPEN and board.clue(i,board.rule)>0:
			return trigger(board,i,shielding)
	return ""
func trigger(board: Board, index: int, shielding: bool = false) -> String:
	if triggered or board==null or board.finished() or index<0 or index>=board.cells.size() or board.cells[index]!=Board.Cell.OPEN: return ""
	triggered = true
	if shielding:
		shielded = true
		return "shielded"
	cell = index
	rule = board.rule
	value = board.clue(cell,rule)
	until_action = actions+DURATION
	return "hidden"
func clear_zone(free_hotfix: bool = false) -> bool:
	if not active() or (free_hotfix and hotfix_used): return false
	if free_hotfix: hotfix_used = true
	until_action = actions
	return true
func snapshot() -> Dictionary:
	return {"actions":actions,"triggered":triggered,"cell":cell,"rule":rule,"value":value,"until":until_action,"shielded":shielded,"hotfix":hotfix_used}
func restore(data: Dictionary, board: Board) -> bool:
	if data.is_empty(): return true
	for key in ["actions","cell","rule","value","until"]:
		if typeof(data.get(key))!=TYPE_INT: return false
	for key in ["triggered","shielded","hotfix"]:
		if typeof(data.get(key))!=TYPE_BOOL: return false
	var a: int = data["actions"]
	var i: int = data["cell"]
	var r: int = data["rule"]
	var v: int = data["value"]
	var until: int = data["until"]
	if a<0 or a>1000000000 or i< -1 or i>=board.cells.size() or r<0 or r>5 or until<0 or until>a+DURATION: return false
	if i>=0:
		if not data["triggered"] or data["shielded"] or board.cells[i]!=Board.Cell.OPEN or v!=board.clue(i,r): return false
	elif until!=0 or v!=0 or data["hotfix"] or data["triggered"]!=data["shielded"]: return false
	actions=a
	triggered=data["triggered"]
	cell=i
	rule=r
	value=v
	until_action=until
	shielded=data["shielded"]
	hotfix_used=data["hotfix"]
	return true
