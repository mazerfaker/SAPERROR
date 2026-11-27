extends RefCounted
const Board = preload("res://scripts/board/state.gd")
const SEQUENCE := [KEY_UP,KEY_UP,KEY_DOWN,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_LEFT,KEY_RIGHT,KEY_B,KEY_A]
var prefix: Array[int] = []
var held: Dictionary = {}
var queue: Array[int] = []
var cursor: int = 0
func reset_input() -> void:
	prefix.clear()
	held.clear()
func feed(event: InputEventKey) -> bool:
	var key: int = event.physical_keycode
	# Some platform/synthetic non-letter events have no physical code.
	# Actual A/B input prefers the physical QWERTY location regardless of locale.
	if key == 0 and event.keycode in SEQUENCE: key = event.keycode
	if not event.pressed:
		held.erase(key)
		return false
	if event.echo or held.has(key): return false
	held[key] = true
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		prefix.clear()
		return false
	prefix.append(key)
	while not prefix.is_empty():
		var matches := true
		for i in range(prefix.size()):
			if prefix[i] != SEQUENCE[i]:
				matches = false
				break
		if matches: break
		prefix.pop_front()
	if prefix.size() == SEQUENCE.size():
		prefix.clear()
		return true
	return false
func prepare(board: Board) -> bool:
	queue.clear()
	cursor = 0
	if board == null or board.finished(): return false
	# Mark all live mines first, before the last safe cell can trigger victory.
	for i in range(board.cells.size()):
		if board._mask[i] == 1 and board.cells[i] == Board.Cell.CLOSED: queue.append(i)
	for i in range(board.cells.size()):
		if board._mask[i] == 0 and board.cells[i] != Board.Cell.OPEN: queue.append(i)
	return not queue.is_empty()
func advance(board: Board, batch: int = 1) -> void:
	for _i in range(maxi(batch,0)):
		if cursor >= queue.size() or board.finished(): return
		var index: int = queue[cursor]
		cursor += 1
		if board._mask[index] == 1:
			if board.cells[index] == Board.Cell.CLOSED: board.flag(index)
		else:
			# Administrator override also bypasses an anomaly-locked safe flag.
			if board.cells[index] == Board.Cell.FLAG: board.cells[index] = Board.Cell.CLOSED
			# Intentional administrator override, not a normal move: exact single-cell
			# reveal (no flood) so each tile can be animated. Never touch a mine,
			# health, hits, resources or normal BoardState methods/solver.
			if board.cells[index] == Board.Cell.CLOSED:
				board.cells[index] = Board.Cell.OPEN
				board.opened += 1
func progress() -> float:
	return float(cursor)/float(maxi(1,queue.size()))
func done() -> bool:
	return cursor >= queue.size()
