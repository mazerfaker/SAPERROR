extends RefCounted
## No BoardState, hidden mask, RNG, or flag access. Accepts public observations only.
static func deduce(obs: Dictionary, proven_mines: Array[int]) -> Dictionary:
	var known: Dictionary = {}
	for i in obs["open"]: known[i] = 0
	for i in obs["neutralized"]: known[i] = 1
	for i in proven_mines: known[i] = 1
	var raw: Array = obs["constraints"].duplicate()
	var all_cells: Array[int] = []
	for i in range(int(obs["size"])): all_cells.append(i)
	raw.append({"cells": all_cells, "mines": obs["mine_total"], "source": -1, "rule": -1})
	var constraints: Array[Dictionary] = []
	for c in raw:
		var remaining: int = c["mines"]
		var unknown: Array[int] = []
		for i in c["cells"]:
			if known.has(i): remaining -= int(known[i])
			else: unknown.append(i)
		if remaining < 0 or remaining > unknown.size(): return {"error": "inconsistent observation"}
		if unknown.is_empty(): continue
		var reduced: Dictionary = {"cells": unknown, "mines": remaining, "source": c["source"], "rule": c["rule"]}
		constraints.append(reduced)
		if remaining == 0 or remaining == unknown.size():
			return {"cells": unknown, "mine": remaining != 0, "kind": "direct", "premises": [reduced]}
	for a in constraints:
		for b in constraints:
			var small: Array = a["cells"]
			var large: Array = b["cells"]
			if small.size() >= large.size(): continue
			var subset: bool = true
			for i in small:
				if not large.has(i):
					subset = false
					break
			if not subset: continue
			var diff: Array[int] = []
			for i in large:
				if not small.has(i): diff.append(i)
			var delta: int = int(b["mines"]) - int(a["mines"])
			if delta < 0 or delta > diff.size(): return {"error": "inconsistent subset"}
			if delta == 0 or delta == diff.size():
				return {"cells": diff, "mine": delta != 0, "kind": "subset", "premises": [a, b]}
	return {}
