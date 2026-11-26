extends RefCounted
const Rules = preload("res://scripts/board/rules.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const MAX_ATTEMPTS: int = 64
## Initial supported profile: 8x8, 10 mines, CLASSIC. Other profiles must earn QA.
static func generate(seed_value: int, first: int) -> Dictionary:
	if first < 0 or first >= 64: return {}
	var safe: Array[int] = Rules.neighbors(8, 8, first)
	safe.append(first)
	var allowed: Array[int] = []
	for i in range(64):
		if not safe.has(i): allowed.append(i)
	var rules: Array[int] = [Rules.Rule.CLASSIC]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for attempt in range(MAX_ATTEMPTS):
		var pool: Array[int] = allowed.duplicate()
		var mask := PackedByteArray()
		mask.resize(64)
		for j in range(10):
			var k: int = rng.randi_range(j, pool.size() - 1)
			var temp: int = pool[j]
			pool[j] = pool[k]
			pool[k] = temp
			mask[pool[j]] = 1
		var proof: Dictionary = Validator.certify(8, 8, mask, first, rules)
		if not proof.is_empty(): return {"mask": mask, "certificate": proof, "attempt": attempt, "seed": seed_value, "fallback": false}
	# Deterministic authored-pattern candidates: full edge + two adjacent cells.
	# Never accept a fallback unless the same public solver certifies it for this click.
	for side in range(4):
		for offset in range(7):
			var mask := PackedByteArray()
			mask.resize(64)
			var positions: Array[int] = []
			for j in range(8):
				positions.append([j, 56+j, j*8, j*8+7][side])
			for j in range(offset, offset+2):
				positions.append([8+j, 48+j, j*8+1, j*8+6][side])
			var valid: bool = true
			for i in positions:
				if safe.has(i): valid = false
				mask[i] = 1
			if not valid: continue
			var proof: Dictionary = Validator.certify(8, 8, mask, first, rules)
			if not proof.is_empty(): return {"mask": mask, "certificate": proof, "attempt": MAX_ATTEMPTS, "seed": seed_value, "fallback": true}
	return {} # fail closed; UI never starts uncertified boards
