extends RefCounted
# Narrative metadata; the existing run owns board, HP, inventory and seed.
const ACT_IDS := ["BOOT","CORRUPTION","ECHO","ADMIN"]
const BOSSES := {3:"WATCHER",6:"LIAR",9:"LOOP",10:"ADMIN"}
var active: bool = false
var seen: Array[int] = []
var cleared: Array[int] = []
var records: Array[String] = []
func act_index(sector: int) -> int:
	if sector>=10: return 3
	if sector>=7: return 2
	if sector>=4: return 1
	return 0
func needs_intro(sector: int) -> bool:
	return active and not seen.has(act_index(sector))
func acknowledge(sector: int) -> void:
	if active and not seen.has(act_index(sector)): seen.append(act_index(sector))
func boss_pending(sector: int) -> String:
	if not active or cleared.has(sector): return ""
	return str(BOSSES.get(sector,""))
func complete_boss(sector: int, id: String) -> bool:
	if not active or id.is_empty() or id=="ADMIN" or boss_pending(sector)!=id: return false
	cleared.append(sector)
	records.append("MEMORY_%02d" % sector)
	return true
func snapshot() -> Dictionary:
	return {"active":active,"seen":seen.duplicate(),"cleared":cleared.duplicate(),"records":records.duplicate()}
func restore(raw: Variant, sector: int) -> bool:
	if not raw is Dictionary or typeof(raw.get("active"))!=TYPE_BOOL: return false
	if not raw["active"]: return true
	if sector<1 or sector>10: return false
	for key in ["seen","cleared","records"]:
		if not raw.get(key) is Array: return false
	var s: Array[int] = []
	var c: Array[int] = []
	var r: Array[String] = []
	for value in raw["seen"]:
		if typeof(value)!=TYPE_INT or value<0 or value>act_index(sector) or s.has(value): return false
		s.append(value)
	for value in raw["cleared"]:
		if typeof(value)!=TYPE_INT or value not in [3,6,9] or value>sector or c.has(value): return false
		c.append(value)
	for gate in [3,6,9]:
		if gate<sector and not c.has(gate): return false
	for value in raw["records"]:
		if typeof(value)!=TYPE_STRING or r.has(value): return false
		r.append(value)
	if r.size()!=c.size(): return false
	for gate in c:
		if not r.has("MEMORY_%02d" % gate): return false
	active=true
	seen=s
	cleared=c
	records=r
	return true
