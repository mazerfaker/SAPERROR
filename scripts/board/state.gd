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
	for n in Rules.neighbors(width, height, i, r): total += _mask[n]
	return total
func clue(i: int, r: int) -> int:
	assert(cells[i] == Cell.OPEN)
	var count: int = count_mines(i, r)
	return Rules.neighbors(width, height, i, r).size() - count if r == Rules.Rule.INVERT else count
func flag(i: int) -> void:
	if finished() or i < 0 or i >= cells.size(): return
	if cells[i] == Cell.CLOSED: cells[i] = Cell.FLAG
	elif cells[i] == Cell.FLAG: cells[i] = Cell.CLOSED
func reveal(i: int) -> void:
	if finished() or i < 0 or i >= cells.size() or cells[i] != Cell.CLOSED: return
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
		if cells[c] != Cell.CLOSED: continue
		assert(_mask[c] == 0)
		cells[c] = Cell.OPEN
		opened += 1
		if count_mines(c, rule) == 0:
			for n in Rules.neighbors(width, height, c, rule):
				if cells[n] == Cell.CLOSED: queue.append(n)
func chord(i: int) -> void:
	if finished() or i < 0 or i >= cells.size() or cells[i] != Cell.OPEN: return
	var ns: Array[int] = Rules.neighbors(width, height, i, rule)
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
				var ns: Array[int] = Rules.neighbors(width, height, i, r)
				constraints.append({"cells": ns, "mines": Rules.mine_count(clue(i, r), ns.size(), r), "source": i, "rule": r})
		elif cells[i] == Cell.NEUTRALIZED: neutralized.append(i)
	return {"size": cells.size(), "mine_total": mine_total, "open": open_ids, "neutralized": neutralized, "constraints": constraints}
