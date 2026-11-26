extends RefCounted
const Rules = preload("res://scripts/board/rules.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Generator = preload("res://scripts/board/generator.gd")
const IDS := ["story","standard","expert","hardcore"]
const SIZES := [6,8,10,10]
const MINES := [4,10,16,20]
const HP := [5,3,2,1]
static func valid(profile: int) -> bool:
	return profile >= 0 and profile < IDS.size()
static func generate(profile: int, seed_value: int, first: int) -> Dictionary:
	if not valid(profile): return {}
	var w: int = SIZES[profile]
	var mines: int = MINES[profile]
	if first < 0 or first >= w*w: return {}
	if profile == 1: return Generator.generate(seed_value,first)
	var safe: Array[int] = Rules.neighbors(w,w,first)
	safe.append(first)
	var allowed: Array[int] = []
	for i in range(w*w):
		if not safe.has(i): allowed.append(i)
	var rules: Array[int] = [Rules.Rule.CLASSIC]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for attempt in range(64):
		var pool: Array[int] = allowed.duplicate()
		var mask := PackedByteArray()
		mask.resize(w*w)
		for j in range(mines):
			var k: int = rng.randi_range(j,pool.size()-1)
			var tmp: int = pool[j]
			pool[j] = pool[k]
			pool[k] = tmp
			mask[pool[j]] = 1
		var cert: Dictionary = Validator.certify(w,w,mask,first,rules)
		if not cert.is_empty(): return {"mask":mask,"certificate":cert,"seed":seed_value,"fallback":false,"attempt":attempt}
	# Bounded deterministic fallback from each edge; never bypass certificate.
	for side in range(4):
		var mask := PackedByteArray()
		mask.resize(w*w)
		var count: int = 0
		for depth in range(w):
			for offset in range(w):
				var i: int = int([depth*w+offset,(w-1-depth)*w+offset,offset*w+depth,offset*w+w-1-depth][side])
				if safe.has(i) or count >= mines: continue
				mask[i] = 1
				count += 1
		if count != mines: continue
		var cert: Dictionary = Validator.certify(w,w,mask,first,rules)
		if not cert.is_empty(): return {"mask":mask,"certificate":cert,"seed":seed_value,"fallback":true,"attempt":64}
	return {}
