extends RefCounted
const Profiles = preload("res://scripts/board/profiles.gd")
const Board = preload("res://scripts/board/state.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Rules = preload("res://scripts/board/rules.gd")
const PATH := "user://saperror_session.cfg"
const VERSION := 1
static func load_config(path: String = PATH) -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or cfg.get_value("meta","version",0) != VERSION:
		cfg.clear()
	return cfg
static func write_config(cfg: ConfigFile, path: String = PATH) -> Error:
	cfg.set_value("meta","version",VERSION)
	return cfg.save(path)
static func snapshot(board: Board, profile: int, seed_value: int, first: int, start_hp: int = -1, protected_hits: int = 0) -> Dictionary:
	if board == null or board.finished(): return {}
	return {"profile":profile,"seed":seed_value,"first":first,"mask":board._mask.duplicate(),"cells":board.cells.duplicate(),"hp":board.hp,"rule":board.rule,"start_hp":Profiles.HP[profile] if start_hp<0 else start_hp,"protected_hits":protected_hits}
static func restore(data: Dictionary) -> Dictionary:
	for key in ["profile","seed","first","mask","cells","hp"]:
		if not data.has(key): return {}
	if typeof(data["profile"]) != TYPE_INT or typeof(data["seed"]) != TYPE_INT or typeof(data["first"]) != TYPE_INT or typeof(data["hp"]) != TYPE_INT: return {}
	if typeof(data["mask"]) != TYPE_PACKED_BYTE_ARRAY or typeof(data["cells"]) != TYPE_PACKED_INT32_ARRAY: return {}
	var rule: Variant = data.get("rule",Rules.Rule.CLASSIC)
	if typeof(rule)!=TYPE_INT or rule not in [Rules.Rule.CLASSIC,Rules.Rule.CROSS,Rules.Rule.DIAGONAL,Rules.Rule.INVERT,Rules.Rule.RANGE_II,Rules.Rule.WRAP]: return {}
	var profile: int = data["profile"]
	if not Profiles.valid(profile): return {}
	var w: int = Profiles.SIZES[profile]
	var mask: PackedByteArray = data["mask"]
	var cells: PackedInt32Array = data["cells"]
	var first: int = data["first"]
	var hp: int = data["hp"]
	if mask.size()!=w*w or cells.size()!=w*w or first<0 or first>=w*w: return {}
	if hp<=0 or hp>Profiles.HP[profile]: return {}
	var start_hp: Variant = data.get("start_hp",Profiles.HP[profile])
	var protected_hits: Variant = data.get("protected_hits",0)
	if typeof(start_hp)!=TYPE_INT or typeof(protected_hits)!=TYPE_INT or start_hp<1 or start_hp>Profiles.HP[profile] or protected_hits<0: return {}
	var mines: int = 0
	var opened: int = 0
	var hits: int = 0
	for i in range(mask.size()):
		if mask[i]>1 or cells[i]<Board.Cell.CLOSED or cells[i]>Board.Cell.NEUTRALIZED: return {}
		mines += mask[i]
		if cells[i] == Board.Cell.OPEN:
			if mask[i]!=0: return {}
			opened += 1
		elif cells[i] == Board.Cell.NEUTRALIZED:
			if mask[i]!=1: return {}
			hits += 1
	if mines!=Profiles.MINES[profile] or protected_hits>hits or hp!=start_hp-hits+protected_hits or cells[first]!=Board.Cell.OPEN: return {}
	for i in Rules.neighbors(w,w,first):
		if mask[i]!=0: return {}
	var rules: Array[int] = [Rules.Rule.CLASSIC]
	var proof: Dictionary = Validator.certify(w,w,mask,first,rules)
	if proof.is_empty(): return {}
	var board := Board.new(w,w,mask,hp)
	board.rule = int(rule)
	board.cells = cells.duplicate()
	board.opened = opened
	board.hits = hits
	if board.finished(): return {}
	return {"board":board,"profile":profile,"seed":data["seed"],"first":first,"certificate":proof,"start_hp":start_hp,"protected_hits":protected_hits}
