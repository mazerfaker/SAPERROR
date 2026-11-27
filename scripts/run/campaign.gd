extends RefCounted
const ACT_IDS := ["BOOT","CORRUPTION","ECHO","ADMIN"]
const BOSSES := {3:"WATCHER",6:"LIAR",9:"LOOP",10:"ADMIN"}
const ARCHIVES := {2:"WATCHER",5:"LIAR",8:"DOUBLE"}
var active: bool = false
var seen: Array[int] = []
var cleared: Array[int] = []
var records: Array[String] = []
var routes: Dictionary = {}
var loop_phase: int = 0
var admin_phase: int = 0
var admin_intro_seen: bool = false
var rewrite_done: bool = false
var ending: String = ""
const ENDINGS := ["SHUTDOWN","CONTAINMENT","REWRITE"]
const ADMIN_PHASES := ["ADMIN_LINK","DOUBLE","LIAR"]
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
	return str(BOSSES.get(sector,"")) if active and not cleared.has(sector) else ""
func complete_boss(sector: int, id: String) -> bool:
	if not active or id.is_empty() or boss_pending(sector)!=id: return false
	if id=="LOOP" and loop_phase!=2: return false
	if id=="ADMIN" and admin_phase!=3: return false
	cleared.append(sector)
	return true
func phase_kind(sector: int) -> String:
	var id: String=boss_pending(sector)
	if id=="LOOP": return ["LOOP","LOOP_B"][loop_phase] if loop_phase<2 else ""
	if id=="ADMIN": return ADMIN_PHASES[admin_phase] if admin_phase<3 else ""
	return id
func advance_phase(sector: int, kind: String) -> bool:
	if phase_kind(sector)!=kind or kind.is_empty(): return false
	var id: String=boss_pending(sector)
	if id=="LOOP":
		loop_phase+=1
		if loop_phase<2: return true
	elif id=="ADMIN":
		admin_phase+=1
		if admin_phase<3: return true
	return complete_boss(sector,id)
func can_end(id: String) -> bool:
	if not active or not cleared.has(10) or id not in ENDINGS or not ending.is_empty(): return false
	if id=="SHUTDOWN": return true
	return records.size()==3 and (id=="CONTAINMENT" or rewrite_done)
func choose_ending(id: String) -> bool:
	if not can_end(id): return false
	ending=id
	return true
func archive_pending(sector: int) -> bool:
	return active and ARCHIVES.has(sector) and not routes.has(sector)
func choose_route(sector: int, recovered: bool) -> bool:
	if not archive_pending(sector): return false
	routes[sector]=recovered
	if recovered: records.append("MEMORY_%02d" % sector)
	return true
func snapshot() -> Dictionary:
	return {"active":active,"seen":seen.duplicate(),"cleared":cleared.duplicate(),"records":records.duplicate(),"routes":routes.duplicate(),"loop_phase":loop_phase,"admin_phase":admin_phase,"admin_intro_seen":admin_intro_seen,"rewrite_done":rewrite_done,"ending":ending}
func restore(raw: Variant, sector: int) -> bool:
	if not raw is Dictionary or typeof(raw.get("active"))!=TYPE_BOOL: return false
	if not raw["active"]: return true
	if sector<1 or sector>10: return false
	for key in ["seen","cleared","records"]:
		if not raw.get(key) is Array: return false
	var s: Array[int] = []
	var c: Array[int] = []
	var r: Array[String] = []
	var rt: Variant = raw.get("routes",{})
	if not rt is Dictionary: return false
	for value in raw["seen"]:
		if typeof(value)!=TYPE_INT or value<0 or value>act_index(sector) or s.has(value): return false
		s.append(value)
	for value in raw["cleared"]:
		if typeof(value)!=TYPE_INT or value not in [3,6,9,10] or value>sector or c.has(value): return false
		c.append(value)
	for gate in [3,6,9]:
		if gate<sector and not c.has(gate): return false
	for key in rt:
		if typeof(key)!=TYPE_INT or not ARCHIVES.has(key) or key>sector or typeof(rt[key])!=TYPE_BOOL: return false
	for value in raw["records"]:
		if typeof(value)!=TYPE_STRING or r.has(value): return false
		r.append(value)
	var expected: Array[String] = []
	for key in rt:
		if rt[key]: expected.append("MEMORY_%02d" % int(key))
	if r.size()!=expected.size(): return false
	for value in expected:
		if not r.has(value): return false
	var lp: Variant=raw.get("loop_phase",2 if c.has(9) else 0)
	var ap: Variant=raw.get("admin_phase",3 if c.has(10) else 0)
	var intro: Variant=raw.get("admin_intro_seen",false)
	var rewrite: Variant=raw.get("rewrite_done",false)
	var final_id: Variant=raw.get("ending","")
	if typeof(lp)!=TYPE_INT or lp<0 or lp>2 or typeof(ap)!=TYPE_INT or ap<0 or ap>3 or typeof(intro)!=TYPE_BOOL or typeof(rewrite)!=TYPE_BOOL or typeof(final_id)!=TYPE_STRING: return false
	if (lp==2)!=c.has(9) or (ap==3)!=c.has(10) or (lp>0 and sector<9) or (ap>0 and sector<10) or (intro and sector<10): return false
	if rewrite and (not c.has(10) or r.size()!=3): return false
	if not final_id.is_empty() and (not c.has(10) or final_id not in ENDINGS or (final_id!="SHUTDOWN" and r.size()!=3) or (final_id=="REWRITE" and not rewrite)): return false
	loop_phase=lp
	admin_phase=ap
	admin_intro_seen=intro
	rewrite_done=rewrite
	ending=final_id
	active=true
	seen=s
	cleared=c
	records=r
	routes=rt.duplicate()
	return true
