extends RefCounted
## Pure topology, shared by the board and the public-constraint builder.
enum Rule { CLASSIC, CROSS, DIAGONAL, INVERT, RANGE_II, WRAP }
static func neighbors(w: int, h: int, cell: int, rule: int = Rule.CLASSIC) -> Array[int]:
	var result: Array[int] = []
	var x: int = cell % w
	var y: int = cell / w
	var radius: int = 2 if rule == Rule.RANGE_II else 1
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0: continue
			if rule == Rule.CROSS and dx != 0 and dy != 0: continue
			if rule == Rule.DIAGONAL and (dx == 0 or dy == 0): continue
			var nx: int = x + dx
			var ny: int = y + dy
			if rule == Rule.WRAP:
				nx = posmod(nx, w)
				ny = posmod(ny, h)
			if nx < 0 or nx >= w or ny < 0 or ny >= h: continue
			var id: int = ny * w + nx
			if id != cell and not result.has(id): result.append(id)
	result.sort()
	return result
static func mine_count(display: int, degree: int, rule: int) -> int:
	return degree - display if rule == Rule.INVERT else display
