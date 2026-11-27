extends RefCounted
# Account-local collection. Never used to grant credits or ending prerequisites.
const Challenge=preload("res://scripts/board/anomaly_challenge.gd")
const Campaign=preload("res://scripts/run/campaign.gd")
const RECORDS:=["MEMORY_02","MEMORY_05","MEMORY_08"]
var archives: Array[String]=[]
var trials: Array[String]=[]
static func validated(raw: Variant, allowed: Array) -> Array[String]:
	var result: Array[String]=[]
	if not raw is Array: return result
	for id in allowed:
		if raw.has(id): result.append(id)
	return result
func restore(cfg: ConfigFile, active_records: Array[String]) -> void:
	archives=validated(cfg.get_value("stats","archives",[]),RECORDS)
	trials=validated(cfg.get_value("stats","lab_completed",[]),Challenge.KINDS)
	# Migrate recovered records from pre-0.7 saves without inventing lost history.
	for id in active_records: recover(id)
func write(cfg: ConfigFile) -> void:
	cfg.set_value("stats","archives",archives.duplicate())
	cfg.set_value("stats","lab_completed",trials.duplicate())
func recover(id: String) -> bool:
	if not RECORDS.has(id) or archives.has(id): return false
	archives.append(id)
	return true
func finish_trial(id: String) -> bool:
	if not Challenge.KINDS.has(id) or trials.has(id): return false
	trials.append(id)
	return true
