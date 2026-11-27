extends RefCounted
const Rules = preload("res://scripts/board/rules.gd")
enum Cell { CLOSED, OPEN, FLAG, NEUTRALIZED }
var width: int
var height: int
var mine_total: int
var hp: int
var rule: int = Rules.Rule.CLASSIC
var cells: PackedInt32Array
var _mask: PackedByteArray
var opened: int = 0
var hits: int = 0
# Temporary access lock, not a new Cell state. Normal boards always use -1.
var blocked_cell: int = -1
var portal_pair := Vector2i(-1,-1)
var portal_enabled: bool = false
func has_portal() -> bool:
	return portal_pair.x>=0 and portal_pair.y>=0
func configure_portal(a: int, b: int, active: bool = true) -> bool:
	if a<0 or b<0 or a>=cells.size() or b>=cells.size() or a==b: return false
	portal_pair = Vector2i(mini(a,b),maxi(a,b))
	portal_enabled = active
	return true
func neighbors(i: int, r: int) -> Array[int]:
	var ns: Array[int] = Rules.neighbors(width,height,i,r)
	if portal_enabled and has_portal():
		var peer: int = portal_pair.y if i==portal_pair.x else (portal_pair.x if i==portal_pair.y else -1)
		if peer>=0 and not ns.has(peer):
			ns.append(peer)
			ns.sort()
	return ns
func _init(w: int, h: int, mask: PackedByteArray, integrity: int = 3) -> void:
	assert(w > 0 and h > 0 and mask.size() == w * h)
	width = w
	height = h
	_mask = mask.duplicate()
	for bit in _mask: mine_total += bit
	cells.resize(w * h)
	hp = integrity
func won() -> bool:
	return hp > 0 and opened == cells.size() - mine_total
func finished() -> bool:
	return hp <= 0 or won()
func count_mines(i: int, r: int) -> int:
	var total: int = 0
	for n in neighbors(i, r): total += _mask[n]
	return total
func clue(i: int, r: int) -> int:
	assert(cells[i] == Cell.OPEN)
	var count: int = count_mines(i, r)
	return neighbors(i, r).size() - count if r == Rules.Rule.INVERT else count
func flag(i: int) -> void:
	if finished() or i < 0 or i >= cells.size() or i==blocked_cell: return
	if cells[i] == Cell.CLOSED: cells[i] = Cell.FLAG
	elif cells[i] == Cell.FLAG: cells[i] = Cell.CLOSED
func reveal(i: int) -> void:
	if finished() or i < 0 or i >= cells.size() or cells[i] != Cell.CLOSED or i==blocked_cell: return
	if _mask[i] == 1:
		cells[i] = Cell.NEUTRALIZED
		hp -= 1
		hits += 1
		return
	var queue: Array[int] = [i]
	var cursor: int = 0
	while cursor < queue.size():
		var c: int = queue[cursor]
		cursor += 1
		if cells[c] != Cell.CLOSED or c==blocked_cell: continue
		assert(_mask[c] == 0)
		cells[c] = Cell.OPEN
		opened += 1
		if count_mines(c, rule) == 0:
			for n in neighbors(c, rule):
				if cells[n] == Cell.CLOSED: queue.append(n)
func chord(i: int) -> void:
	if finished() or i < 0 or i >= cells.size() or cells[i] != Cell.OPEN: return
	var ns: Array[int] = neighbors(i, rule)
	var marks: int = 0
	for n in ns:
		if cells[n] == Cell.FLAG or cells[n] == Cell.NEUTRALIZED: marks += 1
	if marks != Rules.mine_count(clue(i, rule), ns.size(), rule): return
	for n in ns:
		if finished(): break
		reveal(n)
## Only public clues are returned; flags remain untrusted unknowns.
func observation(rules: Array[int]) -> Dictionary:
	var open_ids: Array[int] = []
	var neutralized: Array[int] = []
	var constraints: Array[Dictionary] = []
	for i in range(cells.size()):
		if cells[i] == Cell.OPEN:
			open_ids.append(i)
			for r in rules:
				var ns: Array[int] = neighbors(i, r)
				constraints.append({"cells": ns, "mines": Rules.mine_count(clue(i, r), ns.size(), r), "source": i, "rule": r})
		elif cells[i] == Cell.NEUTRALIZED: neutralized.append(i)
	return {"size": cells.size(), "mine_total": mine_total, "open": open_ids, "neutralized": neutralized, "constraints": constraints}
