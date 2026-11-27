extends RefCounted
const Profiles = preload("res://scripts/board/profiles.gd")
const Board = preload("res://scripts/board/state.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Phantom = preload("res://scripts/board/phantom.gd")
const Parasite = preload("res://scripts/board/parasite.gd")
const PATH := "user://saperror_session.cfg"
const VERSION := 1
const SEAL := "; SAPERROR-SHA256 "
const MAX_BYTES := 4*1024*1024
# Seal covers exact UTF-8 payload, not a reserialized ConfigFile.
# Existing version-1 files without the seal remain readable.
static func _read(path: String) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	if file.get_length()<=0 or file.get_length()>MAX_BYTES: return {}
	var contents: String=file.get_as_text()
	file.close()
	var payload: String=contents
	var sealed: bool=contents.begins_with(SEAL)
	if sealed:
		var newline: int=contents.find("\n")
		if newline<0: return {}
		var expected: String=contents.substr(SEAL.length(),newline-SEAL.length())
		payload=contents.substr(newline+1)
		if expected.length()!=64 or payload.sha256_text()!=expected: return {}
	var cfg:=ConfigFile.new()
	if cfg.parse(payload)!=OK or cfg.get_value("meta","version",0)!=VERSION: return {}
	return {"config":cfg,"sealed":sealed}
static func load_report(path: String = PATH) -> Dictionary:
	for suffix in ["",".bak",".tmp"]:
		var result: Dictionary=_read(path+suffix)
		if not result.is_empty():
			result["source"]="primary" if suffix=="" else ("backup" if suffix==".bak" else "staged")
			return result
	var existed: bool=FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak") or FileAccess.file_exists(path+".tmp")
	return {"config":ConfigFile.new(),"source":"invalid" if existed else "new","sealed":false}
static func load_config(path: String = PATH) -> ConfigFile:
	return load_report(path)["config"]
static func write_config(cfg: ConfigFile, path: String = PATH) -> Error:
	cfg.set_value("meta","version",VERSION)
	var payload: String=cfg.encode_to_text()
	var contents: String=SEAL+payload.sha256_text()+"\n"+payload
	if contents.to_utf8_buffer().size()>MAX_BYTES: return ERR_INVALID_DATA
	var stage: String=path+".tmp"
	var backup: String=path+".bak"
	var backup_stage: String=path+".bak.tmp"
	# If an interrupted first write is the only readable copy, preserve it
	# before touching the staging path.
	if _read(path).is_empty() and _read(backup).is_empty() and not _read(stage).is_empty():
		var recovery: Error=DirAccess.rename_absolute(ProjectSettings.globalize_path(stage),ProjectSettings.globalize_path(backup))
		if recovery!=OK: return recovery
	var file:=FileAccess.open(stage,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	var status: Error=file.get_error()
	file.close()
	if status!=OK: return status
	var validated: Dictionary=_read(stage)
	if validated.is_empty() or not validated["sealed"]: return ERR_FILE_CORRUPT
	# Never replace the last valid backup with a corrupt primary.
	if not _read(path).is_empty():
		status=DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(backup_stage))
		if status!=OK: return status
		if _read(backup_stage).is_empty(): return ERR_FILE_CORRUPT
		status=DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_stage),ProjectSettings.globalize_path(backup))
		if status!=OK: return status
	# Replace only after staged data and previous generation are readable.
	# On failure leave both the previous save and staged file for recovery.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(stage),ProjectSettings.globalize_path(path))
static func snapshot(board: Board, profile: int, seed_value: int, first: int, start_hp: int = -1, protected_hits: int = 0) -> Dictionary:
	if board == null or board.finished(): return {}
	return {"profile":profile,"seed":seed_value,"first":first,"mask":board._mask.duplicate(),"cells":board.cells.duplicate(),"hp":board.hp,"rule":board.rule,"start_hp":Profiles.HP[profile] if start_hp<0 else start_hp,"protected_hits":protected_hits,"portal_pair":board.portal_pair,"portal_enabled":board.portal_enabled}
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
	var pair: Variant = data.get("portal_pair",Vector2i(-1,-1))
	var link: Variant = data.get("portal_enabled",false)
	if typeof(pair)!=TYPE_VECTOR2I or typeof(link)!=TYPE_BOOL: return {}
	if pair!=Vector2i(-1,-1):
		if not board.configure_portal(pair.x,pair.y,link): return {}
	elif link: return {}
	if board.finished(): return {}
	var phantom := Phantom.new()
	var anomaly: Variant = data.get("phantom",{})
	if not anomaly is Dictionary or not phantom.restore(anomaly,board): return {}
	var parasite := Parasite.new()
	var infection: Variant = data.get("parasite",{})
	if not infection is Dictionary or not parasite.restore(infection,board): return {}
	if phantom.active() and parasite.active(): return {}
	if board.has_portal() and (phantom.active() or parasite.active()): return {}
	return {"parasite":parasite,"phantom":phantom,"board":board,"profile":profile,"seed":data["seed"],"first":first,"certificate":proof,"start_hp":start_hp,"protected_hits":protected_hits}
